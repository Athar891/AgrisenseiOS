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
            currentLocale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code]))
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
        bundle.localizedString(forKey: key, value: nil, table: nil)
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
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"), let b = Bundle(path: path) {
            bundle = b
        } else {
            bundle = .main
        }
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
