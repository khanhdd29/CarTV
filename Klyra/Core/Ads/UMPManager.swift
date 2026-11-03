#if MONETIZATION_ENABLED
//
//  UMPManager.swift
//  Guru cleaner
//
//  Created by Đức Mạnh on 10/03/2026.
//

import Foundation
import UserMessagingPlatform
import FirebaseAnalytics
import SwiftUI

final class UMPManager {
    static let shared = UMPManager()

    private init() {}

    @MainActor
    func requestConsentIfNeeded() async {
        do {
            let parameters = RequestParameters()
            parameters.isTaggedForUnderAgeOfConsent = false

            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)

            let status = ConsentInformation.shared.consentStatus
            let formAvailable = ConsentInformation.shared.formStatus == .available

            if formAvailable && (status == .required || status == .unknown) {
                let form = try await loadConsentForm()
                try await presentForm(form)
            }

        } catch {
            print("UMP consent update failed: \(error.localizedDescription)")
        }
    }

    private func loadConsentForm() async throws -> ConsentForm {
        return try await withCheckedThrowingContinuation { continuation in
            ConsentForm.load { form, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let form = form {
                    continuation.resume(returning: form)
                } else {
                    continuation.resume(throwing: NSError(domain: "UMP", code: 999, userInfo: [NSLocalizedDescriptionKey: "Form not available"]))
                }
            }
        }
    }

    @MainActor
    private func presentForm(_ form: ConsentForm) async throws {
        let rootVC = try await getRootViewController()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            form.present(from: rootVC) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }

                let status = ConsentInformation.shared.consentStatus
                if status == .obtained {
                    Analytics.logEvent("user_consent", parameters: [:])
                    print("✅ User completed consent (likely tapped Continue)")
                } else {
                    Analytics.logEvent("user_not_consent", parameters: [:])
                    print("❌ User dismissed or did not complete")
                }
            }
        }
    }

    @MainActor
    private func getRootViewController() async throws -> UIViewController {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            throw NSError(domain: "UMP", code: 998, userInfo: [NSLocalizedDescriptionKey: "No root view controller found"])
        }
        return rootVC
    }
}

#endif
