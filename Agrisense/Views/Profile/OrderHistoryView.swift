//
//  OrderHistoryView.swift
//  Agrisense
//
//  Created by Athar Reza on 17/08/25.
//

import SwiftUI

struct OrderHistoryView: View {
    @ObservedObject var orderManager: OrderManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilter: OrderStatusFilter = .all
    @State private var selectedOrder: Order?
    @State private var showingOrderDetail = false
    
    enum OrderStatusFilter: String, CaseIterable {
        case all = "all"
        case active = "active"
        case delivered = "delivered"
        case cancelled = "cancelled"
        
        var displayName: String {
            LocalizationManager.shared.localizedString(for: "order_filter_\(rawValue)")
        }
    }
    
    var filteredOrders: [Order] {
        var orders = orderManager.orders
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            orders = orders.filter { $0.isActive }
        case .delivered:
            orders = orders.filter { $0.status == .delivered }
        case .cancelled:
            orders = orders.filter { $0.status == .cancelled }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            orders = orderManager.searchOrders(query: searchText)
        }
        
        return orders
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Order Summary Stats
                if let summary = orderManager.orderSummary {
                    OrderSummaryStatsView(summary: summary)
                        .padding()
                        .background(Color(.systemGray6))
                }
                
                // Search and Filter
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField(LocalizationManager.shared.localizedString(for: "search_orders_placeholder"), text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(OrderStatusFilter.allCases, id: \.self) { filter in
                                FilterTab(
                                    title: filter.displayName,
                                    isSelected: selectedFilter == filter
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                
                // Orders List
                if filteredOrders.isEmpty {
                    EmptyOrdersView(filter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredOrders) { order in
                                OrderRowView(order: order) {
                                    selectedOrder = order
                                    showingOrderDetail = true
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle(LocalizationManager.shared.localizedString(for: "order_history_title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.localizedString(for: "close")) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingOrderDetail) {
            if let order = selectedOrder {
                OrderDetailView(order: order, orderManager: orderManager)
            }
        }
    }
}

struct OrderSummaryStatsView: View {
    let summary: OrderHistorySummary
    
    var body: some View {
        HStack(spacing: 20) {
            OrderStatCard(title: "Total Orders", value: "\(summary.totalOrders)", icon: "bag", color: .blue)
            OrderStatCard(title: "Total Spent", value: summary.formattedTotalSpent, icon: "dollarsign.circle", color: .green)
            OrderStatCard(title: "Active", value: "\(summary.activeOrders)", icon: "clock", color: .orange)
        }
    }
}

struct OrderStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct FilterTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct OrderRowView: View {
    let order: Order
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Order Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order #\(order.orderNumber)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(order.formattedOrderDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    HStack(spacing: 4) {
                        Image(systemName: order.status.icon)
                            .font(.caption)
                        Text(order.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(order.status.color.opacity(0.1))
                    .foregroundColor(order.status.color)
                    .cornerRadius(8)
                }
                
                // Order Items Preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(order.totalItems) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(order.items.prefix(2).map { $0.productName }.joined(separator: ", "))
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    
                    if order.items.count > 2 {
                        Text("and \(order.items.count - 2) more...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Order Total
                HStack {
                    Text("Total: \(order.formattedTotalAmount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyOrdersView: View {
    let filter: OrderHistoryView.OrderStatusFilter
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bag")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all: return "No orders yet"
        case .active: return "No active orders"
        case .delivered: return "No delivered orders"
        case .cancelled: return "No cancelled orders"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all: return "Start shopping in the marketplace to see your orders here"
        case .active: return "You don't have any active orders at the moment"
        case .delivered: return "No orders have been delivered yet"
        case .cancelled: return "No orders have been cancelled"
        }
    }
}

struct OrderDetailView: View {
    let order: Order
    @ObservedObject var orderManager: OrderManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Order Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Order #\(order.orderNumber)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: order.status.icon)
                                Text(order.status.displayName)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(order.status.color.opacity(0.1))
                            .foregroundColor(order.status.color)
                            .cornerRadius(8)
                        }
                        
                        Text("Placed on \(order.formattedOrderDate)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let estimatedDelivery = order.formattedEstimatedDelivery {
                            Text("Estimated delivery: \(estimatedDelivery)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Order Items
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Items (\(order.items.count))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(order.items) { item in
                            OrderItemDetailRow(item: item)
                        }
                    }
                    
                    // Delivery Address
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Delivery Address")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(order.deliveryAddress.fullName)
                                .fontWeight(.medium)
                            Text(order.deliveryAddress.formattedAddress)
                                .foregroundColor(.secondary)
                            if !order.deliveryAddress.phoneNumber.isEmpty {
                                Text(order.deliveryAddress.phoneNumber)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Order Total
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Order Summary")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Items (\(order.totalItems))")
                                Spacer()
                                Text(order.formattedTotalAmount)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(order.formattedTotalAmount)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct OrderItemDetailRow: View {
    let item: OrderItem
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.productImageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .frame(width: 60, height: 60)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text("by \(item.seller)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(item.quantity) × \(item.formattedPrice)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(item.formattedTotalPrice)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    OrderHistoryView(orderManager: OrderManager(userId: "preview"))
}
