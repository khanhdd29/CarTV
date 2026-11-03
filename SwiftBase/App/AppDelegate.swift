//
//  AppDelegate.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//
//  Firebase configure is preserved but gated behind `MONETIZATION_ENABLED`
//  (undefined in v1). v1 is local-only, so nothing is initialized here.
//

import UIKit
#if MONETIZATION_ENABLED
import FirebaseCore
#endif

final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Launch

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if MONETIZATION_ENABLED
        configureFirebase()
        // Ad SDKs (MobileAds, Facebook, Adjust) are wired from SplashView.
        #endif
        return true
    }

    #if MONETIZATION_ENABLED
    // MARK: - Firebase

    /// Configure Firebase from the per-target plist: `GoogleService-Info-dev.plist`
    /// for the dev target (`DEV` flag), `GoogleService-Info.plist` for prod.
    private func configureFirebase() {
        guard FirebaseApp.app() == nil else { return }
        #if DEV
        let resource = "GoogleService-Info-dev"
        #else
        let resource = "GoogleService-Info"
        #endif
        if let path = Bundle.main.path(forResource: resource, ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: path) {
            FirebaseApp.configure(options: options)
        } else {
            FirebaseApp.configure()
        }
    }
    #endif

    // MARK: - Orientation

    /// Portrait everywhere except the player (which allows landscape).
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationGate.mask
    }

    // MARK: - Scene configuration

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    }

    // MARK: - Remote notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        #if DEBUG
        print("[AppDelegate] APNs device token: \(token)")
        #endif
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("[AppDelegate] Failed to register for remote notifications: \(error)")
        #endif
    }
}
