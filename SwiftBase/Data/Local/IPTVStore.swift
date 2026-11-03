//
//  IPTVStore.swift
//  SwiftBase
//
//  The single local persistence point (spec §7: playlist repo is always local).
//  An `actor` owns one SQLite connection so every query is serialized and runs
//  off the main thread. Channels live here (potentially 20k+ rows, paged on
//  demand) — never held wholesale in RAM.
//

import Foundation

/// Lightweight row produced by the parser before it has a DB id.
struct ParsedChannel: Sendable {
    let name: String
    let streamURL: String
    let logoURL: String?
    let groupTitle: String?
    let tvgId: String?
}

actor IPTVStore {
    private let db: SQLiteDatabase

    init() throws {
        let fm = FileManager.default
        let dir = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = dir.appendingPathComponent("iptv.sqlite")
        db = try SQLiteDatabase(path: url.path)
        try Self.migrate(db)
    }

    private static func migrate(_ db: SQLiteDatabase) throws {
        try db.run("""
        CREATE TABLE IF NOT EXISTS playlists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            source_url TEXT NOT NULL,
            type TEXT NOT NULL,
            added_at REAL NOT NULL,
            channel_count INTEGER NOT NULL DEFAULT 0
        );
        """)

        try db.run("""
        CREATE TABLE IF NOT EXISTS channels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playlist_id TEXT NOT NULL,
            name TEXT NOT NULL,
            stream_url TEXT NOT NULL,
            logo_url TEXT,
            group_title TEXT,
            tvg_id TEXT,
            sort_order INTEGER NOT NULL,
            FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
        );
        """)
        try db.run("CREATE INDEX IF NOT EXISTS idx_channels_playlist ON channels(playlist_id);")
        try db.run("CREATE INDEX IF NOT EXISTS idx_channels_group ON channels(group_title);")

        // Full-text index (FTS5) over name + group, external-content on `channels`
        // so inserts/deletes stay in sync via triggers (spec §5.4).
        try db.run("""
        CREATE VIRTUAL TABLE IF NOT EXISTS channels_fts USING fts5(
            name, group_title, content='channels', content_rowid='id', tokenize='unicode61'
        );
        """)
        try db.run("""
        CREATE TRIGGER IF NOT EXISTS channels_ai AFTER INSERT ON channels BEGIN
            INSERT INTO channels_fts(rowid, name, group_title) VALUES (new.id, new.name, new.group_title);
        END;
        """)
        try db.run("""
        CREATE TRIGGER IF NOT EXISTS channels_ad AFTER DELETE ON channels BEGIN
            INSERT INTO channels_fts(channels_fts, rowid, name, group_title)
            VALUES ('delete', old.id, old.name, old.group_title);
        END;
        """)

        try db.run("""
        CREATE TABLE IF NOT EXISTS favourites (
            stream_url TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            logo_url TEXT,
            group_title TEXT,
            added_at REAL NOT NULL
        );
        """)

        try db.run("""
        CREATE TABLE IF NOT EXISTS recents (
            stream_url TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            logo_url TEXT,
            group_title TEXT,
            watched_at REAL NOT NULL,
            position REAL NOT NULL DEFAULT 0
        );
        """)
        try db.run("CREATE INDEX IF NOT EXISTS idx_recents_watched ON recents(watched_at DESC);")
        // Upgrade older installs: add the resume column if missing (no-op otherwise).
        db.exec("ALTER TABLE recents ADD COLUMN position REAL NOT NULL DEFAULT 0;")

        // EPG (electronic program guide), matched to channels by tvg-id.
        try db.run("""
        CREATE TABLE IF NOT EXISTS epg (
            tvg_id TEXT NOT NULL,
            start REAL NOT NULL,
            stop REAL NOT NULL,
            title TEXT NOT NULL
        );
        """)
        try db.run("CREATE INDEX IF NOT EXISTS idx_epg_channel ON epg(tvg_id, start);")

        // Playlist health — last-known reachability per stream link (Driver 3).
        try db.run("""
        CREATE TABLE IF NOT EXISTS stream_health (
            stream_url TEXT PRIMARY KEY,
            status INTEGER NOT NULL,
            checked_at REAL NOT NULL
        );
        """)
    }

    // MARK: - Playlists

    func savePlaylist(_ ref: PlaylistRef) throws {
        try db.run(
            "INSERT OR REPLACE INTO playlists (id, name, source_url, type, added_at, channel_count) VALUES (?, ?, ?, ?, ?, ?);",
            [.text(ref.id), .text(ref.name), .text(ref.sourceURL), .text(ref.type.rawValue),
             .double(ref.addedAt.timeIntervalSince1970), .int(Int64(ref.channelCount))]
        )
    }

    func setChannelCount(_ count: Int, playlistId: String) throws {
        try db.run("UPDATE playlists SET channel_count = ? WHERE id = ?;", [.int(Int64(count)), .text(playlistId)])
    }

    func renamePlaylist(id: String, name: String) throws {
        try db.run("UPDATE playlists SET name = ? WHERE id = ?;", [.text(name), .text(id)])
    }

    func playlists() throws -> [PlaylistRef] {
        let stmt = try db.prepare("SELECT id, name, source_url, type, added_at, channel_count FROM playlists ORDER BY added_at DESC;")
        defer { stmt.finalize() }
        var result: [PlaylistRef] = []
        while stmt.stepRow() {
            result.append(PlaylistRef(
                id: stmt.string(0) ?? UUID().uuidString,
                name: stmt.string(1) ?? "",
                sourceURL: stmt.string(2) ?? "",
                type: PlaylistType(rawValue: stmt.string(3) ?? "m3u") ?? .m3u,
                addedAt: Date(timeIntervalSince1970: stmt.double(4)),
                channelCount: Int(stmt.int(5))
            ))
        }
        return result
    }

    func playlist(id: String) throws -> PlaylistRef? {
        let stmt = try db.prepare("SELECT id, name, source_url, type, added_at, channel_count FROM playlists WHERE id = ?;")
        defer { stmt.finalize() }
        stmt.bind([.text(id)])
        guard stmt.stepRow() else { return nil }
        return PlaylistRef(
            id: stmt.string(0) ?? id,
            name: stmt.string(1) ?? "",
            sourceURL: stmt.string(2) ?? "",
            type: PlaylistType(rawValue: stmt.string(3) ?? "m3u") ?? .m3u,
            addedAt: Date(timeIntervalSince1970: stmt.double(4)),
            channelCount: Int(stmt.int(5))
        )
    }

    func deletePlaylist(id: String) throws {
        // ON DELETE CASCADE removes channels; the AD trigger cleans the FTS index.
        try db.run("DELETE FROM channels WHERE playlist_id = ?;", [.text(id)])
        try db.run("DELETE FROM playlists WHERE id = ?;", [.text(id)])
    }

    func clearChannels(playlistId: String) throws {
        try db.run("DELETE FROM channels WHERE playlist_id = ?;", [.text(playlistId)])
    }

    // MARK: - Channel import (batched transaction)

    /// Insert a batch of parsed channels in one transaction, appending after any
    /// channels already stored for this playlist so pagination keeps playlist
    /// order across batches. Returns the running cumulative count for the
    /// playlist (handy for live progress).
    @discardableResult
    func insertChannels(_ batch: [ParsedChannel], playlistId: String) throws -> Int {
        guard !batch.isEmpty else { return try channelCount(playlistId: playlistId) }
        let startOrder = try channelCount(playlistId: playlistId)
        try db.beginTransaction()
        do {
            let stmt = try db.prepare("""
            INSERT INTO channels (playlist_id, name, stream_url, logo_url, group_title, tvg_id, sort_order)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """)
            defer { stmt.finalize() }
            var order = startOrder
            for ch in batch {
                stmt.reset()
                stmt.bind([
                    .text(playlistId),
                    .text(ch.name),
                    .text(ch.streamURL),
                    ch.logoURL.map(SQLValue.text) ?? .null,
                    ch.groupTitle.map(SQLValue.text) ?? .null,
                    ch.tvgId.map(SQLValue.text) ?? .null,
                    .int(Int64(order))
                ])
                try stmt.stepDone()
                order += 1
            }
            try db.commit()
            return order
        } catch {
            db.rollback()
            throw error
        }
    }

    func channelCount(playlistId: String) throws -> Int {
        let stmt = try db.prepare("SELECT COUNT(*) FROM channels WHERE playlist_id = ?;")
        defer { stmt.finalize() }
        stmt.bind([.text(playlistId)])
        return stmt.stepRow() ? Int(stmt.int(0)) : 0
    }

    // MARK: - Channel queries (paged)

    func channelCount() throws -> Int {
        let stmt = try db.prepare("SELECT COUNT(*) FROM channels;")
        defer { stmt.finalize() }
        return stmt.stepRow() ? Int(stmt.int(0)) : 0
    }

    func groups() throws -> [String] {
        let stmt = try db.prepare("""
        SELECT group_title FROM channels
        WHERE group_title IS NOT NULL AND group_title <> ''
        GROUP BY group_title ORDER BY group_title COLLATE NOCASE;
        """)
        defer { stmt.finalize() }
        var result: [String] = []
        while stmt.stepRow() { if let g = stmt.string(0) { result.append(g) } }
        return result
    }

    func channels(group: String?, limit: Int, offset: Int, sortByName: Bool = false) throws -> [Channel] {
        let order = sortByName ? "name COLLATE NOCASE" : "sort_order"
        let sql: String
        var binds: [SQLValue] = []
        if let group {
            sql = "SELECT id, playlist_id, name, stream_url, logo_url, group_title, tvg_id FROM channels WHERE group_title = ? ORDER BY \(order) LIMIT ? OFFSET ?;"
            binds = [.text(group), .int(Int64(limit)), .int(Int64(offset))]
        } else {
            sql = "SELECT id, playlist_id, name, stream_url, logo_url, group_title, tvg_id FROM channels ORDER BY \(order) LIMIT ? OFFSET ?;"
            binds = [.int(Int64(limit)), .int(Int64(offset))]
        }
        let stmt = try db.prepare(sql)
        defer { stmt.finalize() }
        stmt.bind(binds)
        return readChannels(stmt)
    }

    /// Every channel of one playlist (used by the health sweep).
    func channels(playlistId: String) throws -> [Channel] {
        let stmt = try db.prepare("""
        SELECT id, playlist_id, name, stream_url, logo_url, group_title, tvg_id
        FROM channels WHERE playlist_id = ? ORDER BY sort_order;
        """)
        defer { stmt.finalize() }
        stmt.bind([.text(playlistId)])
        return readChannels(stmt)
    }

    func search(_ query: String, limit: Int) throws -> [Channel] {
        guard let match = Self.ftsQuery(from: query) else { return [] }
        // Use the table name directly (FTS5 MATCH + rank don't accept an alias here).
        let stmt = try db.prepare("""
        SELECT c.id, c.playlist_id, c.name, c.stream_url, c.logo_url, c.group_title, c.tvg_id
        FROM channels_fts
        JOIN channels c ON c.id = channels_fts.rowid
        WHERE channels_fts MATCH ?
        ORDER BY rank
        LIMIT ?;
        """)
        defer { stmt.finalize() }
        stmt.bind([.text(match), .int(Int64(limit))])
        return readChannels(stmt)
    }

    private func readChannels(_ stmt: Statement) -> [Channel] {
        var result: [Channel] = []
        while stmt.stepRow() {
            result.append(Channel(
                id: stmt.int(0),
                playlistId: stmt.string(1) ?? "",
                name: stmt.string(2) ?? "",
                streamURL: stmt.string(3) ?? "",
                logoURL: stmt.string(4),
                groupTitle: stmt.string(5),
                tvgId: stmt.string(6)
            ))
        }
        return result
    }

    /// Turn free text into a safe FTS5 prefix query: each token quoted (quotes
    /// doubled) with a trailing `*`, implicitly AND-ed.
    private static func ftsQuery(from text: String) -> String? {
        let tokens = text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }
        return tokens.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"*" }.joined(separator: " ")
    }

    // MARK: - Favourites

    func favourites() throws -> [Favourite] {
        let stmt = try db.prepare("SELECT stream_url, name, logo_url, group_title, added_at FROM favourites ORDER BY added_at DESC;")
        defer { stmt.finalize() }
        var result: [Favourite] = []
        while stmt.stepRow() {
            result.append(Favourite(
                streamURL: stmt.string(0) ?? "",
                name: stmt.string(1) ?? "",
                logoURL: stmt.string(2),
                groupTitle: stmt.string(3),
                addedAt: Date(timeIntervalSince1970: stmt.double(4))
            ))
        }
        return result
    }

    func favouriteStreamURLs() throws -> Set<String> {
        let stmt = try db.prepare("SELECT stream_url FROM favourites;")
        defer { stmt.finalize() }
        var set = Set<String>()
        while stmt.stepRow() { if let u = stmt.string(0) { set.insert(u) } }
        return set
    }

    func isFavourite(streamURL: String) throws -> Bool {
        let stmt = try db.prepare("SELECT 1 FROM favourites WHERE stream_url = ? LIMIT 1;")
        defer { stmt.finalize() }
        stmt.bind([.text(streamURL)])
        return stmt.stepRow()
    }

    func addFavourite(_ fav: Favourite) throws {
        try db.run(
            "INSERT OR REPLACE INTO favourites (stream_url, name, logo_url, group_title, added_at) VALUES (?, ?, ?, ?, ?);",
            [.text(fav.streamURL), .text(fav.name), fav.logoURL.map(SQLValue.text) ?? .null,
             fav.groupTitle.map(SQLValue.text) ?? .null, .double(fav.addedAt.timeIntervalSince1970)]
        )
    }

    func removeFavourite(streamURL: String) throws {
        try db.run("DELETE FROM favourites WHERE stream_url = ?;", [.text(streamURL)])
    }

    // MARK: - Recents (watch history)

    func recents(limit: Int) throws -> [WatchHistory] {
        let stmt = try db.prepare("SELECT stream_url, name, logo_url, group_title, watched_at FROM recents ORDER BY watched_at DESC LIMIT ?;")
        defer { stmt.finalize() }
        stmt.bind([.int(Int64(limit))])
        var result: [WatchHistory] = []
        while stmt.stepRow() {
            result.append(WatchHistory(
                streamURL: stmt.string(0) ?? "",
                name: stmt.string(1) ?? "",
                logoURL: stmt.string(2),
                groupTitle: stmt.string(3),
                watchedAt: Date(timeIntervalSince1970: stmt.double(4))
            ))
        }
        return result
    }

    func recordWatch(_ item: WatchHistory) throws {
        // Upsert that PRESERVES the saved resume position (don't reset it on replay).
        try db.run("""
        INSERT INTO recents (stream_url, name, logo_url, group_title, watched_at)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(stream_url) DO UPDATE SET
            name = excluded.name,
            logo_url = excluded.logo_url,
            group_title = excluded.group_title,
            watched_at = excluded.watched_at;
        """,
            [.text(item.streamURL), .text(item.name), item.logoURL.map(SQLValue.text) ?? .null,
             item.groupTitle.map(SQLValue.text) ?? .null, .double(item.watchedAt.timeIntervalSince1970)]
        )
        // Trim to the latest 100.
        try db.run("""
        DELETE FROM recents WHERE stream_url NOT IN (
            SELECT stream_url FROM recents ORDER BY watched_at DESC LIMIT 100
        );
        """)
    }

    func clearRecents() throws {
        try db.run("DELETE FROM recents;")
    }

    // MARK: - EPG

    func replaceEPG(_ programmes: [ParsedProgramme]) throws {
        try db.run("DELETE FROM epg;")
        guard !programmes.isEmpty else { return }
        try db.beginTransaction()
        do {
            let stmt = try db.prepare("INSERT INTO epg (tvg_id, start, stop, title) VALUES (?, ?, ?, ?);")
            defer { stmt.finalize() }
            for p in programmes {
                stmt.reset()
                stmt.bind([.text(p.channelId), .double(p.start.timeIntervalSince1970),
                           .double(p.stop.timeIntervalSince1970), .text(p.title)])
                try stmt.stepDone()
            }
            try db.commit()
        } catch {
            db.rollback(); throw error
        }
    }

    func epgCount() throws -> Int {
        let stmt = try db.prepare("SELECT COUNT(*) FROM epg;")
        defer { stmt.finalize() }
        return stmt.stepRow() ? Int(stmt.int(0)) : 0
    }

    func clearEPG() throws { try db.run("DELETE FROM epg;") }

    // MARK: - Stream health

    func allHealth() throws -> [String: StreamStatus] {
        let stmt = try db.prepare("SELECT stream_url, status FROM stream_health;")
        defer { stmt.finalize() }
        var result: [String: StreamStatus] = [:]
        while stmt.stepRow() {
            if let url = stmt.string(0) {
                result[url] = StreamStatus(rawValue: Int(stmt.int(1))) ?? .unknown
            }
        }
        return result
    }

    func setHealth(streamURL: String, status: StreamStatus, at: Double) throws {
        try db.run("""
        INSERT INTO stream_health (stream_url, status, checked_at) VALUES (?, ?, ?)
        ON CONFLICT(stream_url) DO UPDATE SET status = excluded.status, checked_at = excluded.checked_at;
        """, [.text(streamURL), .int(Int64(status.rawValue)), .double(at)])
    }

    /// Resolve a channel's `tvg-id` from its stream URL (for channels rebuilt
    /// from Favorites/Recents, which don't carry the id).
    func tvgId(forStreamURL url: String) throws -> String? {
        let stmt = try db.prepare("""
        SELECT tvg_id FROM channels
        WHERE stream_url = ? AND tvg_id IS NOT NULL AND tvg_id <> '' LIMIT 1;
        """)
        defer { stmt.finalize() }
        stmt.bind([.text(url)])
        guard stmt.stepRow() else { return nil }
        return stmt.string(0)
    }

    func nowNext(tvgId: String, at now: Double) throws -> EPGNowNext {
        let nowStmt = try db.prepare("""
        SELECT title, start, stop FROM epg
        WHERE tvg_id = ? AND start <= ? AND stop > ? ORDER BY start DESC LIMIT 1;
        """)
        defer { nowStmt.finalize() }
        nowStmt.bind([.text(tvgId), .double(now), .double(now)])
        let nowEntry = readEntry(nowStmt)

        let nextStmt = try db.prepare("""
        SELECT title, start, stop FROM epg
        WHERE tvg_id = ? AND start > ? ORDER BY start ASC LIMIT 1;
        """)
        defer { nextStmt.finalize() }
        nextStmt.bind([.text(tvgId), .double(now)])
        let nextEntry = readEntry(nextStmt)

        return EPGNowNext(now: nowEntry, next: nextEntry)
    }

    /// All programmes overlapping a window (for the schedule/timeline view).
    func schedule(tvgId: String, from: Double, to: Double) throws -> [EPGEntry] {
        let stmt = try db.prepare("""
        SELECT title, start, stop FROM epg
        WHERE tvg_id = ? AND stop > ? AND start < ? ORDER BY start ASC;
        """)
        defer { stmt.finalize() }
        stmt.bind([.text(tvgId), .double(from), .double(to)])
        var result: [EPGEntry] = []
        while stmt.stepRow() {
            result.append(EPGEntry(
                title: stmt.string(0) ?? "",
                start: Date(timeIntervalSince1970: stmt.double(1)),
                stop: Date(timeIntervalSince1970: stmt.double(2))))
        }
        return result
    }

    private func readEntry(_ stmt: Statement) -> EPGEntry? {
        guard stmt.stepRow() else { return nil }
        return EPGEntry(
            title: stmt.string(0) ?? "",
            start: Date(timeIntervalSince1970: stmt.double(1)),
            stop: Date(timeIntervalSince1970: stmt.double(2))
        )
    }

    // MARK: Resume position

    func savePosition(streamURL: String, seconds: Double) throws {
        try db.run("UPDATE recents SET position = ? WHERE stream_url = ?;",
                   [.double(seconds), .text(streamURL)])
    }

    func position(streamURL: String) throws -> Double {
        let stmt = try db.prepare("SELECT position FROM recents WHERE stream_url = ? LIMIT 1;")
        defer { stmt.finalize() }
        stmt.bind([.text(streamURL)])
        return stmt.stepRow() ? stmt.double(0) : 0
    }
}
