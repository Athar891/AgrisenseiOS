//
//  EnhancedDashboardView.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import SwiftUI

// MARK: - Enhanced Dashboard View with Loading States

struct EnhancedDashboardView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var marketPriceManager = MarketPriceManager()
    @StateObject private var loadingManager = LoadingStateManager.shared
    @State private var showingNotifications = false
    @State private var refreshButtonState: LoadingButtonState = .idle
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Welcome and Notifications
                    EnhancedDashboardHeader()
                    
                    // Quick Stats Cards with Loading States
                    EnhancedDashboardQuickStatsSection(marketPriceManager: marketPriceManager)
                    
                    // Main Content based on User Type
                    if userManager.currentUser?.userType == .farmer {
                        EnhancedFarmerDashboardContent()
                        
                        // Recent Activity (only for farmers)
                        EnhancedRecentActivitySection()
                    } else {
                        EnhancedSellerDashboardContent()
                    }
                    
                    // Refresh Button
                    LoadingButton(
                        title: "Refresh Dashboard",
                        state: refreshButtonState
                    ) {
                        refreshDashboard()
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle(localizationManager.localizedString(for: "dashboard_title"))
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
            .onAppear {
                loadInitialData()
            }
            .refreshable {
                await refreshDashboardAsync()
            }
        }
    }
    
    // MARK: - Data Loading Methods
    
    private func loadInitialData() {
        loadWeatherData()
        loadCropData()
        loadMarketPrices()
    }
    
    private func loadWeatherData() {
        loadingManager.setLoading(for: LoadingStateKeys.loadWeather)
        
        // Simulate weather data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loadingManager.setLoaded("Weather data loaded", for: LoadingStateKeys.loadWeather)
        }
    }
    
    private func loadCropData() {
        loadingManager.setLoading(for: LoadingStateKeys.loadCrops)
        
        // Simulate crop data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            loadingManager.setLoaded("Crop data loaded", for: LoadingStateKeys.loadCrops)
        }
    }
    
    private func loadMarketPrices() {
        loadingManager.setLoading(for: LoadingStateKeys.loadMarketPrices)
        
        // Simulate market price loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            loadingManager.setLoaded("Market prices loaded", for: LoadingStateKeys.loadMarketPrices)
        }
    }
    
    private func refreshDashboard() {
        refreshButtonState = .loading
        
        // Refresh all data
        loadInitialData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            refreshButtonState = .success
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                refreshButtonState = .idle
            }
        }
    }
    
    private func refreshDashboardAsync() async {
        refreshButtonState = .loading
        
        // Simulate async refresh
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await MainActor.run {
            loadInitialData()
            refreshButtonState = .success
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                refreshButtonState = .idle
            }
        }
    }
}

// MARK: - Enhanced Dashboard Header

struct EnhancedDashboardHeader: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var loadingManager = LoadingStateManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localizedString(for: "welcome_back_greeting"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(userManager.currentUser?.name ?? "User")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Enhanced Weather Widget with Loading State
                EnhancedWeatherWidget()
            }
            
            Text(String(format: localizationManager.localizedString(for: "dashboard_whats_happening"), userManager.currentUser?.userType == .farmer ? localizationManager.localizedString(for: "farm") : localizationManager.localizedString(for: "business")))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Enhanced Weather Widget

