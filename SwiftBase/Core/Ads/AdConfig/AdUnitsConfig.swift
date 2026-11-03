#if MONETIZATION_ENABLED
//
//  AdUnitsConfig.swift
//  AdmobSwitUI
//
//  Created by DucManh on 10/03/2026.
//  Tailored for SwiftBase.
//

import Foundation

struct AdUnitsConfig: Codable {
    // MARK: Universal (keep across apps)
    var appopenResume: AdUnitConfig = AdUnitConfig()
    var interSplash: AdUnitConfig = AdUnitConfig()
    var openOnResumeSplash: AdUnitConfig = AdUnitConfig()
    var nativeLanguage: AdUnitConfig = AdUnitConfig()
    var nativeLanguageSelect: AdUnitConfig = AdUnitConfig()
    var nativeIntro1: AdUnitConfig = AdUnitConfig()
    var nativeIntro3: AdUnitConfig = AdUnitConfig()
    var nativeAll: AdUnitConfig = AdUnitConfig()
    var bannerAll: AdUnitConfig = AdUnitConfig()
    var rewardAll: AdUnitConfig = AdUnitConfig()
    var interAll: AdUnitConfig = AdUnitConfig()

    // MARK: SwiftBase-specific placements
    var interHome: AdUnitConfig = AdUnitConfig()    // inter when opening a Home item → detail
    var interBack: AdUnitConfig = AdUnitConfig()    // inter on back navigation

    enum CodingKeys: String, CodingKey {
        case appopenResume
        case interSplash
        case openOnResumeSplash
        case nativeLanguage
        case nativeLanguageSelect
        case nativeIntro1
        case nativeIntro3
        case nativeAll
        case bannerAll
        case rewardAll
        case interAll
        case interHome
        case interBack
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Decode + GÁN `placement = tên slot` cho từng unit. Bước gán placement
        // này BẮT BUỘC để lớp review-gating (AdUnitConfig.isEnable) hoạt động —
        // nó so khớp placement với `adsInReviewBlockedPlacements`.
        func u(_ k: CodingKeys) throws -> AdUnitConfig {
            var unit = try c.decodeIfPresent(AdUnitConfig.self, forKey: k) ?? AdUnitConfig()
            unit.placement = k.stringValue
            return unit
        }
        appopenResume        = try u(.appopenResume)
        interSplash          = try u(.interSplash)
        openOnResumeSplash = try u(.openOnResumeSplash)
        nativeLanguage       = try u(.nativeLanguage)
        nativeLanguageSelect = try u(.nativeLanguageSelect)
        nativeIntro1         = try u(.nativeIntro1)
        nativeIntro3         = try u(.nativeIntro3)
        nativeAll            = try u(.nativeAll)
        bannerAll            = try u(.bannerAll)
        rewardAll            = try u(.rewardAll)
        interAll             = try u(.interAll)
        interHome            = try u(.interHome)
        interBack            = try u(.interBack)
    }
}

#endif
