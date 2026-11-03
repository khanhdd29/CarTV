//
//  OnboardingStore.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import Foundation

final class OnboardingStore {

    private let defaults: UserDefaults

    private enum Keys {
        static let didOnboard = "appflow.didCompleteOnboarding"
        // Shared with `String.localized` so the picked language drives lookups.
        static let language = Constants.Key.languageSelected
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// `true` once the user has finished language + intro at least once.
    var hasOnboarded: Bool {
        get { defaults.bool(forKey: Keys.didOnboard) }
        set { defaults.set(newValue, forKey: Keys.didOnboard) }
    }

    /// The persisted language, or `nil` if the user hasn't chosen yet.
    var language: AppLanguage? {
        get { AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") }
        set { defaults.set(newValue?.rawValue, forKey: Keys.language) }
    }
}
