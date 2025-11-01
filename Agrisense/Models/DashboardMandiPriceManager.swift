//
//  DashboardMandiPriceManager.swift
//  Agrisense
//
//  Created for Dashboard Quick Stats
//

import Foundation
import Combine

/// Manager for displaying rotating commodity prices in the dashboard quick stats card
/// Uses MandiPriceService to fetch real market data from the API
@MainActor
class DashboardMandiPriceManager: ObservableObject {
    @Published var currentCommodityName: String = "Loading..."
    @Published var currentPrice: String = "₹0.00"
    @Published var isLoading: Bool = false
    
    private let mandiService: MandiPriceService
    private var timer: AnyCancellable?
    private var currentIndex: Int = 0
    private var selectedCommodities: [MandiCommodityPrice] = []
    
    init() {
        self.mandiService = MandiPriceService()
        
        // Initial load
        Task {
            await loadInitialData()
            startRotation()
        }
    }
    
    deinit {
        timer?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Refresh data from API
    func refresh() async {
        isLoading = true
        await mandiService.fetchMandiPrices(limit: 100)
        prepareSelectedCommodities()
        updateCurrentCommodity()
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        isLoading = true
        
        // Check if we need to fetch fresh data
        if mandiService.isCacheStale() {
            await mandiService.fetchMandiPrices(limit: 100)
        }
        
        prepareSelectedCommodities()
        updateCurrentCommodity()
        isLoading = false
    }
    
    private func prepareSelectedCommodities() {
        // Get unique commodities and select the best price for each
        let grouped = mandiService.getCommoditiesGrouped()
        
        // For each commodity, get the one with the highest modal price
        selectedCommodities = grouped.compactMap { (name, prices) -> MandiCommodityPrice? in
            prices.max(by: { $0.modalPrice < $1.modalPrice })
        }.sorted(by: { $0.commodity < $1.commodity })
        
        // If no commodities available, use sample data
        if selectedCommodities.isEmpty {
            selectedCommodities = MandiCommodityPrice.samples
        }
        
        #if DEBUG
        print("📊 Dashboard will rotate through \(selectedCommodities.count) commodities")
        #endif
    }
    
    private func startRotation() {
        // Rotate every 60 seconds
        timer = Timer.publish(every: 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.rotateToNextCommodity()
                }
            }
    }
    
    private func rotateToNextCommodity() {
        guard !selectedCommodities.isEmpty else { return }
        
        // Move to next commodity
        currentIndex = (currentIndex + 1) % selectedCommodities.count
        updateCurrentCommodity()
        
        #if DEBUG
        print("🔄 Rotated to: \(currentCommodityName) - \(currentPrice)")
        #endif
    }
    
    private func updateCurrentCommodity() {
        guard !selectedCommodities.isEmpty else {
            currentCommodityName = "No Data"
            currentPrice = "₹0.00"
            return
        }
        
        // Ensure index is within bounds
        if currentIndex >= selectedCommodities.count {
            currentIndex = 0
        }
        
        let commodity = selectedCommodities[currentIndex]
        currentCommodityName = commodity.commodity
        currentPrice = commodity.formattedModalPrice
    }
}
