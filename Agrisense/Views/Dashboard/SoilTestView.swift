import SwiftUI

struct SoilTestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var location = ""
    @State private var sampleID = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(localizationManager.localizedString(for: "soil_test_request"))) {
                    TextField(localizationManager.localizedString(for: "location"), text: $location)
                    TextField(localizationManager.localizedString(for: "sample_id"), text: $sampleID)
                }

                Section {
            Button(localizationManager.localizedString(for: "request_soil_test")) {
                        // Request soil test logic here
                        dismiss()
                    }
                }
            }
        .navigationTitle(localizationManager.localizedString(for: "soil_test"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
            Button(localizationManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SoilTestView()
}
