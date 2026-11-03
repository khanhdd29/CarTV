import Foundation
import SwiftUI
#if MONETIZATION_ENABLED
import FirebaseAnalytics
#endif

// MARK: - Log screen_view (callable outside SwiftUI)
//
// Firebase Analytics is preserved but gated behind `MONETIZATION_ENABLED`. In
// v1 (flag off) this logs to the console in DEBUG only. Call sites
// (`.trackScreen(...)`) never change.

enum AnalyticsTracker {
    static func logScreenView(_ screen: AnalyticsScreen) {
        let name = sanitizeScreenName(screen.rawValue)
        #if DEBUG
        print("[Analytics] screen_view: \(name)")
        #endif
        #if MONETIZATION_ENABLED
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: name
        ])
        #endif
    }

    /// Cắt phần generic Swift type name (`UIHostingController<...>`) và giới hạn
    /// 100 ký tự theo quy định của Firebase `screen_name`.
    static func sanitizeScreenName(_ name: String) -> String {
        var cleaned = name
        if let start = cleaned.firstIndex(of: "<") {
            cleaned = String(cleaned[..<start])
        }
        if cleaned.count > 100 {
            cleaned = String(cleaned.prefix(100))
        }
        return cleaned
    }
}

// MARK: - ViewModifier

struct ScreenTrackingModifier: ViewModifier {
    let screen: AnalyticsScreen

    func body(content: Content) -> some View {
        content
            .onAppear {
                AnalyticsTracker.logScreenView(screen)
            }
    }
}

// MARK: - View extension

extension View {
    func trackScreen(_ screen: AnalyticsScreen) -> some View {
        modifier(ScreenTrackingModifier(screen: screen))
    }
}
