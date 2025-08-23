import SwiftUI

struct MarketPricesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(LocalizationManager.shared.localizedString(for: "crop_prices"))) {
                    Text(LocalizationManager.shared.localizedString(for: "wheat_price"))
                    Text(LocalizationManager.shared.localizedString(for: "corn_price"))
                    Text(LocalizationManager.shared.localizedString(for: "soybeans_price"))
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString(for: "market_prices"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizationManager.shared.localizedString(for: "done")) {
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
