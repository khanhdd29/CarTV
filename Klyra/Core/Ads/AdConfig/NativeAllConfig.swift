#if MONETIZATION_ENABLED
//
//  NativeAllConfig.swift
//  Guru cleaner
//
//  Created by DucManh on 16/03/2026.
//

import Foundation

struct NativeAllConfig: Codable {
    var similarPhoto: Bool = true
    var livePhoto: Bool = true
    var screenshots: Bool = true
    var panoramas: Bool = true
    var oldPhoto: Bool = true
    var oldVideo: Bool = true
    var compressionComplete: Bool = true

    enum CodingKeys: String, CodingKey {
        case similarPhoto
        case livePhoto
        case screenshots
        case panoramas
        case oldPhoto
        case oldVideo
        case compressionComplete
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        similarPhoto = try container.decodeIfPresent(Bool.self, forKey: .similarPhoto) ?? true
        livePhoto = try container.decodeIfPresent(Bool.self, forKey: .livePhoto) ?? true
        screenshots = try container.decodeIfPresent(Bool.self, forKey: .screenshots) ?? true
        panoramas = try container.decodeIfPresent(Bool.self, forKey: .panoramas) ?? true
        oldPhoto = try container.decodeIfPresent(Bool.self, forKey: .oldPhoto) ?? true
        oldVideo = try container.decodeIfPresent(Bool.self, forKey: .oldVideo) ?? true
        compressionComplete = try container.decodeIfPresent(Bool.self, forKey: .compressionComplete) ?? true
    }

    init(from dict: [String: Bool]) {
        similarPhoto = dict[CodingKeys.similarPhoto.rawValue] ?? true
        livePhoto = dict[CodingKeys.livePhoto.rawValue] ?? true
        screenshots = dict[CodingKeys.screenshots.rawValue] ?? true
        panoramas = dict[CodingKeys.panoramas.rawValue] ?? true
        oldPhoto = dict[CodingKeys.oldPhoto.rawValue] ?? true
        oldVideo = dict[CodingKeys.oldVideo.rawValue] ?? true
        compressionComplete = dict[CodingKeys.compressionComplete.rawValue] ?? true
    }

    init() {}
}

#endif
