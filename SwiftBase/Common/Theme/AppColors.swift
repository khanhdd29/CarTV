//
//  AppColors.swift
//  SwiftBase
//
//  ─────────────────────────────────────────────────────────────
//  KLYRA COLOR SYSTEM — cinematic, dark-first. Single source of truth.
//
//  The app runs dark-first (a TV/IPTV player should let the video own the
//  screen). Values are fixed hex (not system dynamic) so the look is consistent.
//  Change here and the whole app follows.
//  ─────────────────────────────────────────────────────────────

import SwiftUI

enum AppColors {
    // MARK: Brand
    /// Primary brand (electric blue).
    static let primary = Color(hex: 0x5B8DEF)
    /// Secondary accent (cyan) — highlights, live-adjacent chips, glows.
    static let secondary = Color(hex: 0x22D3EE)
    /// Violet used at the far end of brand gradients.
    static let violet = Color(hex: 0x8B5CF6)
    static let onPrimary = Color.white
    static let primarySoft = Color(hex: 0x5B8DEF, opacity: 0.16)

    // MARK: Surfaces (fixed dark)
    /// App background (near-black with a cool tint).
    static let background = Color(hex: 0x0A0C12)
    /// Slightly lifted backdrop behind rails/sections.
    static let backgroundRaised = Color(hex: 0x10131C)
    /// Cards, tiles, fields.
    static let surface = Color(hex: 0x161A24)
    /// Elevated card / popover.
    static let surfaceElevated = Color(hex: 0x1E2330)
    /// Hairline borders.
    static let border = Color.white.opacity(0.08)
    static let borderStrong = Color.white.opacity(0.14)

    // MARK: Text (on dark)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)

    // MARK: States
    static let favorite = Color(hex: 0xFF4D6D)
    static let live = Color(hex: 0xFF3B5C)
    static let destructive = Color(hex: 0xFF4D6D)
    static let success = Color(hex: 0x34D399)

    // MARK: Player
    static let playerBackground = Color.black
    static let playerForeground = Color.white
    static let playerScrim = Color.black.opacity(0.45)
    static let playerControlBackground = Color.white.opacity(0.14)

    // MARK: Gradients
    /// Primary CTA / hero accent gradient (blue → violet).
    static let brandGradient = LinearGradient(
        colors: [Color(hex: 0x5B8DEF), Color(hex: 0x8B5CF6)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    /// Cyan → blue, for secondary accents and glows.
    static let coolGradient = LinearGradient(
        colors: [Color(hex: 0x22D3EE), Color(hex: 0x5B8DEF)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    /// Subtle top-to-bottom app background wash.
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: 0x12151F), Color(hex: 0x0A0C12)],
        startPoint: .top, endPoint: .bottom
    )
    /// Dark scrim laid over hero artwork so text stays readable.
    static let heroScrim = LinearGradient(
        colors: [.clear, Color(hex: 0x0A0C12, opacity: 0.2), Color(hex: 0x0A0C12, opacity: 0.95)],
        startPoint: .top, endPoint: .bottom
    )
}

extension Color {
    /// `Color(hex: 0x5B8DEF)`
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
