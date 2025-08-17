import SwiftUI

struct MarketPricesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Crop Prices")) {
                    Text("Wheat: ₹2,000 / quintal")
                    Text("Corn: ₹1,800 / quintal")
                    Text("Soybeans: ₹4,500 / quintal")
                }
            }
            .navigationTitle("Market Prices")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MarketPricesView()
}
