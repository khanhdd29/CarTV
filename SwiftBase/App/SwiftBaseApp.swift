//
//  SwiftBaseApp.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//
//  Monetization/analytics (ads, Firebase, Adjust) is kept but DISABLED for the
//  local-only v1 via the `MONETIZATION_ENABLED` compile flag (undefined = off).
//  To re-enable: define MONETIZATION_ENABLED, re-add the SPM packages, and
//  un-exclude Core/Ads. See docs/CarTV-v1-Changes.md.
//

import SwiftUI

@main
struct SwiftBaseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContainerView()
        }
        #if MONETIZATION_ENABLED
        // Mute app-open ads when the user leaves to Safari / App Store and
        // returns — otherwise the app-open ad fires on resume, which is jarring.
        .environment(\.openURL, OpenURLAction { _ in
            AdUtil.suppressAdsUntilReturn()
            return .systemAction
        })
        #endif
    }
}
