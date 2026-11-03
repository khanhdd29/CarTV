//
//  RecentsViewModel.swift
//  SwiftBase
//

import Foundation
import Factory

@MainActor
final class RecentsViewModel: ObservableObject {
    @Injected(\.userDataRepository) private var userRepo: UserDataRepository
    @Injected(\.playerController) private var player: PlayerController
    @Injected(\.app) private var app: AppManager

    @Published var recents: [WatchHistory] = []

    func onAppear() { Task { await load() } }

    func load() async {
        recents = (try? await userRepo.recents(limit: 100)) ?? []
    }

    func clearAll() {
        Task {
            try? await userRepo.clearRecents()
            await load()
        }
    }

    func play(_ item: WatchHistory) {
        let channels = recents.map(\.asChannel)
        let startIndex = recents.firstIndex(of: item) ?? 0
        player.start(channels, at: startIndex)
        app.navi.push(.player, type: .fullScreenCover)
    }
}
