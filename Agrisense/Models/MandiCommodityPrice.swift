import Foundation

// MARK: - Mandi Commodity Price Models
struct MandiCommodityPrice: Codable, Identifiable {
    let id = UUID()
    let commodity: String
    let state: String
    let district: String
    let market: String
    let minPrice: Double
    let maxPrice: Double
    let modalPrice: Double
    let unit: String
    let arrivalDate: String?
    
    var formattedMinPrice: String {
        return CurrencyFormatter.format(price: minPrice)
    }
    
    var formattedMaxPrice: String {
        return CurrencyFormatter.format(price: maxPrice)
    }
    
    var formattedModalPrice: String {
        return CurrencyFormatter.format(price: modalPrice)
    }
    
    enum CodingKeys: String, CodingKey {
        case commodity
        case state
        case district
        case market
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case modalPrice = "modal_price"
        case unit
        case arrivalDate = "arrival_date"
    }
}

// MARK: - API Response Models
struct MandiAPIResponse: Codable {
    let records: [MandiRecord]
}

struct MandiRecord: Codable {
    let state: String
    let district: String
    let market: String
    let commodity: String
    let variety: String?
    let arrivalDate: String?
    let minPrice: String?
    let maxPrice: String?
    let modalPrice: String?
    
    enum CodingKeys: String, CodingKey {
        case state
        case district
        case market
        case commodity
        case variety
        case arrivalDate = "arrival_date"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case modalPrice = "modal_price"
    }
    
    func toMandiCommodityPrice() -> MandiCommodityPrice? {
        // Parse price strings to doubles (they may contain commas)
        guard let modalPriceStr = modalPrice,
              let modal = Double(modalPriceStr.replacingOccurrences(of: ",", with: "")) else {
            return nil
        }
        
        let min = minPrice.flatMap { Double($0.replacingOccurrences(of: ",", with: "")) } ?? modal
        let max = maxPrice.flatMap { Double($0.replacingOccurrences(of: ",", with: "")) } ?? modal
        
        return MandiCommodityPrice(
            commodity: commodity,
            state: state,
            district: district,
            market: market,
            minPrice: min,
            maxPrice: max,
            modalPrice: modal,
            unit: "₹/quintal",
            arrivalDate: arrivalDate
        )
    }
}

// MARK: - Sample Data for Preview/Fallback
extension MandiCommodityPrice {
    static let samples: [MandiCommodityPrice] = [
        MandiCommodityPrice(
            commodity: "Wheat",
            state: "Punjab",
            district: "Ludhiana",
            market: "Khanna",
            minPrice: 2200,
            maxPrice: 2350,
            modalPrice: 2300,
            unit: "₹/quintal",
            arrivalDate: nil
        ),
        MandiCommodityPrice(
            commodity: "Rice",
            state: "Haryana",
            district: "Karnal",
            market: "Gharaunda",
            minPrice: 3200,
            maxPrice: 3450,
            modalPrice: 3380,
            unit: "₹/quintal",
            arrivalDate: nil
        ),
        MandiCommodityPrice(
            commodity: "Cotton",
            state: "Gujarat",
            district: "Rajkot",
            market: "Rajkot",
            minPrice: 5800,
            maxPrice: 6200,
            modalPrice: 6000,
            unit: "₹/quintal",
            arrivalDate: nil
        ),
        MandiCommodityPrice(
            commodity: "Soybean",
            state: "Madhya Pradesh",
            district: "Indore",
            market: "Indore",
            minPrice: 4300,
            maxPrice: 4700,
            modalPrice: 4500,
            unit: "₹/quintal",
            arrivalDate: nil
        )
    ]
}
