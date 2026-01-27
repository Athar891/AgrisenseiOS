//
//  WholesalersView.swift
//  Agrisense
//
//  Created by Athar Reza on 17/12/25.
//

import SwiftUI

struct WholesalersView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var userManager: UserManager
    @State private var wholesalers: [Wholesaler] = sampleWholesalers
    @State private var selectedCommodity: String = "All"
    @State private var sortBy: SortOption = .distance
    @State private var showingFilters = false
    @State private var selectedWholesaler: Wholesaler?
    @State private var showingContactSheet = false
    
    let commodityFilters = ["All", "Rice", "Wheat", "Vegetables", "Fruits", "Pulses", "Cotton", "Spices"]
    
    var filteredWholesalers: [Wholesaler] {
        var filtered = wholesalers
        
        // Filter by commodity
        if selectedCommodity != "All" {
            filtered = filtered.filter { $0.commodities.contains(selectedCommodity) }
        }
        
        // Sort
        switch sortBy {
        case .distance:
            filtered.sort { ($0.distanceKm ?? 999) < ($1.distanceKm ?? 999) }
        case .rating:
            filtered.sort { $0.rating > $1.rating }
        case .name:
            filtered.sort { $0.businessName < $1.businessName }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Commodity Filter
            CommodityFilterBar(selectedCommodity: $selectedCommodity, commodities: commodityFilters)
            
            // Sort and Filter Options
            HStack {
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortBy = option
                        } label: {
                            HStack {
                                Text(option.displayName)
                                if sortBy == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Sort: \(sortBy.displayName)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Text("\(filteredWholesalers.count) Wholesalers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Wholesalers List
            if filteredWholesalers.isEmpty {
                EmptyWholesalersView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredWholesalers) { wholesaler in
                            WholesalerCard(wholesaler: wholesaler) {
                                selectedWholesaler = wholesaler
                                showingContactSheet = true
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedWholesaler) { wholesaler in
            WholesalerDetailSheet(wholesaler: wholesaler)
        }
    }
}

struct CommodityFilterBar: View {
    @Binding var selectedCommodity: String
    let commodities: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(commodities, id: \.self) { commodity in
                    Button {
                        withAnimation {
                            selectedCommodity = commodity
                        }
                    } label: {
                        Text(commodity)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedCommodity == commodity ? .white : .green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCommodity == commodity ? Color.green : Color.green.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct WholesalerCard: View {
    let wholesaler: Wholesaler
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Text(wholesaler.name.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(wholesaler.businessName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if wholesaler.verified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                            }
                        }
                        
                        Text(wholesaler.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", wholesaler.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("(\(wholesaler.reviewsCount))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let distance = wholesaler.distanceKm {
                        VStack(alignment: .trailing) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(String(format: "%.1f km", distance))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("\(wholesaler.location), \(wholesaler.city)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Commodities
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(wholesaler.commodities, id: \.self) { commodity in
                            Text(commodity)
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Contact Button
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                    Text("Contact Now")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.green)
                .cornerRadius(8)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WholesalerDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let wholesaler: Wholesaler
    @State private var showingCallConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Text(wholesaler.name.prefix(1))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(wholesaler.businessName)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                if wholesaler.verified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text(wholesaler.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", wholesaler.rating))
                                    .fontWeight(.semibold)
                                Text("(\(wholesaler.reviewsCount) reviews)")
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        Text(wholesaler.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Commodities
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Commodities Accepted")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(wholesaler.commodities, id: \.self) { commodity in
                                HStack {
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text(commodity)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Information")
                            .font(.headline)
                        
                        WholesalerInfoRow(icon: "phone.fill", title: "Phone", value: wholesaler.phoneNumber)
                        
                        if let email = wholesaler.email {
                            WholesalerInfoRow(icon: "envelope.fill", title: "Email", value: email)
                        }
                        
                        WholesalerInfoRow(icon: "mappin.and.ellipse", title: "Location", value: "\(wholesaler.location), \(wholesaler.city), \(wholesaler.state)")
                        
                        if let distance = wholesaler.distanceKm {
                            WholesalerInfoRow(icon: "location.fill", title: "Distance", value: String(format: "%.1f km away", distance))
                        }
                        
                        WholesalerInfoRow(icon: "clock.fill", title: "Operating Hours", value: wholesaler.operatingHours)
                        
                        if let minQty = wholesaler.minimumQuantity {
                            WholesalerInfoRow(icon: "scalemass.fill", title: "Minimum Quantity", value: minQty)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Payment Methods
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Methods")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(wholesaler.acceptedPaymentMethods, id: \.self) { method in
                                HStack {
                                    Image(systemName: paymentIcon(for: method))
                                        .foregroundColor(.green)
                                    Text(method)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Contact Buttons
                    VStack(spacing: 12) {
                        Button {
                            if let url = URL(string: "tel://\(wholesaler.phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Call Now")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        if let email = wholesaler.email {
                            Button {
                                if let url = URL(string: "mailto:\(email)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("Send Email")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        
                        Button {
                            let message = "Hi, I'm interested in selling my commodities. Can we discuss?"
                            let urlString = "https://wa.me/\(wholesaler.phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: ""))?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                            if let url = URL(string: urlString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("WhatsApp")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.15, green: 0.68, blue: 0.38))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationTitle("Wholesaler Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func paymentIcon(for method: String) -> String {
        switch method.lowercased() {
        case "cash":
            return "banknote.fill"
        case "upi":
            return "qrcode"
        case "bank transfer":
            return "building.columns.fill"
        case "cheque":
            return "doc.text.fill"
        default:
            return "creditcard.fill"
        }
    }
}

struct WholesalerInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

struct EmptyWholesalersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Wholesalers Found")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Try adjusting your filters or check back later")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum SortOption: String, CaseIterable {
    case distance = "Distance"
    case rating = "Rating"
    case name = "Name"
    
    var displayName: String {
        self.rawValue
    }
}

#Preview {
    WholesalersView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(UserManager())
}
