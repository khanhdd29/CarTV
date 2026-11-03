//
//  ChannelsViewModel.swift
//  SwiftBase
//
//  Home as a cinematic rails layout: a featured hero + horizontal rails
//  (Recents, Favourites, then one per channel group). Depends only on the
//  domain repositories.
//

import Foundation
import Factory

struct ChannelRail: Identifiable {
    let id: String
    let title: String
    let channels: [Channel]
}

@MainActor
final class ChannelsViewModel: ObservableObject {
    @Injected(\.playlistRepository) private var playlistRepo: PlaylistRepository
    @Injected(\.userDataRepository) private var userRepo: UserDataRepository
    @Injected(\.playerController) private var player: PlayerController
    @Injected(\.healthCenter) private var health: HealthCenter
    @Injected(\.app) private var app: AppManager

    @Published var hero: Channel?
    @Published var recentsRail: [Channel] = []
    @Published var favouritesRail: [Channel] = []
    @Published var rails: [ChannelRail] = []
    @Published var favouriteURLs: Set<String> = []
    @Published var hasAnyChannel = true
    @Published var isLoading = false

    private let maxGroups = 20
    private let perRail = 12

    func onAppear() { Task { await reload() } }

    func reload() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let count = try await playlistRepo.channelCount()
            hasAnyChannel = count > 0
            favouriteURLs = try await userRepo.favouriteStreamURLs()
            guard count > 0 else {
                hero = nil; recentsRail = []; favouritesRail = []; rails = []
                return
            }

            recentsRail = (try await userRepo.recents(limit: 15)).map(\.asChannel)
            favouritesRail = (try await userRepo.favourites()).map(\.asChannel)

            let groups = try await playlistRepo.groups()
            var built: [ChannelRail] = []
            var loaded: [Channel] = recentsRail + favouritesRail
            let az = app.sortAZ
            for group in groups.prefix(maxGroups) {
                let channels = try await playlistRepo.channels(group: group, limit: perRail, offset: 0, sortByName: az)
                loaded += channels
                let shown = keepLive(channels)
                if !shown.isEmpty {
                    built.append(ChannelRail(id: group, title: group, channels: shown))
                }
            }
            if built.isEmpty {
                let all = try await playlistRepo.channels(group: nil, limit: 30, offset: 0, sortByName: az)
                loaded += all
                built = [ChannelRail(id: "all", title: "all".localized, channels: keepLive(all))]
            }
            rails = built
            hero = keepLive(favouritesRail).first ?? keepLive(recentsRail).first ?? built.first?.channels.first

            // Fill in health in the background for anything not yet probed.
            health.autoProbe(loaded)
        } catch {
            // Soft-fail: leave whatever we had.
        }
    }

    /// Drop channels known to be offline when the "hide dead" setting is on.
    private func keepLive(_ channels: [Channel]) -> [Channel] {
        guard app.hideDeadChannels else { return channels }
        return channels.filter { health.status(for: $0.streamURL) != .offline }
    }

    func isFavourite(_ channel: Channel) -> Bool { favouriteURLs.contains(channel.streamURL) }

    func toggleFavourite(_ channel: Channel) {
        let url = channel.streamURL
        Task {
            do {
                if favouriteURLs.contains(url) {
                    try await userRepo.removeFavourite(streamURL: url)
                    favouriteURLs.remove(url)
                } else {
                    try await userRepo.addFavourite(Favourite(channel: channel))
                    favouriteURLs.insert(url)
                }
            } catch {}
        }
    }

    func play(_ channel: Channel, in list: [Channel]) {
        let queue = list.isEmpty ? [channel] : list
        let startIndex = queue.firstIndex(of: channel) ?? 0
        player.start(queue, at: startIndex)
        app.navi.push(.player, type: .fullScreenCover)
    }

    func openAddPlaylist() { app.navi.push(.addPlaylist, type: .sheet()) }
    func openGuide() { app.navi.push(.guide) }
}
