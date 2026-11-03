//
//  AppPhase.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import Foundation

enum AppPhase: Equatable {
    /// Branded loading screen shown on every launch.
    case splash
    /// First-launch language picker.
    case language
    /// First-launch 3-page onboarding carousel.
    case intro
    /// The main app: a 4-tab `TabView`, one `Navigation` per tab.
    case home
}
