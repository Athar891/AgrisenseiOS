//
//  EnhancedMarketplaceView.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - Enhanced Marketplace View with Network Monitoring

struct EnhancedMarketplaceView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var cartManager: CartManager
    @StateObject private var productManager = ProductManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var retryManager = RetryManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory = .all
    @State private var showingFilters = false
    @State private var showingAddProduct = false
    @State private var showingCart = false
    @State private var lastSyncTime: Date?
    @FocusState private var isSearchFieldFocused: Bool
    
    init() {
        // Initialize with a default user ID, will be updated when user changes
        self._cartManager = StateObject(wrappedValue: CartManager(userId: "default"))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Network Status Indicator
                if !networkMonitor.status.isConnected {
                    NetworkStatusBanner()
                }
                
                // Search and Filter Bar
                EnhancedSearchFilterBar(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    showingFilters: $showingFilters,
                    showingAddProduct: $showingAddProduct,
                    isSearchFieldFocused: $isSearchFieldFocused
                )
                
                // Category Pills
                CategoryPillsView(selectedCategory: $selectedCategory)
                
                // Product Grid with Network-Aware Loading
                ScrollView {
                    if productManager.isLoading {
                        // Show skeleton while loading
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(0..<6, id: \.self) { _ in
                                ProductCardSkeleton()
                            }
                        }
                        .padding()
                    } else if filteredProducts.isEmpty {
                        // Empty state with network-aware messaging
                        EmptyStateView()
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(filteredProducts) { product in
                                EnhancedProductCard(
                                    product: product,
                                    cartManager: cartManager,
                                    productManager: productManager
                                )
                            }
                        }
                        .padding()
                    }
                    
                    // Sync Status Footer
                    SyncStatusFooter(lastSyncTime: lastSyncTime)
                }
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isSearchFieldFocused = false
                        }
                )
                .refreshable {
                    await refreshProducts()
                }
            }
            .navigationTitle(userManager.currentUser?.userType == .seller ? 
                           localizationManager.localizedString(for: "my_products_title") : 
                           localizationManager.localizedString(for: "marketplace_title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NetworkStatusIndicator(compact: true)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCart = true }) {
                        ZStack {
                            Image(systemName: "cart")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            if cartManager.currentCart.totalItems > 0 {
                                Text("\(cartManager.currentCart.totalItems)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView(productManager: productManager)
            }
            .sheet(isPresented: $showingCart) {
                CartView(cartManager: cartManager)
            }
            .onAppear {
                updateCartManager()
                loadProductsWithRetry()
            }
            .onChange(of: userManager.currentUser?.id) { _, _ in
                updateCartManager()
                loadProductsWithRetry()
            }
            .onChange(of: networkMonitor.status) { _, newStatus in
                if newStatus.isConnected && lastSyncTime == nil {
                    // Connection restored, sync data
                    loadProductsWithRetry()
                }
            }
        }
    }
    
    // MARK: - Network-Aware Data Loading
    
    private func loadProductsWithRetry() {
        Task {
            let result = await retryManager.retryWhenOnline(
                operation: {
                    try await productManager.fetchProducts()
                    return "Products loaded successfully"
                },
                configuration: .default,
                operationId: "load_products"
            )
            
            await MainActor.run {
                switch result {
                case .success:
                    lastSyncTime = Date()
                case .failure(let error, _):
                    // Handle error - could show error banner
                    print("Failed to load products: \(error)")
                case .cancelled:
                    break
                }
            }
        }
    }
    
    private func refreshProducts() async {
        if networkMonitor.status.isConnected {
            await loadProductsWithRetry()
        } else {
            // Show offline message
            print("Cannot refresh while offline")
        }
    }
    
    private var filteredProducts: [Product] {
        var products = productManager.products
        
        // Filter by user type - sellers only see their own products
        if userManager.currentUser?.userType == .seller {
            let currentSellerId = userManager.currentUser?.id ?? ""
            products = products.filter { $0.sellerId == currentSellerId }
        }
        
        if !searchText.isEmpty {
            products = products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if selectedCategory != .all {
            products = products.filter { $0.category == selectedCategory }
        }
        
        return products
    }
    
    private func updateCartManager() {
        if let userId = userManager.currentUser?.id {
            cartManager.switchUser(to: userId)
        }
    }
}

// MARK: - Network Status Banner

struct NetworkStatusBanner: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: networkMonitor.status.icon)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(networkMonitor.status.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(localizationManager.localizedString(for: "offline_cached_data"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            if networkMonitor.status == .disconnected {
                Button(action: {
                    Task {
                        await networkMonitor.retryConnection()
                    }
                }) {
                    Text("Retry")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(networkMonitor.status.color)
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.status)
    }
}

// MARK: - Enhanced Search Filter Bar

struct EnhancedSearchFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedCategory: ProductCategory
    @Binding var showingFilters: Bool
    @Binding var showingAddProduct: Bool
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @FocusState.Binding var isSearchFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField(localizationManager.localizedString(for: "search_products_placeholder"), text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isSearchFieldFocused)
                        .disabled(!networkMonitor.status.isConnected && searchText.isEmpty)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button(localizationManager.localizedString(for: "done")) {
                                    isSearchFieldFocused = false
                                }
                                .foregroundColor(.green)
                            }
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(networkMonitor.status.isConnected ? Color.clear : Color.orange.opacity(0.5), lineWidth: 1)
                )
                
                Button(action: { showingFilters = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .disabled(!networkMonitor.status.isConnected)
                
                if userManager.currentUser?.userType == .seller {
                    Button(action: { showingAddProduct = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(networkMonitor.status.isConnected ? Color.green : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!networkMonitor.status.isConnected)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

// MARK: - Enhanced Product Card

struct EnhancedProductCard: View {
    let product: Product
    let cartManager: CartManager
    let productManager: ProductManager
    @State private var showingProductDetail = false
    @State private var showingEditProduct = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var retryManager = RetryManager.shared
    
    private var isOwnProduct: Bool {
        userManager.currentUser?.userType == .seller && 
        product.sellerId == (userManager.currentUser?.id ?? "seller_001")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Product Image with Network Status
                if let mainImage = product.mainImage {
                    ProductImageView(url: mainImage.url, size: CGSize(width: UIScreen.main.bounds.width/2 - 32, height: 120))
                        .cornerRadius(12)
                        .overlay(
                            Group {
                                if isDeleting {
                                    Color.black.opacity(0.5)
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(1.2)
                                        )
                                } else if !networkMonitor.status.isConnected {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Image(systemName: "wifi.slash")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                            Text("Cached")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(8)
                                        .padding(8)
                                    }
                                }
                            }
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 120)
                            .overlay(
                                isDeleting ? Color.black.opacity(0.5) : Color.clear
                            )
                        
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: product.category.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Edit and Delete buttons for sellers on their own products
                if isOwnProduct && networkMonitor.status.isConnected {
                    HStack(spacing: 8) {
                        Button(action: { showingDeleteAlert = true }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        .disabled(isDeleting)
                        
                        Button(action: { showingEditProduct = true }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                        .disabled(isDeleting)
                    }
                    .padding(8)
                }
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if !isOwnProduct {
                        Spacer()
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", product.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Spacer()
                        Text("Stock: \(product.stock)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                
                if !isOwnProduct {
                    Text(product.seller)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.formattedPrice)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("per \(product.unit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .opacity(networkMonitor.status.isConnected ? 1.0 : 0.8)
        .onTapGesture {
            if isOwnProduct && networkMonitor.status.isConnected {
                showingEditProduct = true
            } else {
                showingProductDetail = true
            }
        }
        .sheet(isPresented: $showingProductDetail) {
            ProductDetailView(product: product, cartManager: cartManager)
        }
        .sheet(isPresented: $showingEditProduct) {
            EditProductView(product: product, productManager: productManager)
        }
        .alert("Delete Product", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProductWithRetry()
            }
        } message: {
            Text("Are you sure you want to delete '\(product.name)'? This action cannot be undone.")
        }
    }
    
    private func deleteProductWithRetry() {
        isDeleting = true
        
        Task {
            let result = await retryManager.retryWhenOnline(
                operation: {
                    try await productManager.deleteProduct(productId: product.id)
                    try await productManager.fetchProducts()
                    return "Product deleted successfully"
                },
                configuration: .default,
                operationId: "delete_product_\(product.id)"
            )
            
            await MainActor.run {
                isDeleting = false
                
                switch result {
                case .success:
                    // Product deleted successfully
                    break
                case .failure(let error, _):
                    // Show error to user
                    print("Failed to delete product: \(error)")
                case .cancelled:
                    break
                }
            }
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: networkMonitor.status.isConnected ? 
                  (userManager.currentUser?.userType == .seller ? "plus.circle" : "magnifyingglass") : 
                  "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(emptyStateTitle)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if networkMonitor.status.isConnected && userManager.currentUser?.userType == .seller {
                Button(action: { }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Product")
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 100)
    }
    
    private var emptyStateTitle: String {
        if !networkMonitor.status.isConnected {
            return "You're Offline"
        } else if userManager.currentUser?.userType == .seller {
            return "No products yet"
        } else {
            return "No products found"
        }
    }
    
    private var emptyStateMessage: String {
        if !networkMonitor.status.isConnected {
            return "Connect to the internet to browse products and sync your data"
        } else if userManager.currentUser?.userType == .seller {
            return "Add your first product to start selling"
        } else {
            return "Try adjusting your search or filters"
        }
    }
}

// MARK: - Sync Status Footer

struct SyncStatusFooter: View {
    let lastSyncTime: Date?
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: networkMonitor.status.isConnected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(networkMonitor.status.isConnected ? .green : .orange)
                    .font(.caption)
                
                if let lastSync = lastSyncTime {
                    Text("Last synced \(lastSync, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if networkMonitor.status.isConnected {
                    Text("Syncing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(localizationManager.localizedString(for: "offline_cached_data"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            NetworkStatusIndicator(compact: true)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    EnhancedMarketplaceView()
        .environmentObject(UserManager())
        .environmentObject(AppState())
        .environmentObject(LocalizationManager.shared)
}