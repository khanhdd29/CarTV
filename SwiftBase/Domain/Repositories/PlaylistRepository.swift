//
//  PlaylistRepository.swift
//  SwiftBase
//
//  DOMAIN contract for the *heavy* playlist data (spec §7: the playlist repo is
//  always local). The domain only knows this protocol — never SQLite, never a
//  concrete store. Swap the implementation without touching callers.
//

import Foundation

protocol PlaylistRepository {
    /// Download + streaming-parse an M3U link on a background task, persist its
    /// channels locally, and return the stored metadata. `onProgress` reports the
    /// running channel count so the UI can show live progress.
    @discardableResult
    func addPlaylist(name: String, url: URL, onProgress: (@Sendable (Int) -> Void)?) async throws -> PlaylistRef

    /// Import an M3U playlist from a local file (e.g. picked via the Files app).
    @discardableResult
    func importPlaylist(name: String, fileURL: URL, onProgress: (@Sendable (Int) -> Void)?) async throws -> PlaylistRef

    /// Create a playlist from channels we already have (a pasted stream, or
    /// imported device videos) — no download/parse.
    @discardableResult
    func createManualPlaylist(name: String, type: PlaylistType, channels: [ChannelInput]) async throws -> PlaylistRef

    /// Re-parse an existing playlist from its stored `sourceURL`.
    @discardableResult
    func refreshPlaylist(id: String, onProgress: (@Sendable (Int) -> Void)?) async throws -> PlaylistRef

    func playlists() async throws -> [PlaylistRef]
    func deletePlaylist(id: String) async throws

    // MARK: Channel queries (paged — never load the whole list into memory)

    /// Distinct `group-title` values across all channels, for the category chips.
    func groups() async throws -> [String]

    /// A page of channels, optionally filtered by group, ordered by playlist order.
    func channels(group: String?, limit: Int, offset: Int) async throws -> [Channel]

    /// Full-text (FTS5) search over channel name + group.
    func search(_ query: String, limit: Int) async throws -> [Channel]

    func channelCount() async throws -> Int
}

extension PlaylistRepository {
    @discardableResult
    func addPlaylist(name: String, url: URL) async throws -> PlaylistRef {
        try await addPlaylist(name: name, url: url, onProgress: nil)
    }
}
