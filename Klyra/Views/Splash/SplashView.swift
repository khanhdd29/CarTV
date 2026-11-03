//
//  SplashView.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//
//  The original ad-init splash is preserved under `MONETIZATION_ENABLED`. v1 is
//  local-only, so the `#else` branch just shows a brief branded progress and
//  advances the launch flow. Re-enable monetization → the original runs again.
//

import SwiftUI

#if MONETIZATION_ENABLED
import ads_swift
import GoogleMobileAds
import AppTrackingTransparency

/// Phases of the splash init sequence, each mapped to a progress fraction so the
/// bar advances as real work completes (not on a fake timer).
private enum SplashStep: Equatable {
    case idle, fetchingConfig, initializingAds, requestingConsent, showingInter, completed

    var progress: Double {
        switch self {
        case .idle:              return 0.05
        case .fetchingConfig:    return 0.25
        case .initializingAds:   return 0.5
        case .requestingConsent: return 0.7
        case .showingInter:      return 0.9
        case .completed:         return 1.0
        }
    }
}

struct SplashView: View {
    @EnvironmentObject private var coordinator: AppFlowCoordinator
    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false
    @State private var didStart = false
    @State private var step: SplashStep = .idle

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(Color.accentColor)
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
            Text("SwiftBase")
                .font(.largeTitle.bold())
                .opacity(appeared ? 1 : 0)
            Spacer()
            VStack(spacing: 10) {
                ProgressView(value: step.progress)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                    .frame(width: 200)
                    .animation(.easeInOut(duration: 0.3), value: step)
                Text("\("loading".localized) \(Int(step.progress * 100))%")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
            .padding(.bottom, 60)
            .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
        }
        .task {
            guard !didStart else { return }
            didStart = true
            await configAds()
        }
        .trackScreen(.splash)
    }
}

// MARK: - Ad initialization sequence (order is load-bearing)
private extension SplashView {

    func configAds() async {
        step = .fetchingConfig
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            RemoteConfigManager.shared.fetchAndActivate { cont.resume() }
        }

        step = .initializingAds
        AdsManager.shared.initialize(
            intervalShowInter: RemoteConfigManager.shared.adConfig.intervalShowInter,
            nativeAdColorConfig: Self.nativeAdColorConfig(for: colorScheme)
        )

        AdjustManager.shared.initialize()
        #if DEBUG
        setTestDeviceIdentifiers()
        #endif

        let useInterSplash = RemoteConfigManager.shared.adConfig.useInterSplash
        let openSplashConfig = AdUtil.config.openOnResumeSplash
        if !useInterSplash && openSplashConfig.isEnable {
            AdsManager.shared.initAppOpenAd(
                appOpenAdUnitId: openSplashConfig.id,
                opacity: openSplashConfig.opacity,
                autoEnable: false
            )
        }

        step = .requestingConsent
        await requestConsent()

        step = .showingInter
        if useInterSplash {
            await showInterSplash()
        } else {
            await showOpenSplash(config: openSplashConfig)
        }

        let appOpen = AdUtil.config.appopenResume
        if appOpen.isEnable {
            AdsManager.shared.initAppOpenAd(
                appOpenAdUnitId: appOpen.id,
                opacity: appOpen.opacity,
                autoEnable: false
            )
        }

        step = .completed
        AdsManager.shared.appLifecycleReactor?.setShouldShow(true)
        InterHomeUtil.instance.preload()
        coordinator.splashDidFinish()
    }

    func requestConsent() async {
        AdsManager.shared.appLifecycleReactor?.setIsExcludeScreen(true)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            ATTrackingManager.requestTrackingAuthorization { _ in cont.resume() }
        }
        await UMPManager.shared.requestConsentIfNeeded()
        AdsManager.shared.appLifecycleReactor?.setIsExcludeScreen(false)
    }

    func showInterSplash() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            AdUtil.showInter(config: AdUtil.config.interSplash) { cont.resume() }
        }
    }

    func showOpenSplash(config: AdUnitConfig) async {
        await withCheckedContinuation { cont in
            AdUtil.showOpen(config: config) { cont.resume() }
        }
    }

    func setTestDeviceIdentifiers() {
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = []
    }

    static func nativeAdColorConfig(for scheme: ColorScheme) -> NativeAdColorConfig {
        let adBadge: UIColor = scheme == .dark ? .tertiaryLabel : .secondaryLabel
        return NativeAdColorConfig(
            headlineColor: Color(uiColor: .label),
            bodyColor: Color(uiColor: .secondaryLabel),
            adColor: Color(uiColor: adBadge),
            adBackgroundColor: Color(uiColor: .secondarySystemGroupedBackground),
            callToActionBackgroundColor: .accentColor,
            callToActionTextColor: .white,
            backgroundColor: Color(uiColor: .systemBackground)
        )
    }
}

#else

// MARK: - v1 (local-only, no ads)

struct SplashView: View {
    @EnvironmentObject private var coordinator: AppFlowCoordinator
    @State private var appeared = false
    @State private var didStart = false
    @State private var progress: Double = 0.05

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 116, height: 116)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: AppColors.primary.opacity(0.45), radius: 22, y: 10)
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
            Text("Klyra IPTV")
                .font(.largeTitle.bold())
                .opacity(appeared ? 1 : 0)
            Spacer()
            VStack(spacing: 10) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(AppColors.primary)
                    .frame(width: 200)
                    .animation(.easeInOut(duration: 0.3), value: progress)
                Text("\("loading".localized) \(Int(progress * 100))%")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
            .padding(.bottom, 60)
            .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { appeared = true }
        }
        .task {
            guard !didStart else { return }
            didStart = true
            await runStartup()
        }
        .trackScreen(.splash)
    }

    private func runStartup() async {
        for value in [0.35, 0.7, 1.0] {
            try? await Task.sleep(nanoseconds: 250_000_000)
            progress = value
        }
        coordinator.splashDidFinish()
    }
}

#endif

#if DEBUG
#Preview {
    SplashView()
        .environmentObject(AppFlowCoordinator())
}
#endif
