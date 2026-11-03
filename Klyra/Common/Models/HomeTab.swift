//
//  HomeTab.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import Foundation

enum HomeTab: Hashable, CaseIterable {
    case home          // Channels
    case search
    case favorites
    case recents
    case settings

    var title: String {
        switch self {
        case .home:      return "channels".localized
        case .search:    return "search".localized
        case .favorites: return "favorites".localized
        case .recents:   return "recents".localized
        case .settings:  return "settings".localized
        }
    }

    /// SF Symbol name for the tab bar item.
    var icon: String {
        switch self {
        case .home:      return "tv.fill"
        case .search:    return "magnifyingglass"
        case .favorites: return "heart.fill"
        case .recents:   return "clock.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}
