//
//  LocalHealthRepository.swift
//  SwiftBase
//
//  DATA layer for Playlist Health. Probes links with `StreamProbe` (bounded
//  concurrency) and caches results in SQLite. Everything stays on-device.
//

import Foundation

final class LocalHealthRepository: HealthRepository {
    private let store: IPTVStore
    private let prober = StreamProbe()

    init(store: IPTVStore) {
        self.store = store
    }

    func cachedStatuses() async -> [String: StreamStatus] {
        (try? await store.allHealth()) ?? [:]
    }

    @discardableResult
    func probe(_ channels: [Channel],
               onProgress: (@Sendable (Int, Int) -> Void)?) async -> (online: Int, offline: Int) {
        // De-dupe by stream URL and skip anything we can't turn into a URL.
        var seen = Set<String>()
        var urls: [URL] = []
        var urlToStream: [String: String] = [:]
        for ch in channels {
            guard let u = ch.streamingURL, !seen.contains(ch.streamURL) else { continue }
            seen.insert(ch.streamURL)
            urls.append(u)
            urlToStream[u.absoluteString] = ch.streamURL
        }
        guard !urls.isEmpty else { return (0, 0) }

        let acc = ProbeAccumulator(total: urls.count, onProgress: onProgress)
        await prober.sweep(urls) { url, ok in
            let key = urlToStream[url.absoluteString] ?? url.absoluteString
            await acc.record(streamURL: key, ok: ok)
        }

        let snap = await acc.snapshot()
        let now = Date().timeIntervalSince1970
        for (streamURL, status) in snap.results {
            try? await store.setHealth(streamURL: streamURL, status: status, at: now)
        }
        return (snap.online, snap.offline)
    }

    @discardableResult
    func probePlaylist(id: String,
                       onProgress: (@Sendable (Int, Int) -> Void)?) async -> (online: Int, offline: Int) {
        let channels = (try? await store.channels(playlistId: id)) ?? []
        return await probe(channels, onProgress: onProgress)
    }

    func record(streamURL: String, status: StreamStatus) async {
        try? await store.setHealth(streamURL: streamURL, status: status,
                                   at: Date().timeIntervalSince1970)
    }
}

/// Collects sweep results off the concurrent probe tasks.
private actor ProbeAccumulator {
    private let total: Int
    private let onProgress: (@Sendable (Int, Int) -> Void)?
    private var done = 0
    private(set) var online = 0
    private(set) var offline = 0
    private(set) var results: [(String, StreamStatus)] = []

    init(total: Int, onProgress: (@Sendable (Int, Int) -> Void)?) {
        self.total = total
        self.onProgress = onProgress
    }

    func record(streamURL: String, ok: Bool) {
        done += 1
        if ok { online += 1 } else { offline += 1 }
        results.append((streamURL, ok ? .online : .offline))
        onProgress?(done, total)
    }

    func snapshot() -> (online: Int, offline: Int, results: [(String, StreamStatus)]) {
        (online, offline, results)
    }
}
