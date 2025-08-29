import SwiftUI

struct MarketPricesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(localizationManager.localizedString(for: "crop_prices"))) {
                    Text(localizationManager.localizedString(for: "wheat_price"))
                    Text(localizationManager.localizedString(for: "corn_price"))
                    Text(localizationManager.localizedString(for: "soybeans_price"))
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "market_prices"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString(for: "done")) {
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
