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

    func addPlaylist() { app.navi.push(.addPlaylist, type: .sheet()) }
    func back() { app.navi.pop() }
}
