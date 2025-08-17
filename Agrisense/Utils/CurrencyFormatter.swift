import Foundation

struct CurrencyFormatter {
    static let indianRupees: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        return formatter
    }()
    
    static func format(price: Double) -> String {
        return indianRupees.string(from: NSNumber(value: price)) ?? "₹\(price)"
    }
}
