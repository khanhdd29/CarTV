//
//  IntroView.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//
//  Native ads are preserved under `MONETIZATION_ENABLED` (off in v1).
//

import SwiftUI
#if MONETIZATION_ENABLED
import ads_swift
#endif

struct IntroView: View {
    @EnvironmentObject private var coordinator: AppFlowCoordinator
    @State private var index = 0

    private let pages = IntroPage.all
    private var isLast: Bool { index == pages.count - 1 }

    private var showSkip: Bool {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return version == "1.0.0"
    }

    #if MONETIZATION_ENABLED
    @State private var nativeIntro1VM: NativeAdViewModel?
    @State private var nativeIntro3VM: NativeAdViewModel?

    private var currentAdVM: NativeAdViewModel? {
        switch index {
        case 0:               return nativeIntro1VM
        case pages.count - 1: return nativeIntro3VM
        default:              return nil
        }
    }
    #endif

    var body: some View {
        VStack(spacing: 0) {
            skipBar

            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { offset, page in
                    pageView(page)
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageIndicator

            primaryButton

            #if MONETIZATION_ENABLED
            if let vm = currentAdVM {
                NativeContentView(nativeViewModel: vm, style: .nativeNormalMediaCtaTop)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            #endif
        }
        #if MONETIZATION_ENABLED
        .onAppear { loadAds() }
        #endif
        .trackScreen(.intro)
    }

    /// Custom page dots — no pill background, current page tinted.
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Circle()
                    .fill(i == index ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: index)
            }
        }
        .padding(.top, 8)
    }

    private var skipBar: some View {
        HStack {
            Spacer()
            Button("skip".localized) { coordinator.finishOnboarding() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .opacity(showSkip && !isLast ? 1 : 0)
                .disabled(!showSkip || isLast)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .frame(height: 28)
    }

    private func pageView(_ page: IntroPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: page.systemImage)
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(page.tint)
            VStack(spacing: 12) {
                Text(page.title.localized)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(page.message.localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    private var primaryButton: some View {
        Button {
            if isLast {
                coordinator.finishOnboarding()
            } else {
                withAnimation { index += 1 }
            }
        } label: {
            Text((isLast ? "get_started" : "next").localized)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding()
        }
    }

    #if MONETIZATION_ENABLED
    /// Load both intro placements up front so they're ready as the user pages.
    private func loadAds() {
        let c1 = AdUtil.config.nativeIntro1
        if c1.isEnable, nativeIntro1VM == nil {
            let vm = NativeAdViewModel(adUnitID: c1.id)
            vm.refreshAd()
            nativeIntro1VM = vm
        }
        let c3 = AdUtil.config.nativeIntro3
        if c3.isEnable, nativeIntro3VM == nil {
            let vm = NativeAdViewModel(adUnitID: c3.id)
            vm.refreshAd()
            nativeIntro3VM = vm
        }
    }
    #endif
}

#if DEBUG
#Preview {
    IntroView()
        .environmentObject(AppFlowCoordinator())
}
#endif
