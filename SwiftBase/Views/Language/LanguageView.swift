//
//  LanguageView.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//
//  Native ads are preserved under `MONETIZATION_ENABLED` (off in v1). The flag
//  PNGs + 16-language list are v1 features and stay on regardless.
//

import SwiftUI
#if MONETIZATION_ENABLED
import ads_swift
#endif
import Factory

struct LanguageView: View {

    /// Where this picker was opened from. Controls the copy, the leading button,
    /// and what happens when the user confirms / cancels.
    enum Mode {
        case onboarding
        case settings
    }

    let mode: Mode

    @EnvironmentObject private var coordinator: AppFlowCoordinator
    @Injected(\.app) private var app

    @State private var hasChosen = false
    @State private var originalLanguage: AppLanguage = .deviceDefault

    @Namespace private var guideNS

    #if MONETIZATION_ENABLED
    @State private var nativeLanguageVM: NativeAdViewModel?
    @State private var nativeLanguageSelectVM: NativeAdViewModel?
    /// Used when the screen is opened from Settings — shows the shared `nativeAll`.
    @State private var nativeAllVM: NativeAdViewModel?
    #endif

    init(mode: Mode = .onboarding) {
        self.mode = mode
    }

    // The language the onboarding guide points at first.
    private let guideLanguage: AppLanguage = .english

    private var isGuiding: Bool { mode == .onboarding }
    private var showRowGuide: Bool { isGuiding && !hasChosen }
    private var showButtonGuide: Bool { isGuiding && hasChosen }
    private var canConfirm: Bool { hasChosen }

    #if MONETIZATION_ENABLED
    /// Settings shows the shared `nativeAll`; onboarding swaps to the post-select
    /// native ad once the user has chosen a language.
    private var currentAdVM: NativeAdViewModel? {
        if mode == .settings { return nativeAllVM }
        return hasChosen ? nativeLanguageSelectVM : nativeLanguageVM
    }
    #endif

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { language in
                        row(for: language)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 100)   // clear the floating tab bar / home indicator
            }

            #if MONETIZATION_ENABLED
            if let vm = currentAdVM {
                NativeContentView(nativeViewModel: vm, style: .nativeNormalMediaCtaTop)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
            #endif
        }
        .onAppear {
            originalLanguage = coordinator.language
            // Settings opens already on the current language; onboarding starts blank.
            if mode == .settings { hasChosen = true }
            #if MONETIZATION_ENABLED
            loadAds()
            #endif
        }
        .trackScreen(mode == .onboarding ? .language : .settingsLanguage)
    }

    private var header: some View {
        VStack(spacing: 8) {
            BasicHeaderView(
                "language".localized,
                showBack: mode == .settings,
                backAction: { cancel() },
                trailingView: { doneButton }
            )

            if mode == .onboarding {
                Text("please_select_language".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, mode == .settings ? 8 : 4)
    }

    /// Top-right confirm. Disabled until a language is chosen (onboarding); the tap
    /// guide flies here once a selection is made.
    private var doneButton: some View {
        Button {
            confirm()
        } label: {
            Image(systemName: "checkmark")
                .font(.title3.weight(.bold))
                .foregroundStyle(canConfirm ? Color.accentColor : Color.secondary.opacity(0.4))
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!canConfirm)
        .overlay(alignment: .center) {
            if showButtonGuide {
                tapGuide.offset(x: 16, y: 22)
            }
        }
    }

    private func row(for language: AppLanguage) -> some View {
        let isSelected = hasChosen && coordinator.language == language
        return Button {
            select(language)
        } label: {
            HStack(spacing: 14) {
                language.flagImageView
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Text(language.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            if showRowGuide && language == guideLanguage {
                tapGuide.offset(x: -10, y: 6)
            }
        }
    }

    #if MONETIZATION_ENABLED
    // MARK: - Ads

    /// Load both native placements once. `isEnable` covers the master switch +
    /// review-block gate, so we never show when disabled.
    private func loadAds() {
        // Opened from Settings → single shared `nativeAll` placement.
        if mode == .settings {
            let all = AdUtil.config.nativeAll
            if all.isEnable, nativeAllVM == nil {
                let vm = NativeAdViewModel(adUnitID: all.id)
                vm.refreshAd()
                nativeAllVM = vm
            }
            return
        }

        // Onboarding → dedicated language placements (initial + post-select).
        let initial = AdUtil.config.nativeLanguage
        if initial.isEnable, nativeLanguageVM == nil {
            let vm = NativeAdViewModel(adUnitID: initial.id)
            vm.refreshAd()
            nativeLanguageVM = vm
        }
        let postSelect = AdUtil.config.nativeLanguageSelect
        if postSelect.isEnable, nativeLanguageSelectVM == nil {
            let vm = NativeAdViewModel(adUnitID: postSelect.id)
            vm.refreshAd()
            nativeLanguageSelectVM = vm
        }
    }
    #endif

    // MARK: - Actions

    /// Apply the picked language immediately (live preview).
    private func select(_ language: AppLanguage) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            hasChosen = true
            coordinator.updateLanguage(language)
        }
    }

    /// Top-right "Done": keep the applied language.
    private func confirm() {
        guard hasChosen else { return }
        switch mode {
        case .onboarding:
            coordinator.didSelectLanguage(coordinator.language)
        case .settings:
            app.navi.pop()
        }
    }

    /// Settings back button: discard the live changes and restore the original.
    private func cancel() {
        if coordinator.language != originalLanguage {
            coordinator.updateLanguage(originalLanguage)
        }
        app.navi.pop()
    }

    /// The looping tap hand. The shared `matchedGeometryEffect` id lets it animate
    /// from the language row up to the done button when a selection is made.
    private var tapGuide: some View {
        LottieTapView(name: "tap", tint: .accentColor)
            .frame(width: 64, height: 64)
            .clipped()
            .allowsHitTesting(false)
            .matchedGeometryEffect(id: "tapGuide", in: guideNS)
    }
}

#if DEBUG
#Preview("Onboarding") {
    LanguageView(mode: .onboarding)
        .environmentObject(AppFlowCoordinator())
}

#Preview("Settings") {
    LanguageView(mode: .settings)
        .environmentObject(AppFlowCoordinator())
}
#endif
