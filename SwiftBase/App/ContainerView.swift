//
//  ContainerView.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import SwiftUI
import Factory

struct ContainerView: View {
    @InjectedObject(\.appFlow) private var coordinator: AppFlowCoordinator

    var body: some View {
        ZStack {
            switch coordinator.phase {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .language:
                LanguageView()
                    .transition(.opacity)
            case .intro:
                IntroView()
                    .transition(.opacity)
            case .home:
                HomeTabView()
                    .transition(.opacity)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .environmentObject(coordinator)
        // Views that show localized text observe `coordinator`, so they re-render
        // (and re-read `.localized`) when the language changes at runtime — no
        // destructive `.id(...)` rebuild that would reset state or close sheets.
        .animation(.easeInOut(duration: 0.35), value: coordinator.phase)
        // CarTV is dark-first (a TV player lets the video own the screen).
        .preferredColorScheme(.dark)
    }
}

#if DEBUG
#Preview {
    ContainerView()
}
#endif
