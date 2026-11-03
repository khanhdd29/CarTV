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

    func bumpData() { dataVersion += 1 }
}
