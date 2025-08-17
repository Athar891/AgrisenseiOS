//
//  CartManager.swift
//  Agrisense
//
//  Created by Athar Reza on 16/08/25.
//

import Foundation
import Combine

class CartManager: ObservableObject {
    @Published var currentCart: Cart
    private let userDefaults = UserDefaults.standard
    private let cartKey = "user_cart_"
    
    init(userId: String) {
        self.currentCart = Cart(userId: userId)
        loadCart(for: userId)
    }
    
    // MARK: - Cart Operations
    
    func addToCart(product: Product, quantity: Int = 1) -> Bool {
        // Validate stock availability
        guard quantity > 0 && quantity <= product.stock else {
            return false
        }
        
        // Check if adding this quantity would exceed stock
        if let existingItem = currentCart.items.first(where: { $0.productId == product.id }) {
            let totalQuantity = existingItem.quantity + quantity
            guard totalQuantity <= product.stock else {
                return false
            }
        }
        
        let cartItem = CartItem(from: product, quantity: quantity)
        currentCart.addItem(cartItem)
        saveCart()
        return true
    }
    
    func removeFromCart(itemId: UUID) {
        currentCart.removeItem(withId: itemId)
        saveCart()
    }
    
    func updateQuantity(itemId: UUID, quantity: Int) -> Bool {
        guard let item = currentCart.items.first(where: { $0.id == itemId }) else {
            return false
        }
        
        // Validate quantity against stock
        guard quantity >= 0 && quantity <= item.maxStock else {
            return false
        }
        
        currentCart.updateItemQuantity(itemId: itemId, quantity: quantity)
        saveCart()
        return true
    }
    
    func clearCart() {
        currentCart.clearCart()
        saveCart()
    }
    
    func getItemQuantity(for productId: UUID) -> Int {
        return currentCart.items.first(where: { $0.productId == productId })?.quantity ?? 0
    }
    
    func canAddToCart(product: Product, additionalQuantity: Int = 1) -> Bool {
        let currentQuantity = getItemQuantity(for: product.id)
        let totalQuantity = currentQuantity + additionalQuantity
        return totalQuantity <= product.stock
    }
    
    // MARK: - Persistence
    
    private func saveCart() {
        let key = cartKey + currentCart.userId
        if let encoded = try? JSONEncoder().encode(currentCart) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    private func loadCart(for userId: String) {
        let key = cartKey + userId
        guard let data = userDefaults.data(forKey: key),
              let cart = try? JSONDecoder().decode(Cart.self, from: data) else {
            currentCart = Cart(userId: userId)
            return
        }
        currentCart = cart
    }
    
    func switchUser(to userId: String) {
        currentCart = Cart(userId: userId)
        loadCart(for: userId)
    }
    
    // MARK: - Helper Methods
    
    func getCartSummary() -> (itemCount: Int, totalPrice: Double) {
        return (currentCart.totalItems, currentCart.totalPrice)
    }
    
    func validateCartItems(against products: [Product]) -> [UUID] {
        var invalidItems: [UUID] = []
        
        for item in currentCart.items {
            if let product = products.first(where: { $0.id == item.productId }) {
                // Check if item quantity exceeds current stock
                if item.quantity > product.stock {
                    invalidItems.append(item.id)
                }
                // Check if price has changed significantly (optional validation)
                if abs(item.price - product.price) > 0.01 {
                    // Price changed - could notify user
                }
            } else {
                // Product no longer exists
                invalidItems.append(item.id)
            }
        }
        
        return invalidItems
    }
    
    func removeInvalidItems(_ itemIds: [UUID]) {
        for itemId in itemIds {
            currentCart.removeItem(withId: itemId)
        }
        if !itemIds.isEmpty {
            saveCart()
        }
    }
}
