//
//  AppFlowCoordinator.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//


import SwiftUI
import Combine

@MainActor
final class AppFlowCoordinator: ObservableObject {

    /// The phase currently shown by `ContainerView`.
    @Published private(set) var phase: AppPhase = .splash

    /// The language the user picked (or the system default the first time).
    @Published var language: AppLanguage

    private let store: OnboardingStore

    init(store: OnboardingStore = OnboardingStore()) {
        self.store = store
        self.language = store.language ?? .deviceDefault
    }

    // MARK: - Derived state

    /// `true` once the user has finished language + intro at least once.
    var hasOnboarded: Bool { store.hasOnboarded }

    // MARK: - Transitions

    /// Called when the splash screen finishes. Returning users skip onboarding.
    func splashDidFinish() {
        phase = hasOnboarded ? .home : .language
    }

    /// Called from the onboarding language picker's "Continue" button: persists
    /// the choice and advances the flow to the intro carousel.
    func didSelectLanguage(_ language: AppLanguage) {
        self.language = language
        store.language = language
        phase = .intro
    }

    /// Called from the Settings language picker: persists the choice without
    /// touching the launch phase (the user is already in `.home`).
    func updateLanguage(_ language: AppLanguage) {
        self.language = language
        store.language = language
    }

    /// Called when the user finishes (or skips) the intro carousel.
    func finishOnboarding() {
        store.hasOnboarded = true
        phase = .home
    }

    /// Dev helper: wipe onboarding state and replay the whole flow.
    /// Handy from a debug button in Settings.
    func resetOnboarding() {
        store.hasOnboarded = false
        phase = .splash
    }
}
