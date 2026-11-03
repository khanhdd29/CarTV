//
//  StreamProbe.swift
//  SwiftBase
//
//  Lightweight reachability check for a stream link. Not a full play test — it
//  asks for the first few bytes (or the HLS manifest) with a short timeout, so a
//  sweep over a big playlist stays quick and cheap (spec §Driver 3).
//

import Foundation

struct StreamProbe: Sendable {
    private let session: URLSession

    /// `timeout` is the per-request window; links that don't answer in it are
    /// treated as offline.
    init(timeout: TimeInterval = 8) {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = timeout
        cfg.timeoutIntervalForResource = timeout
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: cfg)
    }

    /// `true` if the link answered with a success status and some payload.
    func check(_ url: URL) async -> Bool {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        // Only the head of the stream — enough to prove it's alive without
        // pulling a whole segment.
        req.setValue("bytes=0-2047", forHTTPHeaderField: "Range")
        req.setValue("VLC/3.0 LibVLC/3.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else { return false }
            // 2xx (incl. 206 Partial Content) with a non-empty body = alive.
            return (200..<300).contains(http.statusCode) && !data.isEmpty
        } catch {
            return false
        }
    }

    /// Probe many URLs with bounded concurrency; `onEach` is awaited per
    /// completion (so a caller can persist each result before the sweep ends).
    func sweep(_ urls: [URL],
               maxConcurrent: Int = 6,
               onEach: @Sendable @escaping (URL, Bool) async -> Void) async {
        var iterator = urls.makeIterator()
        await withTaskGroup(of: Void.self) { group in
            func addNext() {
                guard let url = iterator.next() else { return }
                group.addTask { await onEach(url, await check(url)) }
            }
            for _ in 0..<max(1, maxConcurrent) { addNext() }
            while await group.next() != nil { addNext() }
        }
    }
}
