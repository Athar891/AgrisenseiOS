import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showingLanguageSheet = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(localizationManager.localizedString(for: "preferences"))) {
                    // Language selection row
                    Button(action: { showingLanguageSheet = true }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text(localizationManager.localizedString(for: "language_settings"))
                                Text(localizationManager.localizedString(for: "select_indian_language"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }

                    // Dark mode toggle
                    HStack {
                        Image(systemName: appState.isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(appState.isDarkMode ? .purple : .orange)

                        Text(localizationManager.localizedString(for: "dark_mode"))
                            .font(.subheadline)

                        Spacer()

                        Toggle("", isOn: $appState.isDarkMode)
                            .labelsHidden()
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "settings"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString(for: "close")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingLanguageSheet) {
                LanguageSelectionSheet()
                    .environmentObject(localizationManager)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
            SettingsView()
                .environmentObject(LocalizationManager.shared)
                .environmentObject(AppState())
    }
}
