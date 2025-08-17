//
//  OrderModels.swift
//  Agrisense
//
//  Created by Athar Reza on 17/08/25.
//

import Foundation
import SwiftUI

// MARK: - Order Status
enum OrderStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case preparing = "preparing"
    case shipped = "shipped"
    case delivered = "delivered"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .shipped: return "Shipped"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .blue
        case .preparing: return .purple
        case .shipped: return .indigo
        case .delivered: return .green
        case .cancelled: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .preparing: return "hands.sparkles"
        case .shipped: return "shippingbox"
        case .delivered: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

// MARK: - Order Item Model
struct OrderItem: Identifiable, Codable, Equatable {
    let id: UUID
    let productId: UUID
    let productName: String
    let productDescription: String
    let price: Double
    let unit: String
    let seller: String
    let productImageURL: String?
    let quantity: Int
    
    var totalPrice: Double {
        return price * Double(quantity)
    }
    
    var formattedPrice: String {
        return CurrencyFormatter.format(price: price)
    }
    
    var formattedTotalPrice: String {
        return CurrencyFormatter.format(price: totalPrice)
    }
    
    // Initialize from CartItem
    init(from cartItem: CartItem) {
        self.id = UUID()
        self.productId = cartItem.productId
        self.productName = cartItem.productName
        self.productDescription = cartItem.productDescription
        self.price = cartItem.price
        self.unit = cartItem.unit
        self.seller = cartItem.seller
        self.productImageURL = cartItem.productImageURL
        self.quantity = cartItem.quantity
    }
}

// MARK: - Order Model
struct Order: Identifiable, Codable {
    let id: UUID
    let userId: String
    let orderNumber: String
    let items: [OrderItem]
    let deliveryAddress: DeliveryAddress
    let orderDate: Date
    var status: OrderStatus
    var estimatedDeliveryDate: Date?
    var actualDeliveryDate: Date?
    let totalAmount: Double
    let totalItems: Int
    
    var formattedTotalAmount: String {
        return CurrencyFormatter.format(price: totalAmount)
    }
    
    var formattedOrderDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: orderDate)
    }
    
    var formattedEstimatedDelivery: String? {
        guard let estimatedDeliveryDate = estimatedDeliveryDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: estimatedDeliveryDate)
    }
    
    var isActive: Bool {
        return ![.delivered, .cancelled].contains(status)
    }
    
    // Initialize from Cart and Address
    init(from cart: Cart, deliveryAddress: DeliveryAddress) {
        self.id = UUID()
        self.userId = cart.userId
        self.orderNumber = Order.generateOrderNumber()
        self.items = cart.items.map { OrderItem(from: $0) }
        self.deliveryAddress = deliveryAddress
        self.orderDate = Date()
        self.status = .pending
        self.totalAmount = cart.totalPrice
        self.totalItems = cart.totalItems
        
        // Set estimated delivery date (3-5 business days from now)
        let calendar = Calendar.current
        self.estimatedDeliveryDate = calendar.date(byAdding: .day, value: Int.random(in: 3...5), to: Date())
    }
    
    private static func generateOrderNumber() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let random = Int.random(in: 1000...9999)
        return "AGR\(timestamp)\(random)"
    }
    
    mutating func updateStatus(_ newStatus: OrderStatus) {
        self.status = newStatus
        if newStatus == .delivered && actualDeliveryDate == nil {
            self.actualDeliveryDate = Date()
        }
    }
}

// MARK: - Order History Summary
struct OrderHistorySummary: Codable {
    let totalOrders: Int
    let totalSpent: Double
    let activeOrders: Int
    let completedOrders: Int
    
    var formattedTotalSpent: String {
        return CurrencyFormatter.format(price: totalSpent)
    }
    
    init(orders: [Order]) {
        self.totalOrders = orders.count
        self.totalSpent = orders.reduce(0) { $0 + $1.totalAmount }
        self.activeOrders = orders.filter { $0.isActive }.count
        self.completedOrders = orders.filter { $0.status == .delivered }.count
    }
}
