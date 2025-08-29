//
//  AddressViews.swift
//  Agrisense
//
//  Created by Athar Reza on 16/08/25.
//

import SwiftUI

// MARK: - Address Selection View
struct AddressSelectionView: View {
    @ObservedObject var addressManager: AddressManager
    @Binding var selectedAddress: DeliveryAddress?
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddAddress = false
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationView {
            VStack {
                if addressManager.hasAddresses {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(addressManager.allAddresses) { address in
                                AddressSelectionRow(
                                    address: address,
                                    isSelected: selectedAddress?.id == address.id,
                                    onSelect: { selectedAddress = address },
                                    addressManager: addressManager
                                )
                            }
                        }
                        .padding()
                    }
                } else {
                    EmptyAddressView()
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "select_address_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: "add_new")) {
                        showingAddAddress = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddAddress) {
            AddEditAddressView(addressManager: addressManager)
        }
    }
}

// MARK: - Address Selection Row
struct AddressSelectionRow: View {
    let address: DeliveryAddress
    let isSelected: Bool
    let onSelect: () -> Void
    let addressManager: AddressManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.title2)
                
                // Address type icon
                Image(systemName: address.addressType.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                // Address details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(address.addressType.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if address.isDefault {
                            Text(LocalizationManager.shared.localizedString(for: "default_label"))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(address.fullName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(address.shortAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    if !address.phoneNumber.isEmpty {
                        Text(address.phoneNumber)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Edit button
                NavigationLink(destination: AddEditAddressView(addressManager: addressManager, address: address)) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Address View
struct EmptyAddressView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localizedString(for: "no_addresses"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationManager.shared.localizedString(for: "add_delivery_address_prompt"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

// MARK: - Add/Edit Address View
struct AddEditAddressView: View {
    @ObservedObject var addressManager: AddressManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    let address: DeliveryAddress?
    
    @State private var fullName: String = ""
    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var country: String = ""
    @State private var phoneNumber: String = ""
    @State private var addressType: AddressType = .home
    @State private var isDefault: Bool = false
    
    @State private var validationErrors: [String] = []
    @State private var showingValidationAlert = false
    
    private var isEditing: Bool {
        return address != nil
    }
    
    private var navigationTitle: String {
    return isEditing ? LocalizationManager.shared.localizedString(for: "edit_address_title") : LocalizationManager.shared.localizedString(for: "add_address_title")
    }
    
    init(addressManager: AddressManager, address: DeliveryAddress? = nil) {
        self.addressManager = addressManager
        self.address = address
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizationManager.shared.localizedString(for: "contact_information"))) {
                    TextField(localizationManager.localizedString(for: "full_name_placeholder"), text: $fullName)
                        .textContentType(.name)
                    
                    TextField(localizationManager.localizedString(for: "phone_number_placeholder"), text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text(LocalizationManager.shared.localizedString(for: "address_section"))) {
                    TextField(localizationManager.localizedString(for: "street_address_placeholder"), text: $addressLine1)
                        .textContentType(.streetAddressLine1)
                    
                    TextField(localizationManager.localizedString(for: "apartment_placeholder"), text: $addressLine2)
                        .textContentType(.streetAddressLine2)
                    
                    TextField(localizationManager.localizedString(for: "city_placeholder"), text: $city)
                        .textContentType(.addressCity)
                    
                    HStack {
                        TextField(localizationManager.localizedString(for: "state_placeholder"), text: $state)
                            .textContentType(.addressState)
                        
                        TextField(localizationManager.localizedString(for: "zip_placeholder"), text: $zipCode)
                            .textContentType(.postalCode)
                    }
                    
                    TextField(localizationManager.localizedString(for: "country_placeholder"), text: $country)
                        .textContentType(.countryName)
                }
                
                Section(header: Text(LocalizationManager.shared.localizedString(for: "address_type_section"))) {
                    Picker("Type", selection: $addressType) {
                        ForEach(AddressType.allCases, id: \.self) { type in
                            Image(systemName: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle(LocalizationManager.shared.localizedString(for: "set_as_default"), isOn: $isDefault)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.localizedString(for: "cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.localizedString(for: "save")) {
                        saveAddress()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadAddressData()
        }
        .alert(LocalizationManager.shared.localizedString(for: "validation_error_title"), isPresented: $showingValidationAlert) {
            Button(LocalizationManager.shared.localizedString(for: "ok")) { }
        } message: {
            Text(validationErrors.joined(separator: "\n"))
        }
    }
    
    private func loadAddressData() {
        guard let address = address else {
            // Set default country if adding new address
            if country.isEmpty {
                country = "India"
            }
            return
        }
        
        fullName = address.fullName
        addressLine1 = address.addressLine1
        addressLine2 = address.addressLine2
        city = address.city
        state = address.state
        zipCode = address.zipCode
        country = address.country
        phoneNumber = address.phoneNumber
        addressType = address.addressType
        isDefault = address.isDefault
    }
    
    private func saveAddress() {
        let addressToSave: DeliveryAddress
        
        if isEditing, let originalAddress = address {
            // Preserve the original ID when editing
            addressToSave = DeliveryAddress(
                id: originalAddress.id,
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                addressLine1: addressLine1.trimmingCharacters(in: .whitespacesAndNewlines),
                addressLine2: addressLine2.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                state: state.trimmingCharacters(in: .whitespacesAndNewlines),
                zipCode: zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
                country: country.trimmingCharacters(in: .whitespacesAndNewlines),
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                addressType: addressType,
                isDefault: isDefault
            )
        } else {
            // Create new address with new ID
            addressToSave = DeliveryAddress(
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                addressLine1: addressLine1.trimmingCharacters(in: .whitespacesAndNewlines),
                addressLine2: addressLine2.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                state: state.trimmingCharacters(in: .whitespacesAndNewlines),
                zipCode: zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
                country: country.trimmingCharacters(in: .whitespacesAndNewlines),
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                addressType: addressType,
                isDefault: isDefault
            )
        }
        
        validationErrors = addressManager.validateAddress(addressToSave)
        
        if !validationErrors.isEmpty {
            showingValidationAlert = true
            return
        }
        
        if isEditing {
            addressManager.updateAddress(addressToSave)
        } else {
            addressManager.addAddress(addressToSave)
        }
        
        dismiss()
    }
}

// MARK: - Address Display Card
struct AddressDisplayCard: View {
    let address: DeliveryAddress
    let onEdit: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: address.addressType.icon)
                    .foregroundColor(.blue)
                
                Text(address.addressType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if address.isDefault {
                    Text(localizationManager.localizedString(for: "default_label"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(localizationManager.localizedString(for: "change"), action: onEdit)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(address.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(address.formattedAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                if !address.phoneNumber.isEmpty {
                    Text(address.phoneNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    AddressSelectionView(
        addressManager: AddressManager(userId: "preview"),
        selectedAddress: .constant(nil)
    )
    .environmentObject(LocalizationManager.shared)
}
