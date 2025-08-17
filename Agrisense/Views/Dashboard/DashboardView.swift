//
//  DashboardView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @StateObject private var marketPriceManager = MarketPriceManager()
    @State private var showingNotifications = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Welcome and Notifications
                    DashboardHeader()
                    
                    // Quick Stats Cards
                    DashboardQuickStatsSection(marketPriceManager: marketPriceManager)
                    
                    // Main Content based on User Type
                    if userManager.currentUser?.userType == .farmer {
                        FarmerDashboardContent()
                    } else {
                        SellerDashboardContent()
                    }
                    
                    // Recent Activity
                    RecentActivitySection()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNotifications = true }) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
            }
        }
    }
}

struct DashboardHeader: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(userManager.currentUser?.name ?? "User")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Weather Widget
                WeatherWidget()
            }
            
            Text("Here's what's happening with your \(userManager.currentUser?.userType == .farmer ? "farm" : "business") today")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct WeatherWidget: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        VStack {
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                weatherContent
            case .notDetermined:
                Button("Enable Location for Weather") {
                    locationManager.requestLocationPermission()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            case .denied, .restricted:
                Text("Location access denied. Please enable it in Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            @unknown default:
                EmptyView()
            }
        }
        .onAppear {
            viewModel.setup(locationManager: locationManager)
        }
    }

    private var weatherContent: some View {
        VStack {
            if let weatherData = viewModel.weatherData {
        HStack(spacing: 8) {
                    Image(systemName: weatherIcon(for: weatherData.weather?.first?.main ?? ""))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(weatherData.main?.temp ?? 0, specifier: "%.1f")°C")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(weatherData.weather?.first?.main ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
            } else if viewModel.isLoading {
                ProgressView()
            } else {
                Text("-")
            }
        }
    }

    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "clouds":
            return "cloud.fill"
        case "rain":
            return "cloud.rain.fill"
        case "clear":
            return "sun.max.fill"
        default:
            return "cloud"
        }
    }
}

struct DashboardQuickStatsSection: View {
    @EnvironmentObject var userManager: UserManager
    @ObservedObject var marketPriceManager: MarketPriceManager

    private var activeCropsCount: Int {
        userManager.currentUser?.crops.filter { $0.currentGrowthStage != .harvest }.count ?? 0
    }

    private var harvestReadyCount: Int {
        userManager.currentUser?.crops.filter { $0.currentGrowthStage == .harvest }.count ?? 0
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            if userManager.currentUser?.userType == .farmer {
                StatCard(title: "Active Crops", value: "\(activeCropsCount)", icon: "leaf.fill", color: .green)
                StatCard(title: "Harvest Ready", value: "\(harvestReadyCount)", icon: "scissors", color: .orange)
                StatCard(title: "Soil Health", value: "85%", icon: "drop.fill", color: .blue)
                StatCard(title: marketPriceManager.currentCropName, value: marketPriceManager.currentMarketPrice, icon: "indianrupeesign.circle.fill", color: .purple)
            } else {
                StatCard(title: "Active Listings", value: "8", icon: "tag.fill", color: .green)
                StatCard(title: "Orders Today", value: "5", icon: "cart.fill", color: .blue)
                StatCard(title: "Revenue", value: "₹1,250", icon: "indianrupeesign.circle.fill", color: .purple)
                StatCard(title: "Rating", value: "4.8★", icon: "star.fill", color: .orange)
            }
        }
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
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct FarmerDashboardContent: View {
    @State private var showingAddCrop = false
    @State private var showingWeather = false
    @State private var showingMarketPrices = false
    @State private var showingSoilTest = false

    var body: some View {
        VStack(spacing: 20) {
            // Crop Health Overview
            CropHealthSection()
            
            // Quick Actions
            QuickActionsSection(
                showingAddCrop: $showingAddCrop,
                showingWeather: $showingWeather,
                showingMarketPrices: $showingMarketPrices,
                showingSoilTest: $showingSoilTest
            )
        }
        .sheet(isPresented: $showingAddCrop) { AddCropView() }
        .sheet(isPresented: $showingWeather) { WeatherView() }
        .sheet(isPresented: $showingMarketPrices) { MarketPricesView() }
        .sheet(isPresented: $showingSoilTest) { SoilTestView() }
    }
}

struct SellerDashboardContent: View {
    var body: some View {
        VStack(spacing: 20) {
            // Sales Overview
            SalesOverviewSection()
            
            // Inventory Alerts
            InventoryAlertsSection()
        }
    }
}

struct CropHealthSection: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Crops")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let cropsCount = userManager.currentUser?.crops.count, cropsCount > 0 {
                    Text("\(cropsCount) crop\(cropsCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let crops = userManager.currentUser?.crops, !crops.isEmpty {
                VStack(spacing: 12) {
                    ForEach(crops.filter { !$0.isOverdue }) { crop in
                        NavigationLink(destination: CropDetailView(crop: crop)) {
                            CropHealthRow(crop: crop)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "leaf")
                        .font(.system(size: 40))
                        .foregroundColor(.green.opacity(0.6))
                    
                    Text("No active crops yet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Add your first crop to start tracking its health and progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CropHealthRow: View {
    let crop: Crop
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(crop.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Image(systemName: crop.currentGrowthStage.icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(crop.currentGrowthStage.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                ProgressView(value: crop.healthStatus.healthPercentage)
                    .frame(width: 80)
                    .tint(crop.healthStatus.color)
                
                Text(crop.healthStatus.displayName)
                    .font(.caption)
                    .foregroundColor(crop.healthStatus.color)
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionsSection: View {
    @Binding var showingAddCrop: Bool
    @Binding var showingWeather: Bool
    @Binding var showingMarketPrices: Bool
    @Binding var showingSoilTest: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                DashboardQuickActionButton(title: "Add Crop", icon: "plus.circle.fill", color: .green) { showingAddCrop = true }
                DashboardQuickActionButton(title: "Check Weather", icon: "cloud.sun.fill", color: .blue) { showingWeather = true }
                DashboardQuickActionButton(title: "Market Prices", icon: "chart.line.uptrend.xyaxis", color: .orange) { showingMarketPrices = true }
                DashboardQuickActionButton(title: "Soil Test", icon: "drop.fill", color: .purple) { showingSoilTest = true }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct DashboardQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SalesOverviewSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sales Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("₹1,250")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Today's Sales")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("+12%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("vs Yesterday")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct InventoryAlertsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inventory Alerts")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                AlertRow(title: "Low Stock: Tomatoes", message: "Only 5kg remaining", type: .warning)
                AlertRow(title: "New Order", message: "Order #1234 received", type: .info)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct AlertRow: View {
    let title: String
    let message: String
    let type: AppNotification.NotificationType
    
    var body: some View {
        HStack {
            Circle()
                .fill(type.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct RecentActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActivityRow(icon: "leaf.fill", title: "Crop watered", time: "2 hours ago", color: .blue)
                ActivityRow(icon: "cart.fill", title: "Order completed", time: "4 hours ago", color: .green)
                ActivityRow(icon: "chart.line.uptrend.xyaxis", title: "Price updated", time: "6 hours ago", color: .orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                ForEach(appState.notifications) { notification in
                    NotificationRow(notification: notification)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack {
            Circle()
                .fill(notification.type.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(notification.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DashboardView()
        .environmentObject(UserManager())
        .environmentObject(AppState())
}
