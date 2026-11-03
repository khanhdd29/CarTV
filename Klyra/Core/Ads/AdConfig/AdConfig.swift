#if MONETIZATION_ENABLED
//
//  AdConfig.swift
//  AdmobSwitUI
//
//  Created by DucManh on 10/03/2026.
//

import Foundation

struct AdConfig: Codable {
    var showAllAds: Bool = true
    var showTopButton: Bool = true
    var intervalShowInter: Int = 15
    var useInterSplash: Bool = true
    var adUnitsConfig: AdUnitsConfig = AdUnitsConfig()

    enum CodingKeys: String, CodingKey {
        case showAllAds
        case showTopButton
        case intervalShowInter
        case adUnitsConfig
        case useInterSplash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showAllAds = try container.decodeIfPresent(Bool.self, forKey: .showAllAds) ?? true
        showTopButton = try container.decodeIfPresent(Bool.self, forKey: .showTopButton) ?? true
        intervalShowInter = try container.decodeIfPresent(Int.self, forKey: .intervalShowInter) ?? 15
        useInterSplash = try container.decodeIfPresent(Bool.self, forKey: .useInterSplash) ?? true
        adUnitsConfig = try container.decodeIfPresent(AdUnitsConfig.self, forKey: .adUnitsConfig) ?? AdUnitsConfig()
    }

    init() {}
}

#endif
