//
//  HealthCenter.swift
//  SwiftBase
//
//  App-wide, observable cache of stream health so any channel card can show a
//  status dot and the player can flag a dead link — all reading one source of
//  truth (spec §Driver 3). One instance via Factory.
//

import Foundation
import Factory

@MainActor
final class HealthCenter: ObservableObject {
    @Injected(\.healthRepository) private var repo: HealthRepository
    @Injected(\.app) private var app: AppManager

    /// Last-known status per stream URL. Views observe this and re-render as a
    /// sweep fills it in.
    @Published private(set) var statuses: [String: StreamStatus] = [:]
    @Published private(set) var isProbing = false

    init() { loadCache() }

    /// Load the cached statuses from disk (also runs once on creation).
    func loadCache() {
        Task { statuses = await repo.cachedStatuses() }
    }

    func status(for streamURL: String) -> StreamStatus {
        statuses[streamURL] ?? .unknown
    }

    /// Probe every link in a playlist and refresh the cache.
    @discardableResult
    func probePlaylist(id: String) async -> (online: Int, offline: Int) {
        guard !isProbing else { return (0, 0) }
        isProbing = true
        defer { isProbing = false }
        let result = await repo.probePlaylist(id: id, onProgress: nil)
        statuses = await repo.cachedStatuses()
        app.bumpData()
        return result
    }

    /// Quietly probe, in the background, only the channels we don't yet have a
    /// status for — so dots fill in on their own without re-checking known
    /// links. Bumps the library version when done so lists re-filter/re-render.
    func autoProbe(_ channels: [Channel]) {
        guard !isProbing else { return }
        let unknown = channels.filter { status(for: $0.streamURL) == .unknown }
        guard !unknown.isEmpty else { return }
        isProbing = true
        Task {
            _ = await repo.probe(unknown, onProgress: nil)
            statuses = await repo.cachedStatuses()
            isProbing = false
            app.bumpData()
        }
    }

    /// Flag a link as offline immediately (e.g. playback failed) and persist it.
    func markOffline(_ streamURL: String) { set(streamURL, .offline) }

    /// Flag a link as online (e.g. it just started playing) and persist it.
    func markOnline(_ streamURL: String) { set(streamURL, .online) }

    private func set(_ streamURL: String, _ status: StreamStatus) {
        guard !streamURL.isEmpty, statuses[streamURL] != status else { return }
        statuses[streamURL] = status
        Task { await repo.record(streamURL: streamURL, status: status) }
    }
}
