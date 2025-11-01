//
//  ProfileView.swift
//  Agrisense
//
//  Created by Athar Reza on 24/10/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var orderManager: OrderManager?
    @State private var showingSettings = false
    @State private var showingOrderHistory = false
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView()
                    
                    // Quick Stats (for sellers)
                    if userManager.currentUser?.userType == .seller {
                        SellerStatsView()
                    }
                    
                    // Menu Options
                    VStack(spacing: 0) {
                        ProfileMenuButton(
                            icon: "person.circle",
                            title: localizationManager.localizedString(for: "edit_profile"),
                            action: { showingEditProfile = true }
                        )
                        
                        Divider().padding(.leading, 60)
                        
                        ProfileMenuButton(
                            icon: "clock.arrow.circlepath",
                            title: localizationManager.localizedString(for: "order_history"),
                            action: { showingOrderHistory = true }
                        )
                        
                        Divider().padding(.leading, 60)
                        
                        ProfileMenuButton(
                            icon: "gearshape",
                            title: localizationManager.localizedString(for: "settings"),
                            action: { showingSettings = true }
                        )
                        
                        Divider().padding(.leading, 60)
                        
                        ProfileMenuButton(
                            icon: "questionmark.circle",
                            title: localizationManager.localizedString(for: "help_support"),
                            action: { 
                                // Open help/support - could link to documentation or support email
                                if let url = URL(string: "mailto:support@agrisense.app") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )
                        
                        Divider().padding(.leading, 60)
                        
                        ProfileMenuButton(
                            icon: "arrow.right.square",
                            title: localizationManager.localizedString(for: "logout"),
                            isDestructive: true,
                            action: { showingLogoutAlert = true }
                        )
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    // App Version
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(localizationManager.localizedString(for: "profile"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Initialize OrderManager with current user's ID
                if let userId = userManager.currentUser?.id {
                    orderManager = OrderManager(userId: userId)
                    #if DEBUG
                    print("📱 ProfileView appeared")
                    print("👤 Current user ID: \(userId)")
                    print("🖼️ Profile image URL: \(userManager.currentUser?.profileImage ?? "nil")")
                    #endif
                    // Refresh user data from Firestore to ensure profile image is up to date
                    Task {
                        await userManager.loadUserFromFirestore(userId)
                        #if DEBUG
                        print("♻️ User data refreshed")
                        print("🖼️ Profile image URL after refresh: \(userManager.currentUser?.profileImage ?? "nil")")
                        #endif
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(userManager)
                    .environmentObject(localizationManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(localizationManager)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingOrderHistory) {
                if let orderManager = orderManager {
                    OrderHistoryView(orderManager: orderManager)
                        .environmentObject(localizationManager)
                }
            }
            .alert(localizationManager.localizedString(for: "logout_confirmation"), isPresented: $showingLogoutAlert) {
                Button(localizationManager.localizedString(for: "cancel"), role: .cancel) {}
                Button(localizationManager.localizedString(for: "logout"), role: .destructive) {
                    userManager.signOut()
                }
            } message: {
                Text(localizationManager.localizedString(for: "logout_message"))
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var imageKey = UUID()
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.green, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                if let user = userManager.currentUser {
                    if let imageURL = user.profileImage, !imageURL.isEmpty {
                        #if DEBUG
                        let _ = print("🖼️ Loading profile image from: \(imageURL)")
                        #endif
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            case .failure(let error):
                                VStack {
                                    Text(user.name.prefix(1).uppercased())
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            case .empty:
                                VStack {
                                    ProgressView()
                                        .tint(.white)
                                }
                            @unknown default:
                                Text(user.name.prefix(1).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .id(imageKey)
                    } else {
                        Text(user.name.prefix(1).uppercased())
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
            .onChange(of: userManager.currentUser?.profileImage) { _ in
                imageKey = UUID()
            }
            
            // User Info
            if let user = userManager.currentUser {
                VStack(spacing: 4) {
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // User Type Badge
                    HStack(spacing: 4) {
                        Image(systemName: user.userType == .farmer ? "leaf.fill" : "cart.fill")
                            .font(.caption)
                        Text(user.userType == .farmer ? 
                             localizationManager.localizedString(for: "farmer") : 
                             localizationManager.localizedString(for: "seller"))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                    .padding(.top, 4)
                }
            }
        }
        .padding()
    }
}

// MARK: - Seller Stats
struct SellerStatsView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        HStack(spacing: 16) {
            ProfileStatCard(
                title: localizationManager.localizedString(for: "total_sales"),
                value: "₹0",
                icon: "banknote"
            )
            
            ProfileStatCard(
                title: localizationManager.localizedString(for: "products"),
                value: "0",
                icon: "shippingbox"
            )
            
            ProfileStatCard(
                title: localizationManager.localizedString(for: "rating"),
                value: "0.0",
                icon: "star.fill"
            )
        }
        .padding(.horizontal)
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Profile Menu Button
struct ProfileMenuButton: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isDestructive ? .red : .green)
                    .frame(width: 32)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserManager())
            .environmentObject(AppState())
            .environmentObject(LocalizationManager.shared)
    }
}
