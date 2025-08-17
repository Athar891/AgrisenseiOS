import SwiftUI

struct SoilTestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var location = ""
    @State private var sampleID = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Soil Test Request")) {
                    TextField("Location", text: $location)
                    TextField("Sample ID", text: $sampleID)
                }

                Section {
                    Button("Request Soil Test") {
                        // Request soil test logic here
                        dismiss()
                    }
                }
            }
            .navigationTitle("Soil Test")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
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
