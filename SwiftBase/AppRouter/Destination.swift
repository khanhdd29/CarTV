//
//  Destination.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import SwiftUI

enum Destination: Equatable {
    static func == (lhs: Destination, rhs: Destination) -> Bool {
        lhs.identifier == rhs.identifier
    }

    // Tab roots
    case home              // repurposed: the Channels list
    case search
    case favorites
    case recents
    case settings

    // IPTV screens
    case addPlaylist
    case managePlaylists
    case guide
    case player            // reads its queue from the shared PlayerController

    // Shared
    case language
}

extension Destination {
    var identifier: String {
        switch self {
        case .home:            return "home"
        case .search:          return "search"
        case .favorites:       return "favorites"
        case .recents:         return "recents"
        case .settings:        return "settings"
        case .addPlaylist:     return "addPlaylist"
        case .managePlaylists: return "managePlaylists"
        case .guide:           return "guide"
        case .player:          return "player"
        case .language:        return "language"
        }
    }
}

extension Navigation {
    @ViewBuilder
    internal func screen(for destinationWrapper: DestinationWrapper) -> some View {
        switch destinationWrapper.destination {
        case .home:
            ChannelsScreen()
        case .search:
            SearchScreen()
        case .favorites:
            FavoritesScreen()
        case .recents:
            RecentsScreen()
        case .settings:
            SettingsScreen()
        case .addPlaylist:
            AddPlaylistScreen()
        case .managePlaylists:
            ManagePlaylistsScreen()
        case .guide:
            GuideScreen()
        case .player:
            PlayerScreen()
        case .language:
            LanguageView(mode: .settings)
        }
    }
}
