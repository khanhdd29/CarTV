#if MONETIZATION_ENABLED
//
//  ConfigAdMobManager.swift
//  AdmobSwitUI
//
//  Created by DucManh on 10/03/2026.
//

import Foundation
import FirebaseRemoteConfig

// MARK: - Ad Unit Config Models (Moved to ad_config directory)

// MARK: - Remote Config Key
enum RemoteConfigType: CaseIterable {
    case adConfig
    case appConfig

    var key: String {
        switch self {
        case .adConfig: return "ad_config"
        case .appConfig: return "app_configs"
        }
    }
}

// MARK: - Remote Config Manager

class RemoteConfigManager {
    static let shared = RemoteConfigManager()

    var adConfig: AdConfig = AdConfig()
    var appConfig: AppConfig = AppConfig()
    var nativeAllConfig: NativeAllConfig = NativeAllConfig()

    /// Tập placement bị chặn khi app đang review. Build lại mỗi lần config đổi.
    /// RỖNG khi `appConfig.isInReview == false` → ngoài lúc review không chặn gì.
    private(set) var adsInReviewBlockedPlacements: Set<String> = []

    private let remoteConfig = RemoteConfig.remoteConfig()

    private init() {
        loadDefaultValues()
        _ = AdRevenueLogger.shared
    }

    // MARK: - Private Methods
    private func loadDefaultValues() {
        getConfigValue()
    }

    private func getConfigValue(completed: @escaping () -> () = {}) {
        decodeAdConfig()
        decodeAppConfig()
        rebuildAdsInReviewCache()
        completed()
    }

    /// Build lại `adsInReviewBlockedPlacements` từ `self.adConfig` — KHÔNG dùng
    /// `AdUtil.adsInReview` để tránh truy cập đệ quy `RemoteConfigManager.shared`
    /// khi hàm này được gọi từ `init()` (sẽ crash EXC_BREAKPOINT).
    /// Chặn theo PLACEMENT (slot), không theo `id`: nhiều placement có thể dùng
    /// chung một ad unit id nên chặn theo id sẽ tắt nhầm toàn bộ ads.
    private func rebuildAdsInReviewCache() {
        guard appConfig.isInReview else {
            adsInReviewBlockedPlacements = []
            return
        }
        let units = self.adConfig.adUnitsConfig
        let placements: [String] = AdUtil.adsInReviewPaths
            .map { units[keyPath: $0].placement }
            .filter { !$0.isEmpty }
        adsInReviewBlockedPlacements = Set(placements)
    }

    private func decodeAdConfig() {
        let configString = remoteConfig.configValue(forKey: RemoteConfigType.adConfig.key).stringValue
        guard !configString.isEmpty else { return }
        guard let data = configString.data(using: .utf8) else {
            print("❌ Invalid ad_config string"); return
        }
        do {
            adConfig = try JSONDecoder().decode(AdConfig.self, from: data)
            if let extraKeys = adConfig.adUnitsConfig.interAll.extraKeys {
                InterHomeUtil.instance.config = InterHomeConfig(from: extraKeys)
            }
            if let extraKeys = adConfig.adUnitsConfig.rewardAll.extraKeys {
                RewardAllUtil.instance.config = RewardAllConfig(from: extraKeys)
            }
            if let extraKeys = adConfig.adUnitsConfig.nativeAll.extraKeys {
                nativeAllConfig = NativeAllConfig(from: extraKeys)
            }
            print("✅ Ad config loaded")
        } catch {
            print("❌ Error decoding AdConfig: \(error)")
        }
    }

    private func decodeAppConfig() {
        let configString = remoteConfig.configValue(forKey: RemoteConfigType.appConfig.key).stringValue
        guard !configString.isEmpty else { return }
        guard let data = configString.data(using: .utf8) else {
            print("❌ Invalid app_configs string"); return
        }
        do {
            appConfig = try JSONDecoder().decode(AppConfig.self, from: data)
            print("✅ App config loaded: onlyShowLanguage=\(appConfig.onlyShowLanguage) appVersion=\(appConfig.appVersion) isInReview=\(appConfig.isInReview)")
        } catch {
            print("❌ Error decoding AppConfig: \(error)")
        }
    }

    private func activateDebugMode() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }

    var enableAllAds: Bool {
       
        return adConfig.showAllAds
    }

    // MARK: - Fetch
    func fetchAndActivate(completed: @escaping () -> ()) {
        activateDebugMode()
        remoteConfig.fetchAndActivate { [weak self] status, error in
            if let error = error {
                print("❌ Remote Config fetch error: \(error)")
            } else {
                print("✅ Remote Config fetched & activated (status: \(status))")
            }
            self?.getConfigValue()
            DispatchQueue.main.async { completed() }
        }
    }

    func fetchCloudValues(completed: @escaping () -> ()) {
        fetchAndActivate(completed: completed)
    }
}

#endif
