import Foundation

/// Stable `rawValue` strings for Firebase Analytics `screen_view`.
/// IMPORTANT: rawValue đã release → KHÔNG đổi (dashboard/BigQuery phụ thuộc).
///
/// Các màn của SwiftBase. Thêm case khi thêm màn mới.
enum AnalyticsScreen: String {
    // Onboarding
    case splash
    case language                                  // first-launch language picker
    case intro

    // Main tabs
    case home                                      // Channels list
    case search
    case favorites
    case recents
    case settings

    // IPTV screens
    case addPlaylist = "add_playlist"
    case managePlaylists = "manage_playlists"
    case guide
    case player

    // Detail / nested
    case homeDetail = "home_detail"
    case settingsLanguage = "settings_language"    // language sheet opened from Settings
}
