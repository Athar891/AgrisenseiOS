import SwiftUI

struct SoilTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var location = ""
    @State private var sampleID = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizationManager.shared.localizedString(for: "soil_test_request"))) {
                    TextField(LocalizationManager.shared.localizedString(for: "location"), text: $location)
                    TextField(LocalizationManager.shared.localizedString(for: "sample_id"), text: $sampleID)
                }

                Section {
            Button(LocalizationManager.shared.localizedString(for: "request_soil_test")) {
                        // Request soil test logic here
                        dismiss()
                    }
                }
            }
        .navigationTitle(LocalizationManager.shared.localizedString(for: "soil_test"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
            Button(LocalizationManager.shared.localizedString(for: "cancel")) {
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
