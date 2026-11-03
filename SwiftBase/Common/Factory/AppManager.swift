//
//  AppManager.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import Foundation
import Combine

@MainActor
final class AppManager: ObservableObject {
    /// The currently selected tab.
    @Published var activeTab: HomeTab = .home

    /// The navigation tree of the active tab. `HomeTabView` keeps this in sync.
    @Published var navi: Navigation = Navigation()

    /// Whether the app is currently backgrounded.
    @Published var isInBackground: Bool = false

    /// Bumped whenever the library changes (playlist added/removed, favourite or
    /// watch recorded) so screens can reload immediately instead of on next appear.
    @Published var dataVersion: Int = 0

    /// When on, channels probed as offline are hidden from the browse lists
    /// (Playlist Health, Driver 3). Persisted across launches.
    @Published var hideDeadChannels: Bool = UserDefaults.standard.bool(forKey: "settings.hideDeadChannels") {
        didSet { UserDefaults.standard.set(hideDeadChannels, forKey: "settings.hideDeadChannels") }
    }

    /// Car mode: a simplified, large-button player layout for use while driving.
    /// Persisted so it stays on across sessions.
    @Published var carMode: Bool = UserDefaults.standard.bool(forKey: "settings.carMode") {
        didSet { UserDefaults.standard.set(carMode, forKey: "settings.carMode") }
    }

    /// Sort channels alphabetically (A–Z) instead of the playlist's own order.
    @Published var sortAZ: Bool = UserDefaults.standard.bool(forKey: "settings.sortAZ") {
        didSet { UserDefaults.standard.set(sortAZ, forKey: "settings.sortAZ") }
    }

    func bumpData() { dataVersion += 1 }
}
