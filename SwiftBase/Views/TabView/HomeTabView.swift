//
//  HomeTabView.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//
//  Custom shell: all five tab navigation trees stay alive (so each keeps its own
//  stack + scroll state); only the active one is visible. A floating glass bar
//  replaces the stock tab bar.
//

import SwiftUI
import Factory

struct HomeTabView: View {
    @InjectedObject(\.homeNavi) private var homeNavi: Navigation
    @InjectedObject(\.searchNavi) private var searchNavi: Navigation
    @InjectedObject(\.favoritesNavi) private var favoritesNavi: Navigation
    @InjectedObject(\.recentsNavi) private var recentsNavi: Navigation
    @InjectedObject(\.settingsNavi) private var settingsNavi: Navigation
    @InjectedObject(\.app) private var app: AppManager
    @EnvironmentObject private var coordinator: AppFlowCoordinator

    @State private var isFirstAppear = false

    var body: some View {
        // Observe the language so tab titles re-read `.localized` at runtime.
        let _ = coordinator.language
        return ZStack {
            AppColors.background.ignoresSafeArea()
            root(.home, homeNavi, tab: .home)
            root(.search, searchNavi, tab: .search)
            root(.favorites, favoritesNavi, tab: .favorites)
            root(.recents, recentsNavi, tab: .recents)
            root(.settings, settingsNavi, tab: .settings)
        }
        .overlay(alignment: .bottom) {
            FloatingTabBar(selection: $app.activeTab)
                .padding(.bottom, 2)
        }
        .onAppear {
            guard !isFirstAppear else { return }
            isFirstAppear = true
            app.navi = homeNavi
        }
        .onChange(of: app.activeTab) { tab in didSelectTab(tab) }
    }

    @ViewBuilder
    private func root(_ destination: Destination, _ navigation: Navigation, tab: HomeTab) -> some View {
        let active = app.activeTab == tab
        NavigationRoot(destination: destination, navigation: navigation)
            .opacity(active ? 1 : 0)
            .allowsHitTesting(active)
            .zIndex(active ? 1 : 0)
    }

    /// Keep `app.navi` pointing at the active tab's navigation tree.
    private func didSelectTab(_ tab: HomeTab) {
        switch tab {
        case .home:      app.navi = homeNavi
        case .search:    app.navi = searchNavi
        case .favorites: app.navi = favoritesNavi
        case .recents:   app.navi = recentsNavi
        case .settings:  app.navi = settingsNavi
        }
    }
}

#if DEBUG
#Preview {
    HomeTabView()
        .environmentObject(AppFlowCoordinator())
}
#endif
