//
//  OrderManager.swift
//  Agrisense
//
//  Created by Athar Reza on 17/08/25.
//

import Foundation
import Combine

class OrderManager: ObservableObject {
    @Published var orders: [Order] = []
    @Published var orderSummary: OrderHistorySummary?
    
    private let userDefaults = UserDefaults.standard
    private let ordersKey = "user_orders_"
    private var currentUserId: String
    
    init(userId: String) {
        self.currentUserId = userId
        loadOrders(for: userId)
        updateOrderSummary()
    }
    
    // MARK: - Order Operations
    
    func placeOrder(from cart: Cart, deliveryAddress: DeliveryAddress) -> Order {
        let newOrder = Order(from: cart, deliveryAddress: deliveryAddress)
        orders.insert(newOrder, at: 0) // Add to beginning for chronological order
        saveOrders()
        updateOrderSummary()
        return newOrder
    }
    
    func updateOrderStatus(orderId: UUID, status: OrderStatus) {
        if let index = orders.firstIndex(where: { $0.id == orderId }) {
            orders[index].updateStatus(status)
            saveOrders()
            updateOrderSummary()
        }
    }
    
    func getOrder(by id: UUID) -> Order? {
        return orders.first { $0.id == id }
    }
    
    func getActiveOrders() -> [Order] {
        return orders.filter { $0.isActive }
    }
    
    func getCompletedOrders() -> [Order] {
        return orders.filter { $0.status == .delivered }
    }
    
    func getOrdersByStatus(_ status: OrderStatus) -> [Order] {
        return orders.filter { $0.status == status }
    }
    
    func searchOrders(query: String) -> [Order] {
        let lowercaseQuery = query.lowercased()
        return orders.filter { order in
            order.orderNumber.lowercased().contains(lowercaseQuery) ||
            order.items.contains { item in
                item.productName.lowercased().contains(lowercaseQuery) ||
                item.seller.lowercased().contains(lowercaseQuery)
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveOrders() {
        let key = ordersKey + currentUserId
        if let encoded = try? JSONEncoder().encode(orders) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    private func loadOrders(for userId: String) {
        let key = ordersKey + userId
        guard let data = userDefaults.data(forKey: key),
              let loadedOrders = try? JSONDecoder().decode([Order].self, from: data) else {
            orders = []
            return
        }
        orders = loadedOrders.sorted { $0.orderDate > $1.orderDate }
    }
    
    func switchUser(to userId: String) {
        currentUserId = userId
        loadOrders(for: userId)
        updateOrderSummary()
    }
    
    // MARK: - Helper Methods
    
    private func updateOrderSummary() {
        orderSummary = OrderHistorySummary(orders: orders)
    }
    
    func getRecentOrders(limit: Int = 5) -> [Order] {
        return Array(orders.prefix(limit))
    }
    
    func getTotalSpent() -> Double {
        return orders.reduce(0) { $0 + $1.totalAmount }
    }
    
    func getOrdersInDateRange(from startDate: Date, to endDate: Date) -> [Order] {
        return orders.filter { order in
            order.orderDate >= startDate && order.orderDate <= endDate
        }
    }
    
    // MARK: - Mock Data for Testing
    
    func addMockOrders() {
        // This can be used for testing purposes
        guard orders.isEmpty else { return }
        
        // Create some mock orders for demonstration
        let mockCart1 = Cart(userId: currentUserId)
        let mockCart2 = Cart(userId: currentUserId)
        
        // You would populate these with actual cart items and addresses
        // This is just for structure - actual implementation would use real data
    }
    
    // MARK: - Statistics
    
    func getMonthlyOrderCount() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return orders.filter { order in
            order.orderDate >= startOfMonth
        }.count
    }
    
    func getFavoriteProducts() -> [(productName: String, orderCount: Int)] {
        var productCounts: [String: Int] = [:]
        
        for order in orders {
            for item in order.items {
                productCounts[item.productName, default: 0] += item.quantity
            }
        }
        
        return productCounts.map { (productName: $0.key, orderCount: $0.value) }
            .sorted { $0.orderCount > $1.orderCount }
            .prefix(5)
            .map { $0 }
    }
}
