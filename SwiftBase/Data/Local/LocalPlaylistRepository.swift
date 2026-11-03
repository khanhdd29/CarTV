//
//  LocalPlaylistRepository.swift
//  SwiftBase
//
//  DATA layer — the only place that knows about parsing + SQLite. Conforms to
//  the domain `PlaylistRepository`, so view models depend on the protocol, not
//  this class (spec §7, §8.2).
//

import Foundation

final class LocalPlaylistRepository: PlaylistRepository {
    private let store: IPTVStore
    private let downloader = PlaylistDownloader()
    private let parser = M3UParser()
    private let xtream = XtreamClient()

    init(store: IPTVStore) {
        self.store = store
    }

    // MARK: Add / import / refresh

    @discardableResult
    func addPlaylist(name: String, url: URL, onProgress: (@Sendable (Int) -> Void)?) async throws -> PlaylistRef {
        var ref = PlaylistRef(name: name, sourceURL: url.absoluteString, type: .m3u)
        try await store.savePlaylist(ref)
        let fileURL = try await downloader.download(url)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        ref.channelCount = try await parseAndStore(fileURL: fileURL, into: ref.id, onProgress: onProgress)
        return ref
    }

    @discardableResult
    func importPlaylist(name: String, fileURL: URL, onProgress: (@Sendable (Int) -> Void)?) async throws -> PlaylistRef {
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer { if accessed { fileURL.stopAccessingSecurityScopedResource() } }

        var ref = PlaylistRef(name: name, sourceURL: fileURL.absoluteString, type: .m3u)
        try await store.savePlaylist(ref)
        ref.channelCount = try await parseAndStore(fileURL: fileURL, into: ref.id, onProgress: onProgress)
        return ref
    }

    @discardableResult
    func createManualPlaylist(name: String, type: PlaylistType, channels: [ChannelInput]) async throws -> PlaylistRef {
        guard !channels.isEmpty else { throw AppError.emptyPlaylist }
        var ref = PlaylistRef(name: name, sourceURL: "", type: type)
        try await store.savePlaylist(ref)
        let parsed = channels.map {
            ParsedChannel(name: $0.name, streamURL: $0.streamURL, logoURL: $0.logoURL, groupTitle: $0.groupTitle, tvgId: nil)
        }
        _ = try await store.insertChannels(parsed, playlistId: ref.id)
        ref.channelCount = try await store.channelCount(playlistId: ref.id)
        try await store.setChannelCount(ref.channelCount, playlistId: ref.id)
        return ref
    }

    @discardableResult
    func addXtreamPlaylist(name: String, serverURL: URL, username: String, password: String,
                           onProgress: (@Sendable (Int) -> Void)?) async throws -> PlaylistRef {
        var ref = PlaylistRef(name: name, sourceURL: serverURL.absoluteString, type: .xtream)
        try await store.savePlaylist(ref)
        // Credentials → Keychain (never stored with the channel rows).
        KeychainStore.set(username, for: "xtream.\(ref.id).user")
        KeychainStore.set(password, for: "xtream.\(ref.id).pass")

        let cred = XtreamCredentials(base: serverURL, username: username, password: password)
        let channels = try await xtream.fetchLiveChannels(cred)
        guard !channels.isEmpty else {
            try await store.deletePlaylist(id: ref.id)
            throw AppError.emptyPlaylist
        }
        ref.channelCount = try await storeChannels(channels, into: ref.id, onProgress: onProgress)
        try await store.setChannelCount(ref.channelCount, playlistId: ref.id)
        return ref
    }

    @discardableResult
    func refreshPlaylist(id: String, onProgress: (@Sendable (Int) -> Void)?) async throws -> PlaylistRef {
        guard var ref = try await store.playlist(id: id), let url = URL(string: ref.sourceURL) else {
            throw AppError.invalidURL
        }

        // Xtream: re-fetch using the stored credentials.
        if ref.type == .xtream {
            guard let user = KeychainStore.get("xtream.\(id).user"),
                  let pass = KeychainStore.get("xtream.\(id).pass") else {
                throw AppError.invalidURL
            }
            try await store.clearChannels(playlistId: id)
            let cred = XtreamCredentials(base: url, username: user, password: pass)
            let channels = try await xtream.fetchLiveChannels(cred)
            ref.channelCount = try await storeChannels(channels, into: id, onProgress: onProgress)
            try await store.setChannelCount(ref.channelCount, playlistId: id)
            return ref
        }

        try await store.clearChannels(playlistId: id)
        if url.isFileURL {
            ref.channelCount = try await parseAndStore(fileURL: url, into: id, onProgress: onProgress)
        } else {
            let fileURL = try await downloader.download(url)
            defer { try? FileManager.default.removeItem(at: fileURL) }
            ref.channelCount = try await parseAndStore(fileURL: fileURL, into: id, onProgress: onProgress)
        }
        return ref
    }

    /// Streaming-parse a local file → batched insert. Deletes the playlist row if
    /// nothing parsed so we don't leave an empty entry behind. Returns the count.
    private func parseAndStore(fileURL: URL, into playlistId: String, onProgress: (@Sendable (Int) -> Void)?) async throws -> Int {
        let store = self.store
        try await parser.parse(fileURL: fileURL) { batch in
            let cumulative = try await store.insertChannels(batch, playlistId: playlistId)
            onProgress?(cumulative)
        }

        let total = try await store.channelCount(playlistId: playlistId)
        guard total > 0 else {
            try await store.deletePlaylist(id: playlistId)
            throw AppError.emptyPlaylist
        }
        try await store.setChannelCount(total, playlistId: playlistId)
        return total
    }

    /// Insert pre-built channels (Xtream) in chunks, reporting running progress.
    private func storeChannels(_ inputs: [ChannelInput], into playlistId: String,
                               onProgress: (@Sendable (Int) -> Void)?) async throws -> Int {
        let chunkSize = 500
        var i = 0
        while i < inputs.count {
            let slice = Array(inputs[i..<min(i + chunkSize, inputs.count)])
            let parsed = slice.map {
                ParsedChannel(name: $0.name, streamURL: $0.streamURL, logoURL: $0.logoURL,
                              groupTitle: $0.groupTitle, tvgId: nil)
            }
            let cumulative = try await store.insertChannels(parsed, playlistId: playlistId)
            onProgress?(cumulative)
            i += chunkSize
        }
        return try await store.channelCount(playlistId: playlistId)
    }

    // MARK: Queries

    func playlists() async throws -> [PlaylistRef] { try await store.playlists() }
    func deletePlaylist(id: String) async throws {
        // Clean up any stored Xtream credentials for this playlist.
        KeychainStore.delete("xtream.\(id).user")
        KeychainStore.delete("xtream.\(id).pass")
        try await store.deletePlaylist(id: id)
    }
    func renamePlaylist(id: String, name: String) async throws {
        try await store.renamePlaylist(id: id, name: name)
    }

    func channels(playlistId: String) async throws -> [Channel] {
        try await store.channels(playlistId: playlistId)
    }

    func groups() async throws -> [String] { try await store.groups() }

    func channels(group: String?, limit: Int, offset: Int, sortByName: Bool) async throws -> [Channel] {
        try await store.channels(group: group, limit: limit, offset: offset, sortByName: sortByName)
    }

    func search(_ query: String, limit: Int) async throws -> [Channel] {
        try await store.search(query, limit: limit)
    }

    func channelCount() async throws -> Int { try await store.channelCount() }
}
