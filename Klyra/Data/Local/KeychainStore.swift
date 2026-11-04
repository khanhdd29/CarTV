//
//  KeychainStore.swift
//  SwiftBase
//
//  Thin Keychain wrapper for secrets (Xtream credentials). Per spec §6: server
//  credentials go to the Keychain — never plaintext, never to the cloud/Analytics.
//

import Foundation
import Security

enum KeychainStore {
    @discardableResult
    static func set(_ value: String, for key: String) -> Bool {
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(base as CFDictionary)
        var attrs = base
        attrs[kSecValueData as String] = Data(value.utf8)
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(attrs as CFDictionary, nil) == errSecSuccess
    }

    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Remove every generic-password item the app owns.
    static func deleteAll() {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword] as CFDictionary)
    }

    /// The Keychain survives deleting the app, so a reinstall can inherit an old
    /// parental PIN (and stale Xtream logins). On the first launch after an
    /// install — detected via a UserDefaults flag, which *is* cleared when the app
    /// is deleted — wipe the app's Keychain once so a fresh install starts clean.
    static func wipeIfFreshInstall() {
        let flag = "klyra.freshInstallKeychainWiped"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        deleteAll()
        UserDefaults.standard.set(true, forKey: flag)
    }
}
