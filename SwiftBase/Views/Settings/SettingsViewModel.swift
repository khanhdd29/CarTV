//
//  SettingsViewModel.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import Foundation
import Factory
import StoreKit
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Injected(\.appFlow) private var flow
    @Injected(\.app) private var app

    let appName = "Klyra"
    // TODO: RELEASE — keep in sync with MARKETING_VERSION in the project settings on each release.
    let appVersion = "1.0.0"

    /// Push the language picker onto the Settings tab's navigation stack.
    func openLanguage() {
        app.navi.push(.language)
    }

    /// Push the playlist manager (add / refresh / delete M3U sources).
    func openManagePlaylists() {
        app.navi.push(.managePlaylists)
    }

    /// Push the how-to guide.
    func openGuide() {
        app.navi.push(.guide)
    }

    /// Push the XMLTV program-guide (EPG) source screen.
    func openEPG() {
        app.navi.push(.epg)
    }

    /// Text shared by the "Share app" row.
    var shareMessage: String {
        let link = AppConstants.appLi
        return link.isEmpty ? appName : "\(appName)\n\(link)"
    }

    /// Privacy-policy destination. `nil` when not configured yet (row hidden).
    var policyURL: URL? {
        guard !AppConstants.policyLink.isEmpty else { return nil }
        return URL(string: AppConstants.policyLink)
    }

    /// Native in-app review prompt (falls back silently if the OS suppresses it).
    func rateApp() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    func replayOnboarding() {
        flow.resetOnboarding()
    }
}
