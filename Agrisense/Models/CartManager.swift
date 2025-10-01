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
    private let secureStorage = SecureStorage.shared
    private let cartKey = "user_cart_"
    
    init(userId: String) {
        self.currentCart = Cart(userId: userId)
        migrateFromUserDefaults(for: userId)
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
    
    func getItemQuantity(for productId: String) -> Int {
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
        do {
            try secureStorage.save(currentCart, forKey: key)
            #if DEBUG
            print("[CartManager] Successfully saved cart with \(currentCart.totalItems) items to secure storage")
            #endif
        } catch {
            #if DEBUG
            print("[CartManager] Failed to save cart: \(error.localizedDescription)")
            #endif
        }
    }
    
    private func loadCart(for userId: String) {
        let key = cartKey + userId
        do {
            let cart = try secureStorage.load(forKey: key, as: Cart.self)
            currentCart = cart
            #if DEBUG
            print("[CartManager] Successfully loaded cart with \(cart.totalItems) items from secure storage")
            #endif
        } catch SecureStorageError.itemNotFound {
            currentCart = Cart(userId: userId)
        } catch {
            #if DEBUG
            print("[CartManager] Failed to load cart: \(error.localizedDescription)")
            #endif
            currentCart = Cart(userId: userId)
        }
    }
    
    private func migrateFromUserDefaults(for userId: String) {
        let key = cartKey + userId
        
        // Check if already migrated
        if secureStorage.exists(forKey: key) {
            return
        }
        
        // Migrate from UserDefaults
        if let data = UserDefaults.standard.data(forKey: key),
           let legacyCart = try? JSONDecoder().decode(Cart.self, from: data) {
            do {
                try secureStorage.save(legacyCart, forKey: key)
                // Clear from UserDefaults after successful migration
                UserDefaults.standard.removeObject(forKey: key)
                #if DEBUG
                print("[CartManager] Migrated cart with \(legacyCart.totalItems) items from UserDefaults to Keychain")
                #endif
            } catch {
                #if DEBUG
                print("[CartManager] Failed to migrate cart: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    func switchUser(to userId: String) {
        currentCart = Cart(userId: userId)
        migrateFromUserDefaults(for: userId)
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
