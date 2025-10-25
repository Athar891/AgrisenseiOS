import SwiftUI

struct MarketPricesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var mandiService = MandiPriceService()
    @State private var searchText = ""
    @State private var selectedCommodity: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                if mandiService.isLoading && mandiService.commodities.isEmpty {
                    ProgressView("Loading market prices...")
                        .padding()
                } else {
                    mainContent
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "market_prices"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString(for: "done")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await mandiService.fetchMandiPrices()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(mandiService.isLoading)
                }
            }
            .searchable(text: $searchText, prompt: "Search commodity, state, or market")
            .onAppear {
                // Fetch fresh data if cache is stale
                if mandiService.isCacheStale() {
                    Task {
                        await mandiService.fetchMandiPrices()
                    }
                }
            }
        }
    }
    
    private var mainContent: some View {
        List {
            // Last updated section
            if let lastUpdated = mandiService.lastUpdated {
                Section {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Last updated: \(lastUpdated, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Error message if any
            if let errorMessage = mandiService.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Commodity list
            let filteredCommodities = searchText.isEmpty ? 
                mandiService.commodities : 
                mandiService.searchCommodities(query: searchText)
            
            let groupedCommodities = Dictionary(grouping: filteredCommodities, by: { $0.commodity })
            
            ForEach(groupedCommodities.keys.sorted(), id: \.self) { commodity in
                Section(header: commodityHeader(commodity)) {
                    ForEach(groupedCommodities[commodity] ?? []) { price in
                        CommodityPriceRow(price: price)
                    }
                }
            }
            
            if filteredCommodities.isEmpty {
                Section {
                    Text("No market prices found")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .refreshable {
            await mandiService.fetchMandiPrices()
        }
    }
    
    private func commodityHeader(_ commodity: String) -> some View {
        HStack {
            Text(commodity)
                .font(.headline)
            Spacer()
            let count = mandiService.filterCommodities(by: commodity).count
            if count > 1 {
                Text("\(count) markets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Commodity Price Row
struct CommodityPriceRow: View {
    let price: MandiCommodityPrice
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(price.market)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(price.district), \(price.state)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price.formattedModalPrice)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(price.unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Expandable details
            if isExpanded {
                Divider()
                
                HStack(spacing: 16) {
                    PriceDetail(label: "Min", value: price.formattedMinPrice, color: .blue)
                    PriceDetail(label: "Modal", value: price.formattedModalPrice, color: .green)
                    PriceDetail(label: "Max", value: price.formattedMaxPrice, color: .orange)
                }
                .padding(.vertical, 4)
                
                if let arrivalDate = price.arrivalDate {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Arrival: \(arrivalDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Price Detail Component
struct PriceDetail: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    MarketPricesView()
        .environmentObject(LocalizationManager.shared)
}
