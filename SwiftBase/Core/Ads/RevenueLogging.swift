#if MONETIZATION_ENABLED
//
//  RevenueLogging.swift
//  AdmobSwitUI
//
//  Created by Đức Mạnh on 10/03/2026.
//

import Foundation
import GoogleMobileAds
import StoreKit
import AdjustSdk
import ads_swift
import FirebaseAnalytics

class AdRevenueLogger: AdRevenueDelegate, @unchecked Sendable {
    static let shared = AdRevenueLogger()

    private init() {
        AdRevenueTracker.shared.delegate = self
    }

    func didTrackAdRevenue(adValue: AdValue,
                           adUnit: String,
                           adType: AdType) {
        let amount = Double(truncating: adValue.value)
        AdjustManager.shared.logRevenue(name: "ad_revenue", value: amount)
        AdjustManager.shared.trackRevenue(adValue: adValue,
                                          adType: adType.rawValue)
    }
}

#endif
