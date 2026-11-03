#if MONETIZATION_ENABLED
//
//  InterHomeUtil.swift
//  Guru cleaner
//
//  Created by Antigravity on 14/03/2026.
//  Tailored for SwiftBase.
//

import Foundation
import ads_swift

class InterHomeUtil {
    static let instance = InterHomeUtil()
    var config = InterHomeConfig()

    enum AdPlacement {
        case home
        case back

        var useInterAll: Bool {
            switch self {
            case .home: return InterHomeUtil.instance.config.interHome
            case .back: return InterHomeUtil.instance.config.interBack
            }
        }

        var adConfig: AdUnitConfig {
            switch self {
            case .home: return AdUtil.config.interHome
            case .back: return AdUtil.config.interBack
            }
        }
    }

    private init() {}

    func preload() {
        let interAll = AdUtil.config.interAll
        if interAll.isEnable && interAll.opacity > 0 {
            AdsManager.shared.preloadInterstitialAd(
                adUnitID: interAll.id,
                opacity: interAll.opacity
            )
        }
    }

    @MainActor
    func show(placement: AdPlacement, onDone: (() -> Void)? = nil) {
        let adConfig = placement.adConfig
        if !adConfig.isEnable {
            onDone?()
            return
        }

        let usedConfig = placement.useInterAll && AdUtil.config.interAll.opacity > 0
                ? AdUtil.config.interAll
                : adConfig

        AdsManager.shared.showInterstitialAd(
            adUnitID: usedConfig.id,
            onDismissed: onDone
        ) { _ in onDone?() }
    }
}

#endif
