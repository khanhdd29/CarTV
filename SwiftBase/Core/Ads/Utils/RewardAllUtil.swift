#if MONETIZATION_ENABLED
//
//  RewardAllUtil.swift
//  Guru cleaner
//
//  Created by DucManh on 14/03/2026.
//

import Foundation
import ads_swift

class RewardAllUtil {
    static let instance = RewardAllUtil()
    var config = RewardAllConfig()

    enum RewardPlacement {
        case similarPhoto
        case largeFile
        case duplicateContact
        case compressVideo

        var isEnable: Bool {
            switch self {
            case .similarPhoto: return RewardAllUtil.instance.config.similarPhoto
            case .largeFile: return RewardAllUtil.instance.config.largeFile
            case .duplicateContact: return RewardAllUtil.instance.config.duplicateContact
            case .compressVideo: return RewardAllUtil.instance.config.compressVideo
            }
        }
    }

    private init() {}

    @MainActor
    func show(placement: RewardPlacement, onDone: @escaping (Bool) -> Void) {
        guard placement.isEnable else {
            onDone(true)
            return
        }

        let adConfig = AdUtil.config.rewardAll

        AdUtil.showReward(config: adConfig, onDone: onDone)
    }
}


#endif
