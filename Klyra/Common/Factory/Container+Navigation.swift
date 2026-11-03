//
//  Container+Navigation.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import Foundation
import Factory

// MARK: - App state

extension Container {
    var app: Factory<AppManager> {
        Factory(self) { @MainActor in AppManager() }.singleton
    }

    /// Owns the launch-flow phase (splash → language → intro → home). One shared
    /// instance: `ContainerView` observes it, view models drive it.
    var appFlow: Factory<AppFlowCoordinator> {
        Factory(self) { @MainActor in AppFlowCoordinator() }.singleton
    }
}

// MARK: - One navigation tree per tab

extension Container {
    var homeNavi: Factory<Navigation> {
        Factory(self) { @MainActor in Navigation() }.singleton
    }

    var searchNavi: Factory<Navigation> {
        Factory(self) { @MainActor in Navigation() }.singleton
    }

    var favoritesNavi: Factory<Navigation> {
        Factory(self) { @MainActor in Navigation() }.singleton
    }

    var recentsNavi: Factory<Navigation> {
        Factory(self) { @MainActor in Navigation() }.singleton
    }

    var settingsNavi: Factory<Navigation> {
        Factory(self) { @MainActor in Navigation() }.singleton
    }
}
