#if MONETIZATION_ENABLED
//
//  RewardAllConfig.swift
//  AdmobSwitUI
//
//  Created by DucManh on 14/03/2026.
//

import Foundation

struct RewardAllConfig: Codable {
    var similarPhoto: Bool = true
    var largeFile: Bool = true
    var duplicateContact: Bool = true
    var compressVideo: Bool = true

    enum CodingKeys: String, CodingKey {
        case similarPhoto
        case largeFile
        case duplicateContact
        case compressVideo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        similarPhoto = try container.decodeIfPresent(Bool.self, forKey: .similarPhoto) ?? true
        largeFile = try container.decodeIfPresent(Bool.self, forKey: .largeFile) ?? true
        duplicateContact = try container.decodeIfPresent(Bool.self, forKey: .duplicateContact) ?? true
        compressVideo = try container.decodeIfPresent(Bool.self, forKey: .compressVideo) ?? true
    }

    init(from dict: [String: Bool]) {
        similarPhoto = dict[CodingKeys.similarPhoto.rawValue] ?? true
        largeFile = dict[CodingKeys.largeFile.rawValue] ?? true
        duplicateContact = dict[CodingKeys.duplicateContact.rawValue] ?? true
        compressVideo = dict[CodingKeys.compressVideo.rawValue] ?? true
    }

    init() {}
}

#endif
