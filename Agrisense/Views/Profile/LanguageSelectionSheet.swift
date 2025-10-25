//
//  LanguageSelectionSheet.swift
//  Agrisense
//
//  Created by Athar Reza on 24/10/25.
//

import SwiftUI

struct LanguageOption: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let nativeName: String
}

struct LanguageSelectionSheet: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    // Available languages with native names
    let availableLanguages = [
        LanguageOption(code: "en", name: "English", nativeName: "English"),
        LanguageOption(code: "hi", name: "Hindi", nativeName: "हिन्दी"),
        LanguageOption(code: "bn", name: "Bengali", nativeName: "বাংলা"),
        LanguageOption(code: "te", name: "Telugu", nativeName: "తెలుగు"),
        LanguageOption(code: "ta", name: "Tamil", nativeName: "தமிழ்")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(availableLanguages) { language in
                        languageButton(for: language)
                    }
                } header: {
                    Text(localizationManager.localizedString(for: "select_language"))
                } footer: {
                    Text(localizationManager.localizedString(for: "language_change_info"))
                        .font(.caption)
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "language_settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString(for: "close")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func languageButton(for language: LanguageOption) -> some View {
        let isSelected = localizationManager.currentLanguageCode == language.code
        
        return Button {
            selectLanguage(language.code)
        } label: {
            HStack(spacing: 16) {
                Text(flagForLanguage(language.code))
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.nativeName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(.primary)
                    
                    Text(language.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func flagForLanguage(_ code: String) -> String {
        switch code {
        case "en":
            return "🇬🇧"
        case "hi", "bn", "te", "ta":
            return "🇮🇳"
        default:
            return "🌐"
        }
    }
    
    private func selectLanguage(_ code: String) {
        localizationManager.setLanguage(code: code)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

struct LanguageSelectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionSheet()
            .environmentObject(LocalizationManager.shared)
    }
}
