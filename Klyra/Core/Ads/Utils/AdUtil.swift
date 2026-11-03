#if MONETIZATION_ENABLED
//
//  AdUtil.swift
//  AdmobSwitUI
//
//  Created by Đức Mạnh on 10/03/2026.
//

import Foundation
import ads_swift

enum AdUtil {

    static var config: AdUnitsConfig {
        return RemoteConfigManager.shared.adConfig.adUnitsConfig
    }

    /// Danh sách placement bị TẮT khi app đang bị App Store review
    /// (`AppConfig.isInReview == true`). Các placement KHÔNG nằm trong list này
    /// vẫn hiển thị bình thường theo cờ `enable` của chúng.
    ///
    /// ⚠️ ĐÂY LÀ DANH SÁCH ĐẶC THÙ TỪNG APP — chỉnh cho khớp placement thật.
    /// Quy tắc thường gặp: chặn các format dễ khiến reviewer reject — interstitial
    /// dồn dập (interSplash/interAll/interMatch/interTab/interBack…), app-open khi
    /// resume, và full-screen native intro. Giữ lại banner/native nhẹ trong UI.
    /// Khớp THEO PLACEMENT (keypath), không theo ad unit id.
    static let adsInReviewPaths: [KeyPath<AdUnitsConfig, AdUnitConfig>] = [
        \AdUnitsConfig.interSplash,
        \AdUnitsConfig.interAll,
        \AdUnitsConfig.appopenResume,
        \AdUnitsConfig.interHome,
        \AdUnitsConfig.interBack,
    ]

    static var adsInReview: [AdUnitConfig] {
        adsInReviewPaths.map { config[keyPath: $0] }
    }

    // MARK: - Ads
    @MainActor
    static func showInter(config: AdUnitConfig,
                          onDone: @escaping () -> Void) {
        guard config.isEnable else {
            return onDone()
        }

        AdsManager.shared.showInterstitialAd(
            adUnitID: config.id,
            onDismissed: onDone,
            onFailed: { _ in
                onDone()
            }, showLoading: false
        )
    }

    @MainActor
    static func showOpen(config: AdUnitConfig,
                         onDone: @escaping () -> Void) {
        guard config.isEnable else {
            return onDone()
        }

        AdsManager.shared.showAppOpenAd(
            adUnitID: config.id,
            onDismissed: onDone,
            onFailed: { _ in
                onDone()
            }
        )
    }

    @MainActor
    static func showReward(config: AdUnitConfig,
                           onDone: @escaping (Bool) -> Void) {
        guard config.isEnable else { onDone(true); return }
        AdsManager.shared.showRewardedAd(
            adUnitID: config.id,
            onDismissed: { rewarded in
                onDone(rewarded)
            }
        )
    }

    /// Tắt tạm app-open ad cho tới khi user quay lại app (vd: khi mở Safari /
    /// App Store từ trong app). Gọi từ `.environment(\.openURL)` hook.
    static func suppressAdsUntilReturn() {
        AdsManager.shared.appLifecycleReactor?.setIsExcludeScreen(true)
    }
}


#endif
