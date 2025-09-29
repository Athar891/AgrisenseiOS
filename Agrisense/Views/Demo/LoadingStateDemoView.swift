//
//  LoadingStateDemoView.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import SwiftUI

// MARK: - Loading State Demo View

struct LoadingStateDemoView: View {
    @StateObject private var loadingManager = LoadingStateManager.shared
    @State private var products: [String] = []
    @State private var crops: [String] = []
    @State private var buttonState: LoadingButtonState = .idle
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Loading State System Demo")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    
                    // Loading State Manager Demo
                    loadingStateManagerSection
                    
                    // Skeleton Views Demo
                    skeletonViewsSection
                    
                    // Loading Buttons Demo
                    loadingButtonsSection
                    
                    // Integrated Example
                    integratedExampleSection
                }
                .padding(.bottom, 100)
            }
            .navigationTitle("Loading Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Loading State Manager Section
    
    private var loadingStateManagerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Loading State Manager")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Centralized loading state management for consistent UI feedback.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                DemoActionButton(
                    title: "Load Products",
                    subtitle: "Simulate product loading",
                    color: .blue
                ) {
                    simulateProductLoading()
                }
                
                DemoActionButton(
                    title: "Load Crops",
                    subtitle: "Simulate crop data loading",
                    color: .green
                ) {
                    simulateCropLoading()
                }
                
                DemoActionButton(
                    title: "Simulate Error",
                    subtitle: "Show error state",
                    color: .red
                ) {
                    simulateError()
                }
                
                DemoActionButton(
                    title: "Clear All States",
                    subtitle: "Reset loading manager",
                    color: .gray
                ) {
                    loadingManager.clearAllStates()
                    products = []
                    crops = []
                }
            }
            
            // Show current states
            if loadingManager.isLoading(for: LoadingStateKeys.loadProducts) {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading products...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if loadingManager.isLoading(for: LoadingStateKeys.loadCrops) {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading crops...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Skeleton Views Section
    
    private var skeletonViewsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skeleton Views")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Skeleton screens provide visual feedback while content loads.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Products Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Products")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SkeletonContainer(
                    isLoading: loadingManager.isLoading(for: LoadingStateKeys.loadProducts)
                ) {
                    // Skeleton
                    AnyView(
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(0..<4, id: \.self) { _ in
                                ProductCardSkeleton()
                            }
                        }
                    )
                } content: {
                    // Actual content
                    AnyView(
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            if products.isEmpty {
                                Text("No products loaded")
                                    .foregroundColor(.secondary)
                                    .frame(height: 100)
                                    .gridCellColumns(2)
                            } else {
                                ForEach(products, id: \.self) { product in
                                    ProductContentView(title: product)
                                }
                            }
                        }
                    )
                }
            }
            
            // Crops Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Crops")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SkeletonContainer(
                    isLoading: loadingManager.isLoading(for: LoadingStateKeys.loadCrops)
                ) {
                    // Skeleton
                    AnyView(
                        VStack(spacing: 12) {
                            ForEach(0..<3, id: \.self) { _ in
                                CropCardSkeleton()
                            }
                        }
                    )
                } content: {
                    // Actual content
                    AnyView(
                        Group {
                            if crops.isEmpty {
                                Text("No crops loaded")
                                    .foregroundColor(.secondary)
                                    .frame(height: 100)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(crops, id: \.self) { crop in
                                        CropContentView(title: crop)
                                    }
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Loading Buttons Section
    
    private var loadingButtonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Loading Buttons")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Interactive buttons with loading, success, and error states.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                LoadingButton(title: "Primary Action", state: buttonState) {
                    simulateButtonAction()
                }
                
                HStack(spacing: 12) {
                    CompactLoadingButton(title: "Save", state: buttonState) {
                        simulateButtonAction()
                    }
                    
                    CompactLoadingButton(title: "Cancel", state: .idle) {
                        buttonState = .idle
                    }
                    .background(Color.gray)
                }
                
                HStack(spacing: 12) {
                    IconLoadingButton(icon: "plus", state: buttonState) {
                        simulateButtonAction()
                    }
                    
                    IconLoadingButton(icon: "heart", state: .idle) {
                        print("Heart tapped")
                    }
                    .background(Color.red)
                    
                    IconLoadingButton(icon: "star", state: .idle) {
                        print("Star tapped")
                    }
                    .background(Color.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Integrated Example Section
    
    private var integratedExampleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Integrated Example")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Real-world example showing loading states in a typical app flow.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Simulated Dashboard Stats
            Group {
                if loadingManager.isLoading(for: "dashboard_stats") {
                    DashboardStatsSkeleton()
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(title: "Active Crops", value: "12", icon: "leaf.fill", color: .green)
                        StatCard(title: "Harvest Ready", value: "3", icon: "scissors", color: .orange)
                        StatCard(title: "Soil Health", value: "85%", icon: "drop.fill", color: .blue)
                        StatCard(title: "Revenue", value: "₹1,250", icon: "indianrupeesign.circle.fill", color: .purple)
                    }
                }
            }
            
            LoadingButton(title: "Refresh Dashboard", state: .idle) {
                simulateDashboardRefresh()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Simulation Methods
    
    private func simulateProductLoading() {
        loadingManager.setLoading(for: LoadingStateKeys.loadProducts)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let sampleProducts = ["Tomatoes", "Corn", "Wheat", "Apples"]
            products = sampleProducts
            loadingManager.setLoaded(sampleProducts, for: LoadingStateKeys.loadProducts)
        }
    }
    
    private func simulateCropLoading() {
        loadingManager.setLoading(for: LoadingStateKeys.loadCrops)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let sampleCrops = ["Tomato Field A", "Corn Field B", "Wheat Field C"]
            crops = sampleCrops
            loadingManager.setLoaded(sampleCrops, for: LoadingStateKeys.loadCrops)
        }
    }
    
    private func simulateError() {
        loadingManager.setError(.networkUnavailable, for: LoadingStateKeys.loadProducts)
    }
    
    private func simulateButtonAction() {
        buttonState = .loading
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Randomly succeed or fail
            if Bool.random() {
                buttonState = .success
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    buttonState = .idle
                }
            } else {
                buttonState = .error
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    buttonState = .idle
                }
            }
        }
    }
    
    private func simulateDashboardRefresh() {
        loadingManager.setLoading(for: "dashboard_stats")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loadingManager.setLoaded("Dashboard data", for: "dashboard_stats")
        }
    }
}

// MARK: - Helper Views

struct ProductContentView: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.green.opacity(0.3))
                .frame(height: 120)
                .cornerRadius(12)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.title)
                        .foregroundColor(.green)
                )
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("Fresh & Organic")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct CropContentView: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 40, height: 40)
                .background(Color.green.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Healthy • Growing")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                ProgressView(value: 0.7)
                    .frame(width: 80)
                    .tint(.green)
                
                Text("70% Complete")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct DemoActionButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(color)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    LoadingStateDemoView()
}