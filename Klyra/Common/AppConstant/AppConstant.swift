//
//  AppConstant.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import Foundation

/// Values that can only be filled once the app exists on App Store Connect.
///
/// 🔎 Grep the whole project for `TODO: RELEASE` to jump to every placeholder
///    you must fill before submitting (see AppStore/RELEASE_STEPS.md).
struct AppConstants {
    /// App Store numeric id — the digits after "id" in the store URL,
    /// e.g. `apps.apple.com/app/id6701234567` → `"6701234567"`.
    /// Drives the Settings → Share link. While empty, Share sends just the name.
    static let appId = "6830094898"

    /// Published privacy-policy URL for the Settings → "Privacy Policy" row.
    /// While empty, the row still shows but tapping it does nothing.
    // TODO: RELEASE — set the privacy-policy URL (same one used in App Privacy, Step 4).
    static let policyLink = "https://nguyenthingocanhhh.netlify.app/policy"

    /// Full App Store page link, built from `appId`. Used by Share.
    static let appLi = "https://apps.apple.com/app/id\(appId)"
}
