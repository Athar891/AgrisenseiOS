//
//  SkeletonViews.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import SwiftUI

// MARK: - Base Skeleton View

struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var isAnimating = false
    
    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Product Card Skeleton

struct ProductCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Image Skeleton
            SkeletonView(height: 120, cornerRadius: 12)
            
            VStack(alignment: .leading, spacing: 8) {
                // Product Name
                SkeletonView(width: 120, height: 16, cornerRadius: 4)
                
                // Seller Name
                SkeletonView(width: 80, height: 12, cornerRadius: 4)
                
                HStack {
                    // Price
                    SkeletonView(width: 60, height: 18, cornerRadius: 4)
                    
                    Spacer()
                    
                    // Rating
                    SkeletonView(width: 40, height: 12, cornerRadius: 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Crop Card Skeleton

struct CropCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Crop Icon
            SkeletonView(width: 40, height: 40, cornerRadius: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                // Crop Name
                SkeletonView(width: 100, height: 16, cornerRadius: 4)
                
                // Growth Stage
                SkeletonView(width: 80, height: 12, cornerRadius: 4)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Progress Bar
                SkeletonView(width: 80, height: 4, cornerRadius: 2)
                
                // Health Status
                SkeletonView(width: 60, height: 12, cornerRadius: 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Community Post Skeleton

struct CommunityPostSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // User Avatar
                SkeletonView(width: 40, height: 40, cornerRadius: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Username
                    SkeletonView(width: 100, height: 14, cornerRadius: 4)
                    
                    // Timestamp
                    SkeletonView(width: 60, height: 12, cornerRadius: 4)
                }
                
                Spacer()
            }
            
            // Post Content
            VStack(alignment: .leading, spacing: 6) {
                SkeletonView(height: 16, cornerRadius: 4)
                SkeletonView(width: 250, height: 16, cornerRadius: 4)
                SkeletonView(width: 180, height: 16, cornerRadius: 4)
            }
            
            // Post Image (optional)
            if Bool.random() {
                SkeletonView(height: 200, cornerRadius: 12)
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                SkeletonView(width: 60, height: 32, cornerRadius: 16)
                SkeletonView(width: 60, height: 32, cornerRadius: 16)
                SkeletonView(width: 60, height: 32, cornerRadius: 16)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Dashboard Stats Skeleton

struct DashboardStatsSkeleton: View {
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SkeletonView(width: 24, height: 24, cornerRadius: 12)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonView(width: 60, height: 20, cornerRadius: 4)
                        SkeletonView(width: 80, height: 12, cornerRadius: 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
    }
}

// MARK: - Weather Widget Skeleton

struct WeatherWidgetSkeleton: View {
    var body: some View {
        HStack(spacing: 8) {
            SkeletonView(width: 24, height: 24, cornerRadius: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                SkeletonView(width: 50, height: 16, cornerRadius: 4)
                SkeletonView(width: 40, height: 12, cornerRadius: 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - List Skeleton

struct ListSkeleton: View {
    let itemCount: Int
    let itemHeight: CGFloat
    
    init(itemCount: Int = 5, itemHeight: CGFloat = 60) {
        self.itemCount = itemCount
        self.itemHeight = itemHeight
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<itemCount, id: \.self) { _ in
                HStack(spacing: 12) {
                    SkeletonView(width: 40, height: 40, cornerRadius: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonView(width: 120, height: 16, cornerRadius: 4)
                        SkeletonView(width: 80, height: 12, cornerRadius: 4)
                    }
                    
                    Spacer()
                    
                    SkeletonView(width: 60, height: 12, cornerRadius: 4)
                }
                .frame(height: itemHeight)
            }
        }
    }
}

// MARK: - Grid Skeleton

struct GridSkeleton: View {
    let columns: Int
    let itemCount: Int
    let itemHeight: CGFloat
    
    init(columns: Int = 2, itemCount: Int = 6, itemHeight: CGFloat = 200) {
        self.columns = columns
        self.itemCount = itemCount
        self.itemHeight = itemHeight
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 16) {
            ForEach(0..<itemCount, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonView(height: itemHeight * 0.6, cornerRadius: 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonView(width: 100, height: 16, cornerRadius: 4)
                        SkeletonView(width: 60, height: 12, cornerRadius: 4)
                    }
                }
                .frame(height: itemHeight)
            }
        }
    }
}

// MARK: - Profile Skeleton

struct ProfileSkeleton: View {
    var body: some View {
        VStack(spacing: 20) {
            // Profile Image
            SkeletonView(width: 100, height: 100, cornerRadius: 50)
            
            // Name
            SkeletonView(width: 150, height: 24, cornerRadius: 4)
            
            // Email
            SkeletonView(width: 200, height: 16, cornerRadius: 4)
            
            // Stats
            HStack(spacing: 30) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 4) {
                        SkeletonView(width: 40, height: 20, cornerRadius: 4)
                        SkeletonView(width: 60, height: 12, cornerRadius: 4)
                    }
                }
            }
            
            // Settings Options
            VStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        SkeletonView(width: 24, height: 24, cornerRadius: 12)
                        SkeletonView(width: 120, height: 16, cornerRadius: 4)
                        Spacer()
                        SkeletonView(width: 20, height: 20, cornerRadius: 10)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

// MARK: - Skeleton Container

struct SkeletonContainer<Content: View>: View {
    let isLoading: Bool
    let skeleton: () -> Content
    let content: () -> Content
    
    init(isLoading: Bool, @ViewBuilder skeleton: @escaping () -> Content, @ViewBuilder content: @escaping () -> Content) {
        self.isLoading = isLoading
        self.skeleton = skeleton
        self.content = content
    }
    
    var body: some View {
        Group {
            if isLoading {
                skeleton()
            } else {
                content()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Skeleton Views Demo")
                .font(.title2)
                .fontWeight(.bold)
            
            Group {
                Text("Product Cards")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        ProductCardSkeleton()
                    }
                }
                
                Text("Community Posts")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        CommunityPostSkeleton()
                    }
                }
                
                Text("Dashboard Stats")
                    .font(.headline)
                
                DashboardStatsSkeleton()
            }
        }
        .padding()
    }
}