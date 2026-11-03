#if MONETIZATION_ENABLED
//
//  InterHomeConfig.swift
//  AdmobSwitUI
//
//  Created by DucManh on 10/03/2026.
//  Tailored for SwiftBase.
//

import Foundation

struct InterHomeConfig: Codable {
    var interHome: Bool = true
    var interBack: Bool = true

    enum CodingKeys: String, CodingKey {
        case interHome
        case interBack
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        interHome = try container.decodeIfPresent(Bool.self, forKey: .interHome) ?? true
        interBack = try container.decodeIfPresent(Bool.self, forKey: .interBack) ?? true
    }

    init(from dict: [String: Bool]) {
        interHome = dict[CodingKeys.interHome.rawValue] ?? true
        interBack = dict[CodingKeys.interBack.rawValue] ?? true
    }

    init() {}
}

#endif
