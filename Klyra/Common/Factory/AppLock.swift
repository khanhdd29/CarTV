//
//  AppLock.swift
//  SwiftBase
//
//  Parental PIN lock. A 4-digit PIN (stored in the Keychain, never plaintext)
//  gates the app on launch and when returning from the background. Local-only.
//

import Foundation

@MainActor
final class AppLock: ObservableObject {
    private let key = "parental.pin"

    /// A PIN has been set.
    @Published private(set) var isEnabled = false
    /// The lock screen should be shown right now.
    @Published var isLocked = false

    init() {
        let hasPIN = KeychainStore.get(key) != nil
        isEnabled = hasPIN
        isLocked = hasPIN
    }

    func setPIN(_ pin: String) {
        KeychainStore.set(pin, for: key)
        isEnabled = true
        isLocked = false
    }

    func verify(_ pin: String) -> Bool { KeychainStore.get(key) == pin }

    @discardableResult
    func unlock(_ pin: String) -> Bool {
        guard verify(pin) else { return false }
        isLocked = false
        return true
    }

    @discardableResult
    func disable(withPIN pin: String) -> Bool {
        guard verify(pin) else { return false }
        KeychainStore.delete(key)
        isEnabled = false
        isLocked = false
        return true
    }

    /// Re-lock when the app goes to the background (if a PIN is set).
    func lockIfEnabled() { if isEnabled { isLocked = true } }
}
