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
    @InjectedObject(\.appLock) private var appLock: AppLock
    @Environment(\.scenePhase) private var scenePhase

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

            if appLock.isLocked {
                AppLockGate().transition(.opacity).zIndex(10)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                // Re-lock when leaving the app so returning needs the PIN, and
                // queue a background health refresh.
                appLock.lockIfEnabled()
                HealthRefreshScheduler.schedule()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .environmentObject(coordinator)
        // Views that show localized text observe `coordinator`, so they re-render
        // (and re-read `.localized`) when the language changes at runtime — no
        // destructive `.id(...)` rebuild that would reset state or close sheets.
        .animation(.easeInOut(duration: 0.35), value: coordinator.phase)
        // Klyra is dark-first (a TV player lets the video own the screen).
        .preferredColorScheme(.dark)
    }
}

#if DEBUG
#Preview {
    ContainerView()
}
#endif
