//
//  ManagePlaylistsViewModel.swift
//  SwiftBase
//

import Foundation
import Factory

@MainActor
final class ManagePlaylistsViewModel: ObservableObject {
    @Injected(\.playlistRepository) private var playlistRepo: PlaylistRepository
    @Injected(\.healthCenter) private var health: HealthCenter
    @Injected(\.app) private var app: AppManager

    @Published var playlists: [PlaylistRef] = []
    @Published var refreshingId: String?
    @Published var checkingId: String?
    @Published var healthSummary: [String: (online: Int, offline: Int)] = [:]
    @Published var errorMessage: String?

    func onAppear() { health.loadCache(); Task { await load() } }

    /// Probe every link in a playlist and show an online/offline tally.
    func checkHealth(_ ref: PlaylistRef) {
        guard checkingId == nil else { return }
        checkingId = ref.id
        Task {
            let result = await health.probePlaylist(id: ref.id)
            healthSummary[ref.id] = result
            checkingId = nil
            app.bumpData()
        }
    }

    func load() async {
        do { playlists = try await playlistRepo.playlists() }
        catch { errorMessage = error.localizedDescription }
    }

    func delete(_ ref: PlaylistRef) {
        Task {
            do { try await playlistRepo.deletePlaylist(id: ref.id); await load(); app.bumpData() }
            catch { errorMessage = error.localizedDescription }
        }
    }

    func refresh(_ ref: PlaylistRef) {
        guard refreshingId == nil else { return }
        refreshingId = ref.id
        Task {
            do { try await playlistRepo.refreshPlaylist(id: ref.id, onProgress: nil) }
            catch { errorMessage = error.localizedDescription }
            refreshingId = nil
            await load()
            app.bumpData()
        }
    }

    /// Rename a playlist.
    func rename(_ ref: PlaylistRef, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != ref.name else { return }
        Task {
            do { try await playlistRepo.renamePlaylist(id: ref.id, name: trimmed); await load(); app.bumpData() }
            catch { errorMessage = error.localizedDescription }
        }
    }

    /// Write the playlist's channels out to a temporary `.m3u` file for sharing.
    func exportM3U(_ ref: PlaylistRef) async -> URL? {
        guard let channels = try? await playlistRepo.channels(playlistId: ref.id), !channels.isEmpty else { return nil }
        var text = "#EXTM3U\n"
        for ch in channels {
            var attrs = ""
            if let logo = ch.logoURL, !logo.isEmpty { attrs += " tvg-logo=\"\(logo)\"" }
            if let tvg = ch.tvgId, !tvg.isEmpty { attrs += " tvg-id=\"\(tvg)\"" }
            if let group = ch.groupTitle, !group.isEmpty { attrs += " group-title=\"\(group)\"" }
            text += "#EXTINF:-1\(attrs),\(ch.name)\n\(ch.streamURL)\n"
        }
        let safeName = ref.name.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeName).m3u")
        do { try text.write(to: url, atomically: true, encoding: .utf8); return url }
        catch { return nil }
    }

    func addPlaylist() { app.navi.push(.addPlaylist, type: .sheet()) }
    func back() { app.navi.pop() }
}
