//
//  AddressManager.swift
//  Agrisense
//
//  Created by Athar Reza on 16/08/25.
//

import Foundation
import Combine

class AddressManager: ObservableObject {
    @Published var addressCollection: AddressCollection
    private let userDefaults = UserDefaults.standard
    private let addressKey = "user_addresses_"
    
    init(userId: String) {
        self.addressCollection = AddressCollection(userId: userId)
        loadAddresses(for: userId)
    }
    
    // MARK: - Address Operations
    
    func addAddress(_ address: DeliveryAddress) {
        addressCollection.addAddress(address)
        saveAddresses()
    }
    
    func updateAddress(_ address: DeliveryAddress) {
        addressCollection.updateAddress(address)
        saveAddresses()
    }
    
    func removeAddress(withId id: UUID) {
        addressCollection.removeAddress(withId: id)
        saveAddresses()
    }
    
    func setDefaultAddress(withId id: UUID) {
        addressCollection.setDefaultAddress(withId: id)
        saveAddresses()
    }
    
    func getAddress(withId id: UUID) -> DeliveryAddress? {
        return addressCollection.addresses.first { $0.id == id }
    }
    
    // MARK: - Convenience Methods
    
    var defaultAddress: DeliveryAddress? {
        return addressCollection.defaultAddress
    }
    
    var hasAddresses: Bool {
        return addressCollection.hasAddresses
    }
    
    var allAddresses: [DeliveryAddress] {
        return addressCollection.addresses
    }
    
    func getAddressesByType(_ type: AddressType) -> [DeliveryAddress] {
        return addressCollection.addresses.filter { $0.addressType == type }
    }
    
    // MARK: - Persistence
    
    private func saveAddresses() {
        let key = addressKey + addressCollection.userId
        if let encoded = try? JSONEncoder().encode(addressCollection) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    private func loadAddresses(for userId: String) {
        let key = addressKey + userId
        guard let data = userDefaults.data(forKey: key),
              let collection = try? JSONDecoder().decode(AddressCollection.self, from: data) else {
            addressCollection = AddressCollection(userId: userId)
            return
        }
        addressCollection = collection
    }
    
    func switchUser(to userId: String) {
        addressCollection = AddressCollection(userId: userId)
        loadAddresses(for: userId)
    }
    
    // MARK: - Validation
    
    func validateAddress(_ address: DeliveryAddress) -> [String] {
        var errors: [String] = []
        
        if address.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Full name is required")
        }
        
        if address.addressLine1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Street address is required")
        }
        
        if address.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("City is required")
        }
        
        if address.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("State/Province is required")
        }
        
        if address.zipCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("ZIP/Postal code is required")
        }
        
        if address.country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Country is required")
        }
        
        if address.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Phone number is required")
        }
        
        return errors
    }
    
    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^[+]?[0-9\\s\\-\\(\\)]{10,}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: phoneNumber)
    }
    
    func isValidZipCode(_ zipCode: String) -> Bool {
        let zipRegex = "^[0-9A-Za-z\\s\\-]{3,}$"
        let zipTest = NSPredicate(format: "SELF MATCHES %@", zipRegex)
        return zipTest.evaluate(with: zipCode)
    }
}
