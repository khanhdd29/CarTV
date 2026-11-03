#if MONETIZATION_ENABLED
//
//  AppConfig.swift
//  AdmobSwitUI
//
//  Decode từ key Remote Config `app_configs` (tách khỏi `ad_config`).
//  Chứa các cờ vận hành app + cờ phát hiện "đang bị review".
//

import Foundation

struct AppConfig: Codable {

    var onlyShowLanguage: Bool = true
    var appVersion: String = ""
    var appToken: String = ""
    var eventToken: String = ""

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        onlyShowLanguage = try c.decodeIfPresent(Bool.self, forKey: .onlyShowLanguage) ?? false
        appVersion = try c.decodeIfPresent(String.self, forKey: .appVersion) ?? ""
        appToken = try c.decodeIfPresent(String.self, forKey: .appToken) ?? ""
        eventToken = try c.decodeIfPresent(String.self, forKey: .eventToken) ?? ""
    }

    var isInReview: Bool {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return appVersion == bundleVersion
    }
}

#endif
