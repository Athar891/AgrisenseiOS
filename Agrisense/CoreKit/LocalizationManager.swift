import Foundation
import Combine

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()

    @Published public private(set) var currentLocale: Locale
    @Published public private(set) var currentLanguageCode: String?

    private let userDefaultsKey = "selectedLanguageCode"
    private var bundle: Bundle = .main

    private init() {
        if let code = UserDefaults.standard.string(forKey: userDefaultsKey) {
            currentLanguageCode = code
            // Use the language identifier directly (e.g. "bn", "hi").
            // Previous code used the countryCode key which produced invalid locale identifiers
            // and could prevent the correct .lproj bundle from being loaded.
            currentLocale = Locale(identifier: code)
            updateBundle(for: code)
        } else {
            currentLanguageCode = nil
            currentLocale = Locale.current
        }
    }

    public func availableLanguages() -> [(code: String, name: String, nativeName: String)] {
        // code, english name, native script name
        return [
            ("en", "English", "English"),
            ("hi", "Hindi", "हिन्दी"),
            ("bn", "Bengali", "বাংলা"),
            ("ta", "Tamil", "தமிழ்"),
            ("te", "Telugu", "తెలుగు")
        ]
    }

    public func localizedString(for key: String) -> String {
        // Prefer explicitly using the Localizable.strings table and fall back to main bundle
        // if the lookup fails. This prevents returning the raw key when a translation exists
        // in the app bundle but the selected language bundle wasn't resolved correctly.
        let localized = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
        if localized == key {
            // try main bundle as fallback
            let mainLocalized = Bundle.main.localizedString(forKey: key, value: nil, table: "Localizable")
            return mainLocalized
        }
        return localized
    }

    // Formatter helpers
    public func dateFormatter(style: DateFormatter.Style = .medium) -> DateFormatter {
        let fmt = DateFormatter()
        fmt.dateStyle = style
        fmt.locale = Locale(identifier: currentLanguageCode ?? Locale.current.identifier)
        return fmt
    }

    public func numberFormatter() -> NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: currentLanguageCode ?? Locale.current.identifier)
        return nf
    }

    public func setLanguage(code: String?) {
        if let code = code {
            UserDefaults.standard.set(code, forKey: userDefaultsKey)
            currentLanguageCode = code
            updateBundle(for: code)
            currentLocale = Locale(identifier: code)
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            currentLanguageCode = nil
            currentLocale = Locale.current
            bundle = .main
        }
        
        // Notify SwiftUI views to update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
        
        // Post notification for dynamic UI update
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }

    private func updateBundle(for code: String) {
        // Try exact code (e.g. "bn"), then try language component (e.g. from "bn-IN" -> "bn")
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"), let b = Bundle(path: path) {
            bundle = b
            return
        }

        let langComponent = code.split(separator: "-").first.map(String.init) ?? code
        if let path = Bundle.main.path(forResource: langComponent, ofType: "lproj"), let b = Bundle(path: path) {
            bundle = b
            return
        }

        // final fallback
        bundle = .main
    }
}

public extension Notification.Name {
    static let languageChanged = Notification.Name("LocalizationManagerLanguageChanged")
}

// MARK: - SwiftUI Extensions
import SwiftUI

public extension View {
    /// Returns a localized string that updates when the language changes
    func localizedString(for key: String, localizationManager: LocalizationManager = LocalizationManager.shared) -> String {
        return localizationManager.localizedString(for: key)
    }
}

/// A SwiftUI Text view that automatically updates when the language changes
public struct LocalizedText: View {
    @ObservedObject private var localizationManager: LocalizationManager
    private let key: String
    
    public init(_ key: String, localizationManager: LocalizationManager = LocalizationManager.shared) {
        self.key = key
        self.localizationManager = localizationManager
    }
    
    public var body: some View {
        Text(localizationManager.localizedString(for: key))
    }
}
