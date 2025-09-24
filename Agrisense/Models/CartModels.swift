//
//  CartModels.swift
//  Agrisense
//
//  Created by Athar Reza on 16/08/25.
//

import Foundation

// MARK: - Cart Item Model
struct CartItem: Identifiable, Codable, Equatable {
    let id = UUID()
    let productId: String  // Changed from UUID to String
    let productName: String
    let productDescription: String
    let price: Double
    let unit: String
    let seller: String
    let productImageURL: String?
    var quantity: Int
    let maxStock: Int
    
    var totalPrice: Double {
        return price * Double(quantity)
    }
    
    var formattedPrice: String {
        return CurrencyFormatter.format(price: price)
    }
    
    var formattedTotalPrice: String {
        return CurrencyFormatter.format(price: totalPrice)
    }
    
    // Initialize from Product
    init(from product: Product, quantity: Int = 1) {
        self.productId = product.id
        self.productName = product.name
        self.productDescription = product.description
        self.price = product.price
        self.unit = product.unit
        self.seller = product.seller
        self.productImageURL = product.mainImage?.url
        self.quantity = quantity
        self.maxStock = product.stock
    }
    
    // Custom initializer for decoding
    init(productId: String, productName: String, productDescription: String, price: Double, unit: String, seller: String, productImageURL: String?, quantity: Int, maxStock: Int) {
        self.productId = productId
        self.productName = productName
        self.productDescription = productDescription
        self.price = price
        self.unit = unit
        self.seller = seller
        self.productImageURL = productImageURL
        self.quantity = quantity
        self.maxStock = maxStock
    }
}

// MARK: - Cart Model
struct Cart: Codable {
    var items: [CartItem]
    let userId: String
    var lastUpdated: Date
    
    var totalItems: Int {
        return items.reduce(0) { $0 + $1.quantity }
    }
    
    var totalPrice: Double {
        return items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var formattedTotalPrice: String {
        return CurrencyFormatter.format(price: totalPrice)
    }
    
    var isEmpty: Bool {
        return items.isEmpty
    }
    
    init(userId: String) {
        self.items = []
        self.userId = userId
        self.lastUpdated = Date()
    }
    
    mutating func addItem(_ item: CartItem) {
        if let existingIndex = items.firstIndex(where: { $0.productId == item.productId }) {
            // Update existing item quantity
            let newQuantity = items[existingIndex].quantity + item.quantity
            items[existingIndex].quantity = min(newQuantity, item.maxStock)
        } else {
            // Add new item
            items.append(item)
        }
        lastUpdated = Date()
    }
    
    mutating func removeItem(withId id: UUID) {
        items.removeAll { $0.id == id }
        lastUpdated = Date()
    }
    
    mutating func updateItemQuantity(itemId: UUID, quantity: Int) {
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            if quantity <= 0 {
                items.remove(at: index)
            } else {
                items[index].quantity = min(quantity, items[index].maxStock)
            }
            lastUpdated = Date()
        }
    }
    
    mutating func clearCart() {
        items.removeAll()
        lastUpdated = Date()
    }
}
