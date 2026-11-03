//
//  AppLanguage.swift
//  SwiftBase
//
//  16 languages, matching the reference app's set (Arabic left out — RTL needs
//  dedicated layout work). Flags are PNG assets in Assets.xcassets › Flags.
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case vietnamese = "vi"
    case french = "fr"
    case brazilianPortuguese = "pt-BR"
    case spanish = "es"
    case hindi = "hi"
    case indonesian = "id"
    case korean = "ko"
    case japanese = "ja"
    case russian = "ru"
    case german = "de"
    case portuguese = "pt-PT"
    case bengali = "bn"
    case turkish = "tr"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    /// Name shown in the language's own script.
    var displayName: String {
        switch self {
        case .english:             return "English"
        case .vietnamese:          return "Tiếng Việt"
        case .french:              return "Français"
        case .brazilianPortuguese: return "Português (Brasil)"
        case .spanish:             return "Español"
        case .hindi:               return "हिन्दी"
        case .indonesian:          return "Bahasa Indonesia"
        case .korean:              return "한국어"
        case .japanese:            return "日本語"
        case .russian:             return "Русский"
        case .german:              return "Deutsch"
        case .portuguese:          return "Português"
        case .bengali:             return "বাংলা"
        case .turkish:             return "Türkçe"
        case .simplifiedChinese:   return "简体中文"
        case .traditionalChinese:  return "繁體中文"
        }
    }

    /// Image-set name in Assets › Flags (both Chinese variants share one flag).
    var flagImage: String {
        switch self {
        case .simplifiedChinese, .traditionalChinese: return "Flag-zh"
        default: return "Flag-\(rawValue)"
        }
    }

    var flagImageView: Image { Image(flagImage) }

    /// Best match for the device's current language, falling back to English.
    static var deviceDefault: AppLanguage {
        for locale in Locale.preferredLanguages.map({ Locale(identifier: $0) }) {
            guard let code = locale.language.languageCode?.identifier else { continue }
            switch code {
            case "pt":
                // Prefer region when available (pt-BR vs pt-PT).
                return locale.region?.identifier == "BR" ? .brazilianPortuguese : .portuguese
            case "zh":
                let script = locale.language.script?.identifier
                return script == "Hant" ? .traditionalChinese : .simplifiedChinese
            default:
                if let match = AppLanguage(rawValue: code) { return match }
            }
        }
        return .english
    }
}
