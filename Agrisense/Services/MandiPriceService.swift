import Foundation
import Combine

// MARK: - Mandi Price Service
@MainActor
class MandiPriceService: ObservableObject {
    @Published var commodities: [MandiCommodityPrice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    
    private let apiKey: String
    private let baseURL = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    private var cancellables = Set<AnyCancellable>()
    
    init(apiKey: String = Secrets.mandiAPIKey) {
        self.apiKey = apiKey
        // Load cached data first
        loadCachedData()
    }
    
    // MARK: - Public Methods
    
    /// Fetch latest mandi prices from the API
    func fetchMandiPrices(limit: Int = 50) async {
        isLoading = true
        errorMessage = nil
        
        // Build URL with parameters
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "api-key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components?.url else {
            errorMessage = "Invalid API URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response from server"
                isLoading = false
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                errorMessage = "Server error: \(httpResponse.statusCode)"
                isLoading = false
                return
            }
            
            // Parse the response
            let apiResponse = try JSONDecoder().decode(MandiAPIResponse.self, from: data)
            
            // Convert to our model and filter out invalid entries
            let validCommodities = apiResponse.records.compactMap { $0.toMandiCommodityPrice() }
            
            if validCommodities.isEmpty {
                errorMessage = "No valid price data available"
                // Use sample data as fallback
                commodities = MandiCommodityPrice.samples
            } else {
                commodities = validCommodities
                // Cache the data
                cacheData(validCommodities)
            }
            
            lastUpdated = Date()
            isLoading = false
            
            #if DEBUG
            print("✅ Fetched \(validCommodities.count) mandi prices")
            #endif
            
        } catch {
            errorMessage = "Failed to fetch prices: \(error.localizedDescription)"
            isLoading = false
            
            #if DEBUG
            print("❌ Mandi API Error: \(error)")
            #endif
            
            // Load sample data as fallback
            if commodities.isEmpty {
                commodities = MandiCommodityPrice.samples
            }
        }
    }
    
    /// Get commodities grouped by commodity name
    func getCommoditiesGrouped() -> [String: [MandiCommodityPrice]] {
        Dictionary(grouping: commodities, by: { $0.commodity })
    }
    
    /// Get unique commodity names
    func getUniqueCommodities() -> [String] {
        Array(Set(commodities.map { $0.commodity })).sorted()
    }
    
    /// Filter commodities by name
    func filterCommodities(by name: String) -> [MandiCommodityPrice] {
        commodities.filter { $0.commodity.lowercased().contains(name.lowercased()) }
    }
    
    /// Search commodities by state, district, or market
    func searchCommodities(query: String) -> [MandiCommodityPrice] {
        let lowercasedQuery = query.lowercased()
        return commodities.filter {
            $0.commodity.lowercased().contains(lowercasedQuery) ||
            $0.state.lowercased().contains(lowercasedQuery) ||
            $0.district.lowercased().contains(lowercasedQuery) ||
            $0.market.lowercased().contains(lowercasedQuery)
        }
    }
    
    // MARK: - Caching
    
    private func cacheData(_ commodities: [MandiCommodityPrice]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(commodities)
            UserDefaults.standard.set(data, forKey: "cached_mandi_prices")
            UserDefaults.standard.set(Date(), forKey: "cached_mandi_prices_date")
        } catch {
            #if DEBUG
            print("⚠️ Failed to cache mandi prices: \(error)")
            #endif
        }
    }
    
    private func loadCachedData() {
        guard let data = UserDefaults.standard.data(forKey: "cached_mandi_prices") else {
            // No cached data, load samples
            commodities = MandiCommodityPrice.samples
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let cached = try decoder.decode([MandiCommodityPrice].self, from: data)
            commodities = cached
            
            if let cacheDate = UserDefaults.standard.object(forKey: "cached_mandi_prices_date") as? Date {
                lastUpdated = cacheDate
            }
            
            #if DEBUG
            print("📦 Loaded \(cached.count) cached mandi prices")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to load cached prices: \(error)")
            #endif
            // Fallback to samples
            commodities = MandiCommodityPrice.samples
        }
    }
    
    /// Check if cached data is stale (older than 24 hours)
    func isCacheStale() -> Bool {
        guard let lastUpdated = lastUpdated else { return true }
        let hoursSinceUpdate = Date().timeIntervalSince(lastUpdated) / 3600
        return hoursSinceUpdate > 24
    }
}
