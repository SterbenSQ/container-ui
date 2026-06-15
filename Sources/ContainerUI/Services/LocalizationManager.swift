import Foundation
import SwiftUI

// MARK: - Language Definition

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }

    var nativeDisplayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }

    var jsonFileName: String {
        switch self {
        case .english: return "en"
        case .chinese: return "zh"
        }
    }
}

// MARK: - LocalizationManager

/// Observable localization manager that loads string dictionaries from JSON files.
/// Inject as `@EnvironmentObject` in SwiftUI views for reactive language switching.
class LocalizationManager: ObservableObject, @unchecked Sendable {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            loadStrings(for: currentLanguage)
        }
    }

    private var strings: [String: String] = [:]

    private init() {
        // Restore saved language or detect from system
        let saved = UserDefaults.standard.string(forKey: "app_language")
        if let saved = saved, let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Auto-detect from system preference
            let preferredLang = Locale.preferredLanguages.first ?? "en"
            if preferredLang.hasPrefix("zh") {
                self.currentLanguage = .chinese
            } else {
                self.currentLanguage = .english
            }
        }
        loadStrings(for: currentLanguage)
    }

    private func loadStrings(for language: AppLanguage) {
        let fileName = language.jsonFileName
        // Try flat path first (SwiftPM flattens Resources subdirectories),
        // then try structured path with "localization/" prefix (for Xcode builds)
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "json")
                   ?? Bundle.module.url(forResource: "localization/\(fileName)", withExtension: "json")
                   ?? Bundle.main.url(forResource: fileName, withExtension: "json")
                   ?? Bundle.main.url(forResource: "localization/\(fileName)", withExtension: "json") else {
            print("[Localization] Failed to find localization file for \(language.rawValue)")
            strings = [:]
            return
        }
        do {
            let data = try Data(contentsOf: url)
            guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
                print("[Localization] Invalid JSON format")
                strings = [:]
                return
            }
            strings = dict
            print("[Localization] Loaded \(dict.count) strings for \(language.rawValue)")
        } catch {
            print("[Localization] Failed to load: \(error)")
            strings = [:]
        }
    }

    /// Get localized string for a key.
    /// Falls back to the key itself if translation is not found.
    subscript(_ key: String) -> String {
        strings[key] ?? key
    }

    /// Get localized string with parameter substitution.
    /// Use `{paramName}` placeholders in the translation.
    func format(_ key: String, _ args: [String: String]) -> String {
        var result = strings[key] ?? key
        for (k, v) in args {
            result = result.replacingOccurrences(of: "{\(k)}", with: v)
        }
        return result
    }
}

// MARK: - Convenience Accessor

/// Shorthand to get localized string from the shared manager.
/// Safe to call from any context (does not require @MainActor).
/// Note: This does NOT trigger SwiftUI view updates on language change.
/// Use `@EnvironmentObject` in views for reactive updates.
func tr(_ key: String) -> String {
    LocalizationManager.shared[key]
}

func tr(_ key: String, _ args: [String: String]) -> String {
    LocalizationManager.shared.format(key, args)
}
