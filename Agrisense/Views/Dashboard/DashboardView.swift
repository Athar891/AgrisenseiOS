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
    @EnvironmentObject var localizationManager: LocalizationManager
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
                        
                        // Recent Activity (only for farmers)
                        RecentActivitySection()
                    } else {
                        SellerDashboardContent()
                    }
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
        }
    }
}

struct DashboardHeader: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    
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
                
                // Weather Widget
                WeatherWidget()
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

struct WeatherWidget: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel = WeatherViewModel()

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
                Text(localizationManager.localizedString(for: "dash_placeholder"))
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
    @EnvironmentObject var localizationManager: LocalizationManager
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
                DashboardStatCard(title: localizationManager.localizedString(for: "active_crops"), value: "\(activeCropsCount)", icon: "leaf.fill", color: .green)
                DashboardStatCard(title: localizationManager.localizedString(for: "harvest_ready"), value: "\(harvestReadyCount)", icon: "scissors", color: .orange)
                DashboardStatCard(title: localizationManager.localizedString(for: "soil_health"), value: "85%", icon: "drop.fill", color: .blue)
                DashboardStatCard(title: marketPriceManager.currentCropName, value: marketPriceManager.currentMarketPrice, icon: "indianrupeesign.circle.fill", color: .purple)
            } else {
                DashboardStatCard(title: localizationManager.localizedString(for: "active_listings"), value: "8", icon: "tag.fill", color: .green)
                DashboardStatCard(title: localizationManager.localizedString(for: "orders_today"), value: "5", icon: "cart.fill", color: .blue)
                DashboardStatCard(title: localizationManager.localizedString(for: "revenue"), value: "₹1,250", icon: "indianrupeesign.circle.fill", color: .purple)
                DashboardStatCard(title: localizationManager.localizedString(for: "rating"), value: "4.8★", icon: "star.fill", color: .orange)
            }
        }
    }
}

struct DashboardStatCard: View {
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

            // Government Schemes Section
            GovernmentSchemesSection()
        }
        .sheet(isPresented: $showingAddCrop) { AddCropView() }
        .sheet(isPresented: $showingWeather) { WeatherView() }
        .sheet(isPresented: $showingMarketPrices) { MarketPricesView() }
        .sheet(isPresented: $showingSoilTest) { SoilTestView() }
    }
// Government Schemes Section
struct GovernmentScheme: Identifiable {
    let id = UUID()
    let nameKey: String
    let descriptionKey: String
    let url: URL
}

struct GovernmentSchemesSection: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // Static list of schemes with localization keys
    private let schemes: [GovernmentScheme] = [
        GovernmentScheme(
            nameKey: "scheme_pmkisan_name",
            descriptionKey: "scheme_pmkisan_desc",
            url: URL(string: "https://pmkisan.gov.in/")!
        ),
        GovernmentScheme(
            nameKey: "scheme_pmfby_name",
            descriptionKey: "scheme_pmfby_desc",
            url: URL(string: "https://pmfby.gov.in/")!
        ),
        GovernmentScheme(
            nameKey: "scheme_shc_name",
            descriptionKey: "scheme_shc_desc",
            url: URL(string: "https://soilhealth.dac.gov.in/")!
        ),
        GovernmentScheme(
            nameKey: "scheme_kcc_name",
            descriptionKey: "scheme_kcc_desc",
            url: URL(string: "https://www.pmkisan.gov.in/Documents/KCC.pdf")!
        ),
        GovernmentScheme(
            nameKey: "scheme_nfsm_name",
            descriptionKey: "scheme_nfsm_desc",
            url: URL(string: "https://nfsm.gov.in/")!
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString(for: "government_schemes_title"))
                .font(.headline)
                .fontWeight(.semibold)
            Text(localizationManager.localizedString(for: "government_schemes_subtitle"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(schemes) { scheme in
                        GovernmentSchemeCard(scheme: scheme)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.primary.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct GovernmentSchemeCard: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    let scheme: GovernmentScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizationManager.localizedString(for: scheme.nameKey))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(localizationManager.localizedString(for: scheme.descriptionKey))
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: {
                UIApplication.shared.open(scheme.url)
            }) {
                Text(localizationManager.localizedString(for: "visit_official_site"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            }
        }
        .frame(width: 220, height: 140)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.primary.opacity(0.08), radius: 2, x: 0, y: 1)
    }
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
    @EnvironmentObject var localizationManager: LocalizationManager
    
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
                    
                    Text(localizationManager.localizedString(for: "no_active_crops"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(localizationManager.localizedString(for: "add_first_crop_prompt"))
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
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var showingAddCrop: Bool
    @Binding var showingWeather: Bool
    @Binding var showingMarketPrices: Bool
    @Binding var showingSoilTest: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString(for: "quick_actions"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                DashboardQuickActionButton(title: localizationManager.localizedString(for: "add_crop"), icon: "plus.circle.fill", color: .green) { showingAddCrop = true }
                DashboardQuickActionButton(title: localizationManager.localizedString(for: "check_weather"), icon: "cloud.sun.fill", color: .blue) { showingWeather = true }
                DashboardQuickActionButton(title: localizationManager.localizedString(for: "market_prices"), icon: "chart.line.uptrend.xyaxis", color: .orange) { showingMarketPrices = true }
                DashboardQuickActionButton(title: localizationManager.localizedString(for: "soil_test"), icon: "drop.fill", color: .purple) { showingSoilTest = true }
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
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString(for: "sales_overview"))
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("₹1,250")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text(localizationManager.localizedString(for: "todays_sales"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("+12%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text(localizationManager.localizedString(for: "vs_yesterday"))
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
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localizedString(for: "inventory_alerts"))
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
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(appState.notifications) { notification in
                    NotificationRow(notification: notification)
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "notifications_title"))
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
    .environmentObject(LocalizationManager.shared)
}
