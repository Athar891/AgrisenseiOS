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
    @StateObject private var cartManager: CartManager
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
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        ForEach(filteredProducts) { product in
                            ProductCard(product: product, cartManager: cartManager)
                        }
                    }
                    .padding()
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Dismiss keyboard when tapping in scroll area
                                isSearchFieldFocused = false
                            }
                    )
                }
            }
            .navigationTitle(LocalizationManager.shared.localizedString(for: "marketplace_title"))
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
                AddProductView()
            }
            .sheet(isPresented: $showingCart) {
                CartView(cartManager: cartManager)
            }
            .onAppear {
                updateCartManager()
            }
            .onChange(of: userManager.currentUser?.id) { _ in
                updateCartManager()
            }
        }
    }
    
    private var filteredProducts: [Product] {
        var products = sampleProducts
        
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
    @FocusState.Binding var isSearchFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                                TextField(LocalizationManager.shared.localizedString(for: "Search products..."), text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isSearchFieldFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
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
        .padding(.top, 8)
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
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
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
    @State private var showingProductDetail = false
    
    var body: some View {
        Button(action: { showingProductDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Product Image
                if let mainImage = product.mainImage {
                    ProductImageView(url: mainImage.url, size: CGSize(width: UIScreen.main.bounds.width/2 - 32, height: 120))
                        .cornerRadius(12)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 120)
                        
                        Image(systemName: product.category.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    }
                }
                
                // Product Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(product.seller)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(product.formattedPrice)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
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
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingProductDetail) {
            ProductDetailView(product: product, cartManager: cartManager)
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
    let id = UUID()
    let name: String
    let description: String
    let price: Double
    let unit: String
    let category: ProductCategory
    let seller: String
    let rating: Double
    let stock: Int
    let location: String
    let images: [ProductImage]
    let mainImage: ProductImage?
    
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
                            
                            Text("by \(product.seller)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                HStack(alignment: .bottom, spacing: 4) {
                                    Text(product.formattedPrice)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    
                                    Text("per \(product.unit)")
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
                            
                            Text("\(product.stock) in stock")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        
                        // Quantity Selector
                        HStack {
                            Text("Quantity:")
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
                            Text("Add to Cart - ₹\(String(format: "%.2f", product.price * Double(quantity)))")
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
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(addedQuantity == 1 ? "Item Added to Cart!" : "Items Added to Cart!", isPresented: $showingAddedToCartAlert) {
                Button("OK") { }
            } message: {
                Text("\(addedQuantity) \(product.unit) of \(product.name) \(addedQuantity == 1 ? "has" : "have") been added to your cart.")
            }
            .alert("Cannot Add to Cart", isPresented: $showingStockAlert) {
                Button("OK") { }
            } message: {
                Text("Not enough stock available. Only \(product.stock - cartManager.getItemQuantity(for: product.id)) items remaining.")
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
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button(action: { showingImagePicker = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                    }
                }
                
                ForEach(images.indices, id: \.self) { index in
                    Image(uiImage: images[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            Button(action: { removeImage(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(4)
                            }
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(4),
                            alignment: .topTrailing
                        )
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
                .onChange(of: selectedImage) { newImage in
                    if let image = newImage {
                        images.append(image)
                        selectedImage = nil  // Reset for next selection
                    }
                }
        }
    }
    
    private func removeImage(at index: Int) {
        images.remove(at: index)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
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
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var productName = ""
    @State private var description = ""
    @State private var price = ""
    @State private var selectedCategory: ProductCategory = .vegetables
    @State private var stock = ""
    @State private var productImages: [UIImage] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("Product Images") {
                    ImagePickerView(images: $productImages)
                        .frame(height: 120)
                }
                
                Section("Product Information") {
                    TextField("Product Name", text: $productName)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ProductCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section("Pricing & Stock") {
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    
                    TextField("Stock Quantity", text: $stock)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save product logic here
                        dismiss()
                    }
                    .disabled(productName.isEmpty || price.isEmpty || stock.isEmpty)
                }
            }
        }
    }
}

#Preview {
    MarketplaceView()
        .environmentObject(UserManager())
}
