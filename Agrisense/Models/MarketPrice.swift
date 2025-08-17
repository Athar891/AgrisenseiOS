import Foundation

// MARK: - CropPrice Model
struct CropPrice: Codable, Identifiable {
    var id = UUID()
    let name: String
    let unit: String // "per quintal" or "per kg"
    let basePrice: Double // Base price for realistic fluctuations
    let minPrice: Double
    let maxPrice: Double
    var currentPrice: Double
    var lastUpdated: Date
    
    init(name: String, unit: String, basePrice: Double, priceRange: Double) {
        self.name = name
        self.unit = unit
        self.basePrice = basePrice
        self.minPrice = basePrice - priceRange
        self.maxPrice = basePrice + priceRange
        self.currentPrice = basePrice
        self.lastUpdated = Date()
    }
    
    var formattedPrice: String {
        return CurrencyFormatter.format(price: currentPrice)
    }
    
    var displayText: String {
        return "\(name): \(formattedPrice) \(unit)"
    }
    
    // Generate a realistic price fluctuation
    mutating func updatePrice() {
        // Generate a random fluctuation between -5% to +5%
        let fluctuationPercentage = Double.random(in: -0.05...0.05)
        let newPrice = currentPrice * (1 + fluctuationPercentage)
        
        // Ensure price stays within realistic bounds
        currentPrice = max(minPrice, min(maxPrice, newPrice))
        lastUpdated = Date()
    }
}

// MARK: - Sample Indian Market Crops
extension CropPrice {
    static let sampleCrops: [CropPrice] = [
        CropPrice(name: "Wheat", unit: "per quintal", basePrice: 2250, priceRange: 250),
        CropPrice(name: "Rice", unit: "per quintal", basePrice: 2000, priceRange: 200),
        CropPrice(name: "Corn", unit: "per quintal", basePrice: 1800, priceRange: 200),
        CropPrice(name: "Soybeans", unit: "per quintal", basePrice: 4500, priceRange: 500),
        CropPrice(name: "Cotton", unit: "per quintal", basePrice: 6000, priceRange: 500),
        CropPrice(name: "Sugarcane", unit: "per quintal", basePrice: 315, priceRange: 35),
        CropPrice(name: "Onion", unit: "per kg", basePrice: 20, priceRange: 5),
        CropPrice(name: "Tomato", unit: "per kg", basePrice: 28, priceRange: 8)
    ]
}
