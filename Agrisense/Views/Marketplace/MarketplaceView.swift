//
//  MarketplaceView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - Keyboard Helper Extension
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct MarketplaceView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var cartManager: CartManager
    @StateObject private var productManager = ProductManager()
    @State private var searchText = ""
    @State private var selectedCategory: ProductCategory = .all
    @State private var showingFilters = false
    @State private var showingAddProduct = false
    @State private var showingCart = false
    @FocusState private var isSearchFieldFocused: Bool
    
    init() {
        // Initialize with a default user ID, will be updated when user changes
        self._cartManager = StateObject(wrappedValue: CartManager(userId: "default"))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                SearchFilterBar(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    showingFilters: $showingFilters,
                    showingAddProduct: $showingAddProduct,
                    isSearchFieldFocused: $isSearchFieldFocused
                )
                
                // Category Pills
                CategoryPillsView(selectedCategory: $selectedCategory)
                
                // Product Grid
                ScrollView {
                    if filteredProducts.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: userManager.currentUser?.userType == .seller ? "plus.circle" : "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text(userManager.currentUser?.userType == .seller ? 
                                 "No products yet" : "No products found")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            Text(userManager.currentUser?.userType == .seller ? 
                                 "Add your first product to start selling" : "Try adjusting your search or filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            if userManager.currentUser?.userType == .seller {
                                Button(action: { showingAddProduct = true }) {
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
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            ForEach(filteredProducts) { product in
                                ProductCard(product: product, cartManager: cartManager, productManager: productManager)
                            }
                        }
                        .padding()
                    }
                }
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Dismiss keyboard when tapping in scroll area
                            isSearchFieldFocused = false
                        }
                )
            }
            .navigationTitle(userManager.currentUser?.userType == .seller ? 
                           localizationManager.localizedString(for: "my_products_title") : 
                           localizationManager.localizedString(for: "marketplace_title"))
            .navigationBarTitleDisplayMode(.large)
            .background(
                // Invisible background to catch taps
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Dismiss keyboard when tapping outside text field
                        isSearchFieldFocused = false
                    }
            )
            .onDisappear {
                // Dismiss keyboard when leaving this view
                isSearchFieldFocused = false
            }
            .onChange(of: isSearchFieldFocused) { focused in
                if !focused {
                    // Additional fallback to ensure keyboard is dismissed
                    self.hideKeyboard()
                }
            }
            .onChange(of: appState.selectedTab) { newTab in
                // Dismiss keyboard when switching away from market tab
                if newTab != .market {
                    isSearchFieldFocused = false
                    self.hideKeyboard()
                }
            }
            .toolbar {
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
                loadProducts()
            }
            .onChange(of: userManager.currentUser?.id) { _ in
                updateCartManager()
                loadProducts()
            }
        }
    }
    
    private func loadProducts() {
        Task {
            do {
                try await productManager.fetchProducts()
            } catch {
                // Failed to load products
            }
        }
    }
    
    private var filteredProducts: [Product] {
        var products = productManager.products
        
        // Filter by user type - sellers only see their own products
        if userManager.currentUser?.userType == .seller {
            let currentSellerId = userManager.currentUser?.id ?? ""
            products = products.filter { $0.sellerId == currentSellerId }
        }
        // Farmers see all products
        
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

struct SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedCategory: ProductCategory
    @Binding var showingFilters: Bool
    @Binding var showingAddProduct: Bool
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
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
                
                Button(action: { showingFilters = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.green)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                if userManager.currentUser?.userType == .seller {
                    Button(action: { showingAddProduct = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct CategoryPillsView: View {
    @Binding var selectedCategory: ProductCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ProductCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct CategoryPill: View {
    let category: ProductCategory
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        Button(action: action) {
            // Prefer localized category name, fall back to displayName
            let title = localizationManager.localizedString(for: category.localizationKey)
            Text(title.isEmpty ? category.displayName : title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.systemGray6))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProductCard: View {
    let product: Product
    let cartManager: CartManager
    let productManager: ProductManager
    @State private var showingProductDetail = false
    @State private var showingEditProduct = false
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
    private var isOwnProduct: Bool {
        userManager.currentUser?.userType == .seller && 
        product.sellerId == (userManager.currentUser?.id ?? "seller_001")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Product Image
                if let mainImage = product.mainImage {
                    ProductImageView(url: mainImage.url, size: CGSize(width: UIScreen.main.bounds.width/2 - 32, height: 120))
                        .cornerRadius(12)
                        .overlay(
                            // Loading overlay when deleting
                            isDeleting ? Color.black.opacity(0.5) : Color.clear
                        )
                        .overlay(
                            isDeleting ? 
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            : nil
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 120)
                            .overlay(
                                // Loading overlay when deleting
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
                if isOwnProduct {
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
                    
                    if isOwnProduct {
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
                    Text(product.formattedPrice)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if !isOwnProduct {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", product.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onTapGesture {
            if isOwnProduct {
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
                deleteProduct()
            }
        } message: {
            Text("Are you sure you want to delete '\(product.name)'? This action cannot be undone.")
        }
    }
    
    private func deleteProduct() {
        isDeleting = true
        
        Task {
            do {
                try await productManager.deleteProduct(productId: product.id)
                
                // Refresh products list
                try await productManager.fetchProducts()
                
                await MainActor.run {
                    isDeleting = false
                }
                
                // Product deleted successfully
            } catch {
                await MainActor.run {
                    isDeleting = false
                }
                
                // Failed to delete product
            }
        }
    }
}

// MARK: - Models

enum ProductCategory: String, CaseIterable {
    case all = "all"
    case vegetables = "vegetables"
    case fruits = "fruits"
    case grains = "grains"
    case dairy = "dairy"
    case meat = "meat"
    case equipment = "equipment"
    case seeds = "seeds"
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .vegetables:
            return "Vegetables"
        case .fruits:
            return "Fruits"
        case .grains:
            return "Grains"
        case .dairy:
            return "Dairy"
        case .meat:
            return "Meat"
        case .equipment:
            return "Equipment"
        case .seeds:
            return "Seeds"
        }
    }

    var localizationKey: String {
        switch self {
        case .all: return "category_all"
        case .vegetables: return "category_vegetables"
        case .fruits: return "category_fruits"
        case .grains: return "category_grains"
        case .dairy: return "category_dairy"
        case .meat: return "category_meat"
        case .equipment: return "category_equipment"
        case .seeds: return "category_seeds"
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "square.grid.2x2"
        case .vegetables:
            return "leaf.fill"
        case .fruits:
            return "applelogo"
        case .grains:
            return "circle.fill"
        case .dairy:
            return "drop.fill"
        case .meat:
            return "flame.fill"
        case .equipment:
            return "wrench.and.screwdriver.fill"
        case .seeds:
            return "leaf.circle.fill"
        }
    }
}

struct Product: Identifiable, Equatable {
    let id: String // Changed from UUID to String for Firestore compatibility
    let name: String
    let description: String
    let price: Double
    let unit: String
    let category: ProductCategory
    let seller: String
    let sellerId: String  // Added seller ID for filtering
    let rating: Double
    let stock: Int
    let location: String
    let images: [ProductImage]
    let mainImage: ProductImage?
    
    // Initialize with UUID as default for new products
    init(id: String = UUID().uuidString, name: String, description: String, price: Double, unit: String, category: ProductCategory, seller: String, sellerId: String, rating: Double, stock: Int, location: String, images: [ProductImage], mainImage: ProductImage?) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.unit = unit
        self.category = category
        self.seller = seller
        self.sellerId = sellerId
        self.rating = rating
        self.stock = stock
        self.location = location
        self.images = images
        self.mainImage = mainImage
    }
    
    var formattedPrice: String {
        CurrencyFormatter.format(price: price)
    }
    
    var formattedPriceWithUnit: String {
        "\(CurrencyFormatter.format(price: price)) per \(unit)"
    }
}

struct ProductImage: Identifiable, Equatable {
    let id = UUID()
    let url: String
    let description: String?
    
    static let placeholder = "https://placehold.co/400x400/EAEAEA/7AB356?text=Product+Image"
}

struct ProductImageView: View {
    let url: String
    let size: CGSize
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: size.width, height: size.height)
                    .background(Color(.systemGray6))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: size.width * 0.3))
                    .foregroundColor(.gray)
                    .frame(width: size.width, height: size.height)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            @unknown default:
                EmptyView()
            }
        }
    }
}

// MARK: - Sample Data

let sampleProducts = [
    Product(
        name: "Fresh Tomatoes",
        description: "Organic red tomatoes, freshly harvested. Our tomatoes are grown without pesticides and picked at peak ripeness for the best flavor.",
        price: 20.00,
        unit: "kg",
        category: .vegetables,
        seller: "Green Valley Farm",
        sellerId: "seller_001",
        rating: 4.5,
        stock: 50,
        location: "California",
        images: [
            ProductImage(url: "https://images.unsplash.com/photo-1592924357228-91a4daadcfea", description: "Fresh organic tomatoes"),
            ProductImage(url: "https://images.unsplash.com/photo-1518977822534-7049a61ee0c2", description: "Tomatoes on the vine")
        ],
        mainImage: ProductImage(url: "https://images.unsplash.com/photo-1592924357228-91a4daadcfea", description: "Fresh organic tomatoes")
    ),
    Product(
        name: "Sweet Corn",
        description: "Sweet yellow corn, perfect for grilling. Non-GMO corn picked fresh from our family farm.",
        price: 14.00,
        unit: "dozen",
        category: .vegetables,
        seller: "Sunshine Farms",
        sellerId: "seller_002",
        rating: 4.8,
        stock: 100,
        location: "Iowa",
        images: [
            ProductImage(url: "https://images.unsplash.com/photo-1551754655-cd27e38d2076", description: "Fresh sweet corn"),
            ProductImage(url: "https://images.unsplash.com/photo-1562599938-e6fe2a67574b", description: "Corn field")
        ],
        mainImage: ProductImage(url: "https://images.unsplash.com/photo-1551754655-cd27e38d2076", description: "Fresh sweet corn")
    ),
    Product(
        name: "Organic Apples",
        description: "Crisp red apples, pesticide-free. Handpicked from our sustainable orchard.",
        price: 39.00,
        unit: "kg",
        category: .fruits,
        seller: "Apple Orchard Co",
        sellerId: "seller_003",
        rating: 4.6,
        stock: 75,
        location: "Washington",
        images: [
            ProductImage(url: "https://images.unsplash.com/photo-1570913149827-d2ac84ab3f9a", description: "Fresh organic apples"),
            ProductImage(url: "https://images.unsplash.com/photo-1579613832125-5d34a13ffe2a", description: "Apple orchard")
        ],
        mainImage: ProductImage(url: "https://images.unsplash.com/photo-1570913149827-d2ac84ab3f9a", description: "Fresh organic apples")
    ),
    Product(
        name: "Whole Wheat",
        description: "Premium stone-ground whole wheat flour. Perfect for baking bread and pastries.",
        price: 49.00,
        unit: "kg",
        category: .grains,
        seller: "Golden Grain Mill",
        sellerId: "seller_004",
        rating: 4.7,
        stock: 200,
        location: "Kansas",
        images: [
            ProductImage(url: "https://images.unsplash.com/photo-1568254183919-78a4f43a2877", description: "Whole wheat flour"),
            ProductImage(url: "https://images.unsplash.com/photo-1509440159596-0249088772ff", description: "Wheat field")
        ],
        mainImage: ProductImage(url: "https://images.unsplash.com/photo-1568254183919-78a4f43a2877", description: "Whole wheat flour")
    ),
    Product(
        name: "Fresh Milk",
        description: "Farm-fresh whole milk from grass-fed cows. Pasteurized and bottled daily.",
        price: 34.00,
        unit: "liter",
        category: .dairy,
        seller: "Dairy Delight",
        sellerId: "seller_005",
        rating: 4.4,
        stock: 30,
        location: "Wisconsin",
        images: [
            ProductImage(url: "https://images.unsplash.com/photo-1550583724-b2692b85b150", description: "Fresh milk bottles"),
            ProductImage(url: "https://images.unsplash.com/photo-1601368634584-6a95747de5dc", description: "Dairy farm")
        ],
        mainImage: ProductImage(url: "https://images.unsplash.com/photo-1550583724-b2692b85b150", description: "Fresh milk bottles")
    ),
    Product(
        name: "Garden Seeds",
        description: "Mixed vegetable seeds pack. Non-GMO, heirloom varieties for your home garden.",
        price: 80.00,
        unit: "pack",
        category: .seeds,
        seller: "Seed Co",
        sellerId: "seller_006",
        rating: 4.9,
        stock: 150,
        location: "Oregon",
        images: [
            ProductImage(url: "https://images.unsplash.com/photo-1534710961216-75c88202f43e", description: "Variety of seeds"),
            ProductImage(url: "https://images.unsplash.com/photo-1523348837708-15d4a09cfac2", description: "Sprouting seeds")
        ],
        mainImage: ProductImage(url: "https://images.unsplash.com/photo-1534710961216-75c88202f43e", description: "Variety of seeds")
    )
]

struct ProductDetailView: View {
    let product: Product
    let cartManager: CartManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var quantity = 1
    @State private var addedQuantity = 1 // Store the quantity that was actually added
    @State private var showingAddedToCartAlert = false
    @State private var showingStockAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Product Images Gallery
                    TabView {
                        ForEach(product.images) { image in
                            ProductImageView(url: image.url, size: CGSize(width: UIScreen.main.bounds.width - 32, height: 250))
                        }
                    }
                    .frame(height: 250)
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Product Info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(product.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(String(format: localizationManager.localizedString(for: "by_seller"), product.seller))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                HStack(alignment: .bottom, spacing: 4) {
                                    Text(product.formattedPrice)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    
                                    Text(String(format: localizationManager.localizedString(for: "per_unit"), product.unit))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1f", product.rating))
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        
                        // Description
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Location and Stock
                        HStack {
                            Label(product.location, systemImage: "location.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(String(format: localizationManager.localizedString(for: "in_stock"), product.stock))
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        
                        // Quantity Selector
                        HStack {
                            Text(localizationManager.localizedString(for: "quantity_label"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            HStack {
                                Button(action: { if quantity > 1 { quantity -= 1 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.green)
                                }
                                
                                Text("\(quantity)")
                                    .font(.headline)
                                    .frame(minWidth: 40)
                                
                                Button(action: { quantity += 1 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        
                        // Add to Cart Button
                        Button(action: addToCart) {
                            Text(String(format: localizationManager.localizedString(for: "add_to_cart_with_price"), String(format: "%.2f", product.price * Double(quantity))))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(canAddToCart ? Color.green : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(!canAddToCart)
                    }
                    .padding()
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "product_details_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: "done")) {
                        dismiss()
                    }
                }
            }
            .alert(addedQuantity == 1 ? localizationManager.localizedString(for: "item_added_single") : localizationManager.localizedString(for: "item_added_plural"), isPresented: $showingAddedToCartAlert) {
                Button(localizationManager.localizedString(for: "ok")) { }
            } message: {
                Text(String(format: localizationManager.localizedString(for: "items_added_message"), addedQuantity, product.unit, product.name, addedQuantity == 1 ? localizationManager.localizedString(for: "has") : localizationManager.localizedString(for: "have")))
            }
            .alert(localizationManager.localizedString(for: "cannot_add_to_cart"), isPresented: $showingStockAlert) {
                Button(localizationManager.localizedString(for: "ok")) { }
            } message: {
                Text(String(format: localizationManager.localizedString(for: "not_enough_stock"), product.stock - cartManager.getItemQuantity(for: product.id)))
            }
        }
    }
    
    private var canAddToCart: Bool {
        return cartManager.canAddToCart(product: product, additionalQuantity: quantity)
    }
    
    private func addToCart() {
        if cartManager.addToCart(product: product, quantity: quantity) {
            addedQuantity = quantity // Store the quantity before resetting
            showingAddedToCartAlert = true
            // Reset quantity to 1 after successful add
            quantity = 1
        } else {
            showingStockAlert = true
        }
    }
}

struct ImagePickerView: View {
    @Binding var images: [UIImage]
    @Binding var imageUrls: [String] // New binding for uploaded URLs
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showingAlert = false
    let productManager: ProductManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Add button - only show if less than 5 images
                if images.count < 5 {
                    Button(action: { 
                        // Add image button tapped
                        showingImagePicker = true 
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(width: 100, height: 100)
                            
                            if isUploading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.green)
                            } else {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                                    Text("Add Image")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    .disabled(isUploading)
                }
                
                ForEach(images.indices, id: \.self) { index in
                    ZStack {
                        Image(uiImage: images[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Show upload status indicator
                        if index < imageUrls.count && !imageUrls[index].isEmpty {
                            // Successfully uploaded
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .padding(4)
                                }
                            }
                        } else if index < imageUrls.count {
                            // Uploading
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(4)
                                }
                            }
                        }
                        
                        // Remove button
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { removeImage(at: index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(4)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                print("🖼️ Image selected: \(image.size)")
                addImageAndUpload(image)
                selectedImage = nil  // Reset for next selection
            }
        }
        .alert("Upload Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(uploadError ?? "Failed to upload image")
        }
    }
    
    private func addImageAndUpload(_ image: UIImage) {
        // Limit to 5 images
        guard images.count < 5 else {
            uploadError = "You can only add up to 5 images per product."
            showingAlert = true
            return
        }
        
        images.append(image)
        let imageIndex = images.count - 1
        
        // Ensure imageUrls array is the same size as images array
        while imageUrls.count <= imageIndex {
            imageUrls.append("")
        }
        
        // Upload to Cloudinary
        Task {
            isUploading = true
            do {
                let imageUrl = try await productManager.uploadProductImage(image)
                await MainActor.run {
                    if imageIndex < imageUrls.count {
                        imageUrls[imageIndex] = imageUrl
                    }
                }
                print("✅ Product image uploaded successfully: \(imageUrl)")
            } catch {
                await MainActor.run {
                    uploadError = error.localizedDescription
                    showingAlert = true
                    // Remove the image that failed to upload
                    removeImage(at: imageIndex)
                }
                print("❌ Failed to upload product image: \(error)")
            }
            await MainActor.run {
                isUploading = false
            }
        }
    }
    
    private func removeImage(at index: Int) {
        images.remove(at: index)
        if index < imageUrls.count {
            imageUrls.remove(at: index)
        }
    }
}

// Enhanced ImagePicker with completion handler
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    let onImageSelected: ((UIImage?) -> Void)?
    
    init(image: Binding<UIImage?>, onImageSelected: ((UIImage?) -> Void)? = nil) {
        self._image = image
        self.onImageSelected = onImageSelected
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.image = selectedImage
                parent.onImageSelected?(selectedImage)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var userManager: UserManager
    @State private var productName = ""
    @State private var description = ""
    @State private var price = ""
    @State private var unit = ""
    @State private var selectedCategory: ProductCategory = .vegetables
    @State private var stock = ""
    @State private var location = ""
    @State private var productImages: [UIImage] = []
    @State private var productImageUrls: [String] = []
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showingAlert = false
    @State private var showingSuccess = false
    
    let productManager: ProductManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(localizationManager.localizedString(for: "product_images_section")) {
                    ImagePickerView(
                        images: $productImages,
                        imageUrls: $productImageUrls,
                        productManager: productManager
                    )
                    .frame(height: 120)
                    
                    if !productImages.isEmpty {
                        Text("^[\(productImages.count) image](inflect: true) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if productImages.count < 5 {
                        Text("You can add up to 5 images")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(localizationManager.localizedString(for: "product_information_section")) {
                    TextField(localizationManager.localizedString(for: "product_name_placeholder"), text: $productName)
                    TextField(localizationManager.localizedString(for: "description_placeholder"), text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker(localizationManager.localizedString(for: "category_picker"), selection: $selectedCategory) {
                        ForEach(ProductCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section(localizationManager.localizedString(for: "pricing_stock_section")) {
                    HStack {
                        TextField(localizationManager.localizedString(for: "price_placeholder"), text: $price)
                            .keyboardType(.decimalPad)
                        
                        Text("per")
                            .foregroundColor(.secondary)
                        
                        TextField("unit (kg, dozen, etc.)", text: $unit)
                            .textCase(.lowercase)
                    }
                    
                    TextField(localizationManager.localizedString(for: "stock_quantity_placeholder"), text: $stock)
                        .keyboardType(.numberPad)
                    
                    TextField("Location (city, state)", text: $location)
                }
                
                if isSaving {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Saving product...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "add_product_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString(for: "cancel")) {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: "save")) {
                        saveProduct()
                    }
                    .disabled(productName.isEmpty || price.isEmpty || stock.isEmpty || unit.isEmpty || location.isEmpty || isSaving || productImages.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(saveError ?? "Failed to save product")
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Product added successfully!")
            }
        }
    }
    
    private func saveProduct() {
        // Validate that all uploaded images have URLs
        guard !productImages.isEmpty else {
            saveError = "Please add at least one product image."
            showingAlert = true
            return
        }
        
        guard productImageUrls.filter({ !$0.isEmpty }).count == productImages.count else {
            saveError = "Please wait for all images to finish uploading before saving."
            showingAlert = true
            return
        }
        
        // Validate price
        guard let priceValue = Double(price), priceValue > 0 else {
            saveError = "Please enter a valid price."
            showingAlert = true
            return
        }
        
        // Validate stock
        guard let stockValue = Int(stock), stockValue >= 0 else {
            saveError = "Please enter a valid stock quantity."
            showingAlert = true
            return
        }
        
        // Ensure user is logged in
        guard let currentUser = userManager.currentUser else {
            saveError = "You must be logged in to add products."
            showingAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                let productId = try await productManager.saveProduct(
                    name: productName,
                    description: description,
                    price: priceValue,
                    unit: unit,
                    category: selectedCategory.rawValue,
                    stock: stockValue,
                    location: location,
                    imageUrls: productImageUrls.filter { !$0.isEmpty },
                    sellerId: currentUser.id,
                    sellerName: currentUser.name
                )
                
                print("✅ Product saved successfully with ID: \(productId)")
                
                // Refresh products list
                try await productManager.fetchProducts()
                
                await MainActor.run {
                    isSaving = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = "Failed to save product: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Edit Product View

struct EditProductView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var userManager: UserManager
    
    @State private var editedName: String
    @State private var editedDescription: String
    @State private var editedPrice: String
    @State private var editedStock: String
    @State private var editedCategory: ProductCategory
    @State private var editedUnit: String
    @State private var editedLocation: String
    
    // Image editing support
    @State private var currentImages: [UIImage] = []
    @State private var currentImageUrls: [String] = []
    @State private var newImages: [UIImage] = []
    @State private var newImageUrls: [String] = []
    @State private var showingImagePicker = false
    
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let productManager: ProductManager
    
    init(product: Product, productManager: ProductManager) {
        self.product = product
        self.productManager = productManager
        _editedName = State(initialValue: product.name)
        _editedDescription = State(initialValue: product.description)
        _editedPrice = State(initialValue: String(format: "%.2f", product.price))
        _editedStock = State(initialValue: String(product.stock))
        _editedCategory = State(initialValue: product.category)
        _editedUnit = State(initialValue: product.unit)
        _editedLocation = State(initialValue: product.location)
        _currentImageUrls = State(initialValue: product.images.map { $0.url })
    }
    
    var allImageUrls: [String] {
        return currentImageUrls + newImageUrls.filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Product Images Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Product Images")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        // Current Images
                        if !currentImageUrls.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(currentImageUrls.indices, id: \.self) { index in
                                        ZStack {
                                            ProductImageView(url: currentImageUrls[index], size: CGSize(width: 100, height: 100))
                                                .cornerRadius(12)
                                            
                                            // Remove button
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    Button(action: { removeCurrentImage(at: index) }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.white)
                                                            .background(Color.black.opacity(0.6))
                                                            .clipShape(Circle())
                                                            .padding(4)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // New Images
                        if !newImages.isEmpty {
                            Text("New Images")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(newImages.indices, id: \.self) { index in
                                        ZStack {
                                            Image(uiImage: newImages[index])
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            
                                            // Upload status indicator
                                            if index < newImageUrls.count && !newImageUrls[index].isEmpty {
                                                VStack {
                                                    Spacer()
                                                    HStack {
                                                        Spacer()
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.green)
                                                            .background(Color.white)
                                                            .clipShape(Circle())
                                                            .padding(4)
                                                    }
                                                }
                                            }
                                            
                                            // Remove button
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    Button(action: { removeNewImage(at: index) }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.white)
                                                            .background(Color.black.opacity(0.6))
                                                            .clipShape(Circle())
                                                            .padding(4)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Add Image Button
                        if allImageUrls.count < 5 {
                            Button(action: { showingImagePicker = true }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add Image")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        
                        Text("You can have up to 5 images total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Product Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Product Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Product Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter product name", text: $editedName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Enter product description", text: $editedDescription, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Price")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("0.00", text: $editedPrice)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Unit")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("kg, liter, etc.", text: $editedUnit)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Category")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Category", selection: $editedCategory) {
                                ForEach(ProductCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                                    Text(category.displayName).tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stock Quantity")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("0", text: $editedStock)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Location")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("City, State", text: $editedLocation)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    
                    // Save Button
                    Button(action: saveChanges) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSaving ? "Saving..." : "Save Changes")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    .disabled(isSaving || editedName.isEmpty || editedDescription.isEmpty || allImageUrls.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Edit Product", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: .constant(nil)) { image in
                    if let image = image {
                        addNewImage(image)
                    }
                }
            }
        }
    }
    
    private func removeCurrentImage(at index: Int) {
        currentImageUrls.remove(at: index)
    }
    
    private func removeNewImage(at index: Int) {
        newImages.remove(at: index)
        if index < newImageUrls.count {
            newImageUrls.remove(at: index)
        }
    }
    
    private func addNewImage(_ image: UIImage) {
        guard allImageUrls.count < 5 else { return }
        
        newImages.append(image)
        newImageUrls.append("") // Placeholder until upload completes
        
        let imageIndex = newImages.count - 1
        
        // Upload to Cloudinary
        Task {
            do {
                let imageUrl = try await productManager.uploadProductImage(image)
                await MainActor.run {
                    if imageIndex < newImageUrls.count {
                        newImageUrls[imageIndex] = imageUrl
                    }
                }
                print("✅ New product image uploaded successfully: \(imageUrl)")
            } catch {
                await MainActor.run {
                    // Remove the image that failed to upload
                    if imageIndex < newImages.count {
                        newImages.remove(at: imageIndex)
                    }
                    if imageIndex < newImageUrls.count {
                        newImageUrls.remove(at: imageIndex)
                    }
                    alertMessage = "Failed to upload image: \(error.localizedDescription)"
                    showingAlert = true
                }
                print("❌ Failed to upload new product image: \(error)")
            }
        }
    }
    
    private func saveChanges() {
        // Validate inputs
        guard !editedName.isEmpty, !editedDescription.isEmpty else {
            alertMessage = "Please fill in all required fields."
            showingAlert = true
            return
        }
        
        guard let price = Double(editedPrice), price > 0 else {
            alertMessage = "Please enter a valid price."
            showingAlert = true
            return
        }
        
        guard let stock = Int(editedStock), stock >= 0 else {
            alertMessage = "Please enter a valid stock quantity."
            showingAlert = true
            return
        }
        
        guard allImageUrls.count > 0 else {
            alertMessage = "Please add at least one product image."
            showingAlert = true
            return
        }
        
        // Check if new images are still uploading
        let pendingUploads = newImageUrls.filter { $0.isEmpty }
        guard pendingUploads.isEmpty else {
            alertMessage = "Please wait for all images to finish uploading."
            showingAlert = true
            return
        }
        
        // Verify user owns this product
        guard let currentUser = userManager.currentUser,
              currentUser.id == product.sellerId else {
            alertMessage = "You can only edit your own products."
            showingAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                try await productManager.updateProduct(
                    productId: product.id,
                    name: editedName,
                    description: editedDescription,
                    price: price,
                    unit: editedUnit,
                    category: editedCategory.rawValue,
                    stock: stock,
                    location: editedLocation,
                    imageUrls: allImageUrls
                )
                
                // Refresh products list
                try await productManager.fetchProducts()
                
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Product updated successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Failed to update product: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    MarketplaceView()
    .environmentObject(UserManager())
    .environmentObject(LocalizationManager.shared)
}
