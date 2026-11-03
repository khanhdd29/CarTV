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
        var tvgId = channel.tvgId
        if tvgId == nil || tvgId?.isEmpty == true {
            tvgId = try? await store.tvgId(forStreamURL: channel.streamURL)
        }
        guard let id = tvgId, !id.isEmpty else { return empty }
        return (try? await store.nowNext(tvgId: id, at: Date().timeIntervalSince1970)) ?? empty
    }

    func clear() async {
        UserDefaults.standard.removeObject(forKey: Self.key)
        try? await store.clearEPG()
    }
}
