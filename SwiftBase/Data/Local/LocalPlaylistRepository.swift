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
    func refreshPlaylist(id: String, onProgress: (@Sendable (Int) -> Void)?) async throws -> PlaylistRef {
        guard var ref = try await store.playlist(id: id), let url = URL(string: ref.sourceURL) else {
            throw AppError.invalidURL
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

    // MARK: Queries

    func playlists() async throws -> [PlaylistRef] { try await store.playlists() }
    func deletePlaylist(id: String) async throws { try await store.deletePlaylist(id: id) }
    func groups() async throws -> [String] { try await store.groups() }

    func channels(group: String?, limit: Int, offset: Int) async throws -> [Channel] {
        try await store.channels(group: group, limit: limit, offset: offset)
    }

    func search(_ query: String, limit: Int) async throws -> [Channel] {
        try await store.search(query, limit: limit)
    }

    func channelCount() async throws -> Int { try await store.channelCount() }
}
