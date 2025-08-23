//
//  CartView.swift
//  Agrisense
//
//  Created by Athar Reza on 16/08/25.
//

import SwiftUI

struct CartView: View {
    @ObservedObject var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingCheckout = false
    
    var body: some View {
        NavigationView {
            Group {
                if cartManager.currentCart.isEmpty {
            EmptyCartView()
                } else {
                    CartContentView(cartManager: cartManager, showingCheckout: $showingCheckout)
                }
            }
        .navigationTitle(LocalizationManager.shared.localizedString(for: "my_cart"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
            Button(LocalizationManager.shared.localizedString(for: "close")) {
                        dismiss()
                    }
                }
                
                if !cartManager.currentCart.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
            Button(LocalizationManager.shared.localizedString(for: "clear")) {
                            cartManager.clearCart()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCheckout) {
            CheckoutView(cartManager: cartManager)
        }
    }
}

struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(LocalizationManager.shared.localizedString(for: "your_cart_empty"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(LocalizationManager.shared.localizedString(for: "add_products_prompt"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

struct CartContentView: View {
    @ObservedObject var cartManager: CartManager
    @Binding var showingCheckout: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Cart Items List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(cartManager.currentCart.items) { item in
                        CartItemRow(item: item, cartManager: cartManager)
                    }
                }
                .padding()
            }
            
            // Cart Summary
            CartSummaryView(cartManager: cartManager, showingCheckout: $showingCheckout)
        }
    }
}

struct CartItemRow: View {
    let item: CartItem
    @ObservedObject var cartManager: CartManager
    @State private var showingRemoveAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            AsyncImage(url: URL(string: item.productImageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 80)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                        .frame(width: 80, height: 80)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                @unknown default:
                    EmptyView()
                }
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text("by \(item.seller)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.formattedPrice + " per \(item.unit)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                
                // Quantity Controls
                HStack {
                    Button(action: { decreaseQuantity() }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(item.quantity > 1 ? .green : .gray)
                    }
                    .disabled(item.quantity <= 1)
                    
                    Text("\(item.quantity)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(minWidth: 30)
                    
                    Button(action: { increaseQuantity() }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(item.quantity < item.maxStock ? .green : .gray)
                    }
                    .disabled(item.quantity >= item.maxStock)
                    
                    Spacer()
                    
                    // Remove Button
                    Button(action: { showingRemoveAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            // Total Price
            VStack(alignment: .trailing) {
                Text(item.formattedTotalPrice)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(item.quantity) \(item.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .alert("Remove Item", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                cartManager.removeFromCart(itemId: item.id)
            }
        } message: {
            Text("Are you sure you want to remove \(item.productName) from your cart?")
        }
    }
    
    private func increaseQuantity() {
        _ = cartManager.updateQuantity(itemId: item.id, quantity: item.quantity + 1)
    }
    
    private func decreaseQuantity() {
        _ = cartManager.updateQuantity(itemId: item.id, quantity: item.quantity - 1)
    }
}

struct CartSummaryView: View {
    @ObservedObject var cartManager: CartManager
    @Binding var showingCheckout: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Divider()
            
            // Summary Details
            VStack(spacing: 8) {
                HStack {
                    Text("Total Items:")
                        .font(.subheadline)
                    Spacer()
                    Text("\(cartManager.currentCart.totalItems)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Total Amount:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(cartManager.currentCart.formattedTotalPrice)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            
            // Checkout Button
            Button(action: { showingCheckout = true }) {
                Text("Proceed to Checkout")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
}

struct CheckoutView: View {
    @ObservedObject var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingOrderConfirmation = false
    @State private var showingAddressSelection = false
    @State private var selectedAddress: DeliveryAddress?
    @State private var placedOrder: Order?
    @StateObject private var addressManager: AddressManager
    @StateObject private var orderManager: OrderManager
    
    init(cartManager: CartManager) {
        self.cartManager = cartManager
        self._addressManager = StateObject(wrappedValue: AddressManager(userId: cartManager.currentCart.userId))
        self._orderManager = StateObject(wrappedValue: OrderManager(userId: cartManager.currentCart.userId))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Order Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Summary")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(cartManager.currentCart.items) { item in
                            HStack {
                                Text("\(item.quantity)x \(item.productName)")
                                    .font(.subheadline)
                                Spacer()
                                Text(item.formattedTotalPrice)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total:")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                            Text(cartManager.currentCart.formattedTotalPrice)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Delivery Address Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Delivery Address")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let address = selectedAddress {
                            AddressDisplayCard(address: address, onEdit: {
                                showingAddressSelection = true
                            })
                        } else {
                            Button(action: { showingAddressSelection = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Select Delivery Address")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Place Order Button
                    Button(action: { placeOrder() }) {
                        Text("Place Order")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .disabled(selectedAddress == nil)
                }
                .padding()
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Set default address if available
            if selectedAddress == nil {
                selectedAddress = addressManager.defaultAddress
            }
        }
        .sheet(isPresented: $showingAddressSelection) {
            AddressSelectionView(addressManager: addressManager, selectedAddress: $selectedAddress)
        }
        .alert("Order Placed!", isPresented: $showingOrderConfirmation) {
            Button("OK") {
                cartManager.clearCart()
                dismiss()
            }
        } message: {
            if let order = placedOrder {
                Text("Your order #\(order.orderNumber) has been placed successfully! You can track it in your profile.")
            } else {
                Text("Your order has been placed successfully! You will receive a confirmation shortly.")
            }
        }
    }
    
    private func placeOrder() {
        guard let address = selectedAddress else {
            showingAddressSelection = true
            return
        }
        
        // Create and save the order
        let newOrder = orderManager.placeOrder(from: cartManager.currentCart, deliveryAddress: address)
        placedOrder = newOrder
        showingOrderConfirmation = true
    }
}

#Preview {
    CartView(cartManager: CartManager(userId: "preview"))
}
