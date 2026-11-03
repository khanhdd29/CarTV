//
//  FavoritesViewModel.swift
//  SwiftBase
//

import Foundation
import Factory

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Injected(\.userDataRepository) private var userRepo: UserDataRepository
    @Injected(\.playerController) private var player: PlayerController
    @Injected(\.app) private var app: AppManager

    @Published var favourites: [Favourite] = []

    func onAppear() { Task { await load() } }

    func load() async {
        favourites = (try? await userRepo.favourites()) ?? []
    }

    func play(_ favourite: Favourite) {
        let channels = favourites.map(\.asChannel)
        let startIndex = favourites.firstIndex(of: favourite) ?? 0
        player.start(channels, at: startIndex)
        app.navi.push(.player, type: .fullScreenCover)
    }

    func remove(_ favourite: Favourite) {
        Task {
            try? await userRepo.removeFavourite(streamURL: favourite.streamURL)
            await load()
        }
    }
}