struct EnhancedWeatherWidget: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = WeatherViewModel()
    @StateObject private var loadingManager = LoadingStateManager.shared

    var body: some View {
        VStack {
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                weatherContent
            case .notDetermined:
                Button(localizationManager.localizedString(for: "enable_location_for_weather")) {
                    locationManager.requestLocationPermission()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            case .denied, .restricted:
                Text(localizationManager.localizedString(for: "location_access_denied_settings"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            @unknown default:
                EmptyView()
            }
        }
        .onAppear {
            viewModel.setup(locationManager: locationManager)
            
            // Start location updates if authorized
            if locationManager.authorizationStatus == .authorizedWhenInUse || 
               locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startUpdatingLocation()
            }
        }
    }

    private var weatherContent: some View {
        VStack {
            if viewModel.isLoading {
                // Show loading skeleton
                WeatherWidgetSkeleton()
            } else if let errorMessage = viewModel.errorMessage {
                // Show error message
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(localizationManager.localizedString(for: "weather_unavailable"))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12)
            } else if let weatherData = viewModel.weatherData {
                // Show actual weather data
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
            } else {
                // Show placeholder when no data yet
                Text(localizationManager.localizedString(for: "dash_placeholder"))
                    .font(.caption)
                    .foregroundColor(.secondary)
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

// MARK: - Enhanced Quick Stats Section

struct EnhancedDashboardQuickStatsSection: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @ObservedObject var marketPriceManager: MarketPriceManager
    @StateObject private var loadingManager = LoadingStateManager.shared

    private var activeCropsCount: Int {
        userManager.currentUser?.crops.filter { $0.currentGrowthStage != .harvest }.count ?? 0
    }

    private var harvestReadyCount: Int {
        userManager.currentUser?.crops.filter { $0.currentGrowthStage == .harvest }.count ?? 0
    }
    
    var body: some View {
        SkeletonContainer(
            isLoading: loadingManager.isLoading(for: LoadingStateKeys.loadMarketPrices)
        ) {
            // Skeleton
            AnyView(DashboardStatsSkeleton())
        } content: {
            // Actual content
            AnyView(
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    Group {
                        if userManager.currentUser?.userType == .farmer {
                            StatCard(title: localizationManager.localizedString(for: "active_crops"), value: "\(activeCropsCount)", icon: "leaf.fill", color: .green)
                            StatCard(title: localizationManager.localizedString(for: "harvest_ready"), value: "\(harvestReadyCount)", icon: "scissors", color: .orange)
                            StatCard(title: localizationManager.localizedString(for: "soil_health"), value: "85%", icon: "drop.fill", color: .blue)
                            StatCard(title: marketPriceManager.currentCropName, value: marketPriceManager.currentMarketPrice, icon: "indianrupeesign.circle.fill", color: .purple)
                        } else {
                            StatCard(title: localizationManager.localizedString(for: "active_listings"), value: "8", icon: "tag.fill", color: .green)
                            StatCard(title: localizationManager.localizedString(for: "orders_today"), value: "5", icon: "cart.fill", color: .blue)
                            StatCard(title: localizationManager.localizedString(for: "revenue"), value: "₹1,250", icon: "indianrupeesign.circle.fill", color: .purple)
                            StatCard(title: localizationManager.localizedString(for: "rating"), value: "4.8★", icon: "star.fill", color: .orange)
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Enhanced Farmer Dashboard Content

struct EnhancedFarmerDashboardContent: View {
    @State private var showingAddCrop = false
    @State private var showingWeather = false
    @State private var showingMarketPrices = false
    @State private var showingSoilTest = false

    var body: some View {
        VStack(spacing: 20) {
            // Crop Health Overview with Loading States
            EnhancedCropHealthSection()
            
            // Quick Actions
            EnhancedQuickActionsSection(
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

// MARK: - Enhanced Crop Health Section

struct EnhancedCropHealthSection: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var loadingManager = LoadingStateManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(localizationManager.localizedString(for: "active_crops"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let cropsCount = userManager.currentUser?.crops.count, cropsCount > 0 {
                    Text("\(cropsCount) crop\(cropsCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
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
                    VStack(spacing: 12) {
                        if let crops = userManager.currentUser?.crops, !crops.isEmpty {
                            ForEach(crops.filter { !$0.isOverdue }) { crop in
                                NavigationLink(destination: CropDetailView(crop: crop)) {
                                    CropHealthRow(crop: crop)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else {
                            // Empty state
                            Image(systemName: "leaf")
                                .font(.system(size: 40))
                                .foregroundColor(.green.opacity(0.6))
                            
                            Text(localizationManager.localizedString(for: "no_active_crops"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(localizationManager.localizedString(for: "add_first_crop_prompt"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 20)
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Enhanced Quick Actions Section

struct EnhancedQuickActionsSection: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var showingAddCrop: Bool
    @Binding var showingWeather: Bool
    @Binding var showingMarketPrices: Bool
    @Binding var showingSoilTest: Bool
    
    @State private var addCropButtonState: LoadingButtonState = .idle

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString(for: "quick_actions"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                EnhancedDashboardQuickActionButton(
                    title: localizationManager.localizedString(for: "add_crop"),
                    icon: "plus.circle.fill",
                    color: .green,
                    buttonState: addCropButtonState
                ) {
                    addCropButtonState = .loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        addCropButtonState = .success
                        showingAddCrop = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            addCropButtonState = .idle
                        }
                    }
                }
                
                EnhancedDashboardQuickActionButton(
                    title: localizationManager.localizedString(for: "check_weather"),
                    icon: "cloud.sun.fill",
                    color: .blue
                ) { showingWeather = true }
                
                EnhancedDashboardQuickActionButton(
                    title: localizationManager.localizedString(for: "market_prices"),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                ) { showingMarketPrices = true }
                
                EnhancedDashboardQuickActionButton(
                    title: localizationManager.localizedString(for: "soil_test"),
                    icon: "drop.fill",
                    color: .purple
                ) { showingSoilTest = true }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Enhanced Quick Action Button

struct EnhancedDashboardQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let buttonState: LoadingButtonState
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, buttonState: LoadingButtonState = .idle, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.buttonState = buttonState
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if buttonState.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: color))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: buttonState == .success ? "checkmark" : icon)
                            .font(.title2)
                            .foregroundColor(buttonState == .success ? .green : color)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
            .opacity(buttonState.isDisabled ? 0.7 : 1.0)
            .scaleEffect(buttonState.isLoading ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(buttonState.isDisabled)
        .animation(.easeInOut(duration: 0.2), value: buttonState)
    }
}

// MARK: - Enhanced Seller Dashboard Content

struct EnhancedSellerDashboardContent: View {
    var body: some View {
        VStack(spacing: 20) {
            // Sales Overview
            SalesOverviewSection()
            
            // Inventory Alerts
            InventoryAlertsSection()
        }
    }
}

// MARK: - Enhanced Recent Activity Section

struct EnhancedRecentActivitySection: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString(for: "recent_activity"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActivityRow(icon: "leaf.fill", title: localizationManager.localizedString(for: "activity_crop_watered"), time: localizationManager.localizedString(for: "activity_2_hours_ago"), color: .blue)
                ActivityRow(icon: "cart.fill", title: localizationManager.localizedString(for: "activity_order_completed"), time: localizationManager.localizedString(for: "activity_4_hours_ago"), color: .green)
                ActivityRow(icon: "chart.line.uptrend.xyaxis", title: localizationManager.localizedString(for: "activity_price_updated"), time: localizationManager.localizedString(for: "activity_6_hours_ago"), color: .orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    EnhancedDashboardView()
        .environmentObject(UserManager())
        .environmentObject(AppState())
        .environmentObject(LocalizationManager.shared)
}