#if MONETIZATION_ENABLED
//
//  AdjustManager.swift
//  AdmobSwitUI
//
//  Created by Đức Mạnh on 10/03/2026.
//

import Foundation
import AdjustSdk
import GoogleMobileAds
import FirebaseAnalytics

class AdjustManager {
    static let shared = AdjustManager()
    
    private init() {}
    
    func initialize() {
        let appToken = "ahsk06riepz4"
#if DEBUG
        let adjustConfig = ADJConfig(appToken: appToken, environment: ADJEnvironmentSandbox)
        adjustConfig?.logLevel = .verbose
#else
        let adjustConfig = ADJConfig(appToken: appToken, environment: ADJEnvironmentProduction)
        adjustConfig?.logLevel = .suppress
#endif
        Adjust.initSdk(adjustConfig)
    }
    
    // Track event
    func trackEvent(eventToken: String, parameters: [String: Any]? = nil) {
        let event = ADJEvent(eventToken: eventToken)
        if let params = parameters {
            for (key, value) in params {
                if let stringValue = value as? String {
                    event?.addPartnerParameter(key, value: stringValue)
                }
            }
        }
        Adjust.trackEvent(event)
    }

    // Track revenue
    func trackRevenue(adValue: AdValue, adType: String) {
        let valueMicros = Double(truncating: adValue.value)
        let currency = adValue.currencyCode
        let revenueUSD = valueMicros
        print("[AdRevenue] \(adType) - \(revenueUSD) \(currency)")
        let adjustAdRevenue = ADJAdRevenue(source: "admob_sdk")
        adjustAdRevenue?.setRevenue(revenueUSD, currency: currency)
        adjustAdRevenue?.setAdImpressionsCount(1)
        adjustAdRevenue?.setAdRevenueNetwork("AdMob")
        adjustAdRevenue?.setAdRevenueUnit(adType)
        adjustAdRevenue?.setAdRevenuePlacement("default")
        if let adjustAdRevenue = adjustAdRevenue {
            Adjust.trackAdRevenue(adjustAdRevenue)
        }
        let revenueEventToken = "oeoskt"
        guard !revenueEventToken.isEmpty, revenueEventToken != "YOUR_REVENUE_EVENT_TOKEN" else {
            print("[AdjustManager] ⚠️ Revenue event token not configured, skipping event track")
            return
        }
        let event = ADJEvent(eventToken: revenueEventToken)
        event?.setRevenue(revenueUSD, currency: currency)
        Adjust.trackEvent(event)
    }

 func logRevenue(name: String, value: Double) {
         let safeRevenue = Double(String(format: "%.6f", value)) ?? 0.0
         Analytics.logEvent(name, parameters: [
             AnalyticsParameterAdPlatform: "AdMob",
             AnalyticsParameterCurrency: "USD",
             AnalyticsParameterValue: safeRevenue
         ])
     }
}

#endif
