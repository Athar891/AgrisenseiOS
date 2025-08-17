import Foundation

enum UserType: String, CaseIterable, Codable {
    case farmer = "farmer"
    case seller = "seller"
    
    var displayName: String {
        switch self {
        case .farmer:
            return "Farmer"
        case .seller:
            return "Seller"
        }
    }
    
    var icon: String {
        switch self {
        case .farmer:
            return "leaf.fill"
        case .seller:
            return "cart.fill"
        }
    }
}

struct User: Codable, Identifiable {
    let id: String
    var name: String  // Changed to var to allow editing
    let email: String
    let userType: UserType
    var profileImage: String?  // Using profileImage (not profileImageURL)
    var location: String?      // Using location (not address)
    var phoneNumber: String?
    var crops: [Crop] = []     // User's active crops
}
