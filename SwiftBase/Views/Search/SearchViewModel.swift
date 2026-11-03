//
//  SearchViewModel.swift
//  SwiftBase
//
//  Instant channel search backed by SQLite FTS5 (spec §5.4). Debounced from the
//  view's `.task(id:)`.
//

import Foundation
import Factory

@MainActor
final class SearchViewModel: ObservableObject {
    @Injected(\.playlistRepository) private var playlistRepo: PlaylistRepository
    @Injected(\.userDataRepository) private var userRepo: UserDataRepository
    @Injected(\.playerController) private var player: PlayerController
    @Injected(\.app) private var app: AppManager

    @Published var query = ""
    @Published var results: [Channel] = []
    @Published var favouriteURLs: Set<String> = []
    @Published var isSearching = false

    func onAppear() {
        Task { favouriteURLs = (try? await userRepo.favouriteStreamURLs()) ?? [] }
    }

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { results = []; return }
        isSearching = true
        defer { isSearching = false }
        results = (try? await playlistRepo.search(trimmed, limit: 200)) ?? []
    }

    func isFavourite(_ channel: Channel) -> Bool { favouriteURLs.contains(channel.streamURL) }

    func toggleFavourite(_ channel: Channel) {
        let url = channel.streamURL
        Task {
            if favouriteURLs.contains(url) {
                try? await userRepo.removeFavourite(streamURL: url)
                favouriteURLs.remove(url)
            } else {
                try? await userRepo.addFavourite(Favourite(channel: channel))
                favouriteURLs.insert(url)
            }
        }
    }

    func play(_ channel: Channel) {
        let startIndex = results.firstIndex(of: channel) ?? 0
        player.start(results, at: startIndex)
        app.navi.push(.player, type: .fullScreenCover)
    }
}
