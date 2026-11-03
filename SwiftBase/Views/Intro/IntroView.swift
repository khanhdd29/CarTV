//
//  IntroView.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//
//  Full-bleed cinematic onboarding: a photo per page with a dark scrim and the
//  copy pinned to the bottom, over a fixed dots + CTA bar.
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
        ZStack(alignment: .bottom) {
            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { offset, page in
                    pageView(page).tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            bottomBar
        }
        .background(Color.black)
        #if MONETIZATION_ENABLED
        .onAppear { loadAds() }
        #endif
        .trackScreen(.intro)
    }

    // MARK: Page

    private func pageView(_ page: IntroPage) -> some View {
        ZStack(alignment: .bottomLeading) {
            GeometryReader { geo in
                Image(page.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            LinearGradient(
                colors: [.clear, .black.opacity(0.35), .black.opacity(0.94)],
                startPoint: .top, endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 12) {
                Text(page.title.localized)
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(page.message.localized)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 230)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ignoresSafeArea()
    }

    // MARK: Bottom bar (fixed)

    private var bottomBar: some View {
        VStack(spacing: 18) {
            pageIndicator
            #if MONETIZATION_ENABLED
            if let vm = currentAdVM {
                NativeContentView(nativeViewModel: vm, style: .nativeNormalMediaCtaTop)
                    .padding(.horizontal, 4)
            }
            #endif
            primaryButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Color.white : Color.white.opacity(0.35))
                    .frame(width: i == index ? 22 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: index)
            }
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.brandGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: AppColors.primary.opacity(0.5), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
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
