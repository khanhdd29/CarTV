//
//  LocalEPGRepository.swift
//  SwiftBase
//
//  DATA layer — downloads + parses the XMLTV source off the main thread and
//  caches a near-term window locally. The source URL is a light setting
//  (UserDefaults); the programmes live in SQLite.
//

import Foundation

final class LocalEPGRepository: EPGRepository {
    private let store: IPTVStore
    private let downloader = PlaylistDownloader()
    private static let key = "epg.sourceURL"

    init(store: IPTVStore) {
        self.store = store
    }

    func sourceURL() async -> String? {
        UserDefaults.standard.string(forKey: Self.key)
    }

    @discardableResult
    func refresh(url: URL?, onProgress: (@Sendable (Int) -> Void)?) async throws -> Int {
        let target: URL
        if let url {
            target = url
            UserDefaults.standard.set(url.absoluteString, forKey: Self.key)
        } else if let saved = UserDefaults.standard.string(forKey: Self.key), let u = URL(string: saved) {
            target = u
        } else {
            throw AppError.invalidURL
        }

        let file = try await downloader.download(target)
        defer { try? FileManager.default.removeItem(at: file) }

        // Runs on a background executor (this method is nonisolated) — safe for the
        // heavy XML parse.
        let programmes = try XMLTVParser().parse(fileURL: file)
        onProgress?(programmes.count)

        try await store.replaceEPG(programmes)
        return try await store.epgCount()
    }

    func nowNext(for channel: Channel) async -> EPGNowNext {
        let empty = EPGNowNext(now: nil, next: nil)
        guard let id = await resolveTvgId(for: channel) else { return empty }
        return (try? await store.nowNext(tvgId: id, at: Date().timeIntervalSince1970)) ?? empty
    }

    func schedule(for channel: Channel) async -> [EPGEntry] {
        guard let id = await resolveTvgId(for: channel) else { return [] }
        let now = Date().timeIntervalSince1970
        return (try? await store.schedule(tvgId: id, from: now - 3 * 3600, to: now + 24 * 3600)) ?? []
    }

    private func resolveTvgId(for channel: Channel) async -> String? {
        if let id = channel.tvgId, !id.isEmpty { return id }
        let resolved = try? await store.tvgId(forStreamURL: channel.streamURL)
        return (resolved?.isEmpty == false) ? resolved : nil
    }

    func clear() async {
        UserDefaults.standard.removeObject(forKey: Self.key)
        try? await store.clearEPG()
    }
}
