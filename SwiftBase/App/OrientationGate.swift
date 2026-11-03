//
//  OrientationGate.swift
//  SwiftBase
//
//  The app is portrait-locked everywhere EXCEPT the player, which may rotate to
//  landscape for full-screen video. `AppDelegate` reads `mask` to decide the
//  allowed orientations; the player flips it on appear / disappear.
//

import UIKit

enum OrientationGate {
    /// Current allowed orientations (read by AppDelegate).
    static var mask: UIInterfaceOrientationMask = .portrait

    /// Allow landscape (player). Doesn't force a rotation — the user rotates.
    @MainActor static func allowAll() {
        mask = .allButUpsideDown
        refresh()
    }

    /// Lock back to portrait and rotate there (leaving the player).
    @MainActor static func lockPortrait() {
        mask = .portrait
        activeScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        refresh()
    }

    @MainActor private static func refresh() {
        activeScene?.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    private static var activeScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
}
