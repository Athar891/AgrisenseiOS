//
//  AddressModels.swift
//  Agrisense
//
//  Created by Athar Reza on 16/08/25.
//

import Foundation

// MARK: - Address Model
struct DeliveryAddress: Identifiable, Codable, Equatable {
    let id: UUID
    var fullName: String
    var addressLine1: String
    var addressLine2: String
    var city: String
    var state: String
    var zipCode: String
    var country: String
    var phoneNumber: String
    var addressType: AddressType
    var isDefault: Bool
    
    var formattedAddress: String {
        var components: [String] = []
        
        if !addressLine1.isEmpty {
            components.append(addressLine1)
        }
        if !addressLine2.isEmpty {
            components.append(addressLine2)
        }
        if !city.isEmpty {
            components.append(city)
        }
        if !state.isEmpty && !zipCode.isEmpty {
            components.append("\(state) \(zipCode)")
        } else if !state.isEmpty {
            components.append(state)
        } else if !zipCode.isEmpty {
            components.append(zipCode)
        }
        if !country.isEmpty {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    var shortAddress: String {
        var components: [String] = []
        
        if !addressLine1.isEmpty {
            components.append(addressLine1)
        }
        if !city.isEmpty {
            components.append(city)
        }
        if !zipCode.isEmpty {
            components.append(zipCode)
        }
        
        return components.joined(separator: ", ")
    }
    
    var isComplete: Bool {
        return !fullName.isEmpty &&
               !addressLine1.isEmpty &&
               !city.isEmpty &&
               !state.isEmpty &&
               !zipCode.isEmpty &&
               !country.isEmpty &&
               !phoneNumber.isEmpty
    }
    
    init(id: UUID = UUID(), fullName: String = "", addressLine1: String = "", addressLine2: String = "", city: String = "", state: String = "", zipCode: String = "", country: String = "", phoneNumber: String = "", addressType: AddressType = .home, isDefault: Bool = false) {
        self.id = id
        self.fullName = fullName
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.phoneNumber = phoneNumber
        self.addressType = addressType
        self.isDefault = isDefault
    }
}

// MARK: - Address Type
enum AddressType: String, CaseIterable, Codable {
    case home = "Home"
    case work = "Work"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .work:
            return "building.2.fill"
        case .other:
            return "location.fill"
        }
    }
}

// MARK: - Address Collection Model
struct AddressCollection: Codable {
    var addresses: [DeliveryAddress]
    let userId: String
    var lastUpdated: Date
    
    var defaultAddress: DeliveryAddress? {
        return addresses.first { $0.isDefault }
    }
    
    var hasAddresses: Bool {
        return !addresses.isEmpty
    }
    
    init(userId: String) {
        self.addresses = []
        self.userId = userId
        self.lastUpdated = Date()
    }
    
    mutating func addAddress(_ address: DeliveryAddress) {
        var newAddress = address
        
        // If this is the first address or marked as default, make it default
        if addresses.isEmpty || address.isDefault {
            // Remove default from other addresses
            for i in addresses.indices {
                addresses[i].isDefault = false
            }
            newAddress.isDefault = true
        }
        
        addresses.append(newAddress)
        lastUpdated = Date()
    }
    
    mutating func updateAddress(_ updatedAddress: DeliveryAddress) {
        if let index = addresses.firstIndex(where: { $0.id == updatedAddress.id }) {
            var newAddress = updatedAddress
            
            // If setting as default, remove default from others
            if updatedAddress.isDefault {
                for i in addresses.indices {
                    if i != index {
                        addresses[i].isDefault = false
                    }
                }
            }
            
            addresses[index] = newAddress
            lastUpdated = Date()
        }
    }
    
    mutating func removeAddress(withId id: UUID) {
        let wasDefault = addresses.first { $0.id == id }?.isDefault ?? false
        addresses.removeAll { $0.id == id }
        
        // If we removed the default address and there are still addresses, make the first one default
        if wasDefault && !addresses.isEmpty {
            addresses[0].isDefault = true
        }
        
        lastUpdated = Date()
    }
    
    mutating func setDefaultAddress(withId id: UUID) {
        for i in addresses.indices {
            addresses[i].isDefault = (addresses[i].id == id)
        }
        lastUpdated = Date()
    }
}
