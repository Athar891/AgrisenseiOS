//
//  AppState.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import Foundation
import SwiftUI

// Custom environment key for dark mode
struct DarkModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isDarkMode: Bool {
        get { self[DarkModeKey.self] }
        set { self[DarkModeKey.self] = newValue }
    }
}

@MainActor
public final class AppState: ObservableObject {
    // MARK: - Core State
    @Published var user: User?
    @Published public var selectedTab: Tab = .home
    @Published public var pendingDeepLink: DeepLink?
    
    // MARK: - Existing Properties (preserved)
    @Published var showingOnboarding = false
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            print("Dark mode saved to UserDefaults: \(isDarkMode)")
        }
    }
    
    public init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        print("AppState initialized with dark mode: \(self.isDarkMode)")
    }
    
    // MARK: - Tab Management
    public enum Tab: Int, CaseIterable {
        case home = 0        // Renamed from dashboard to match new architecture
        case market = 1      // Renamed from marketplace
        case community = 2
        case assistant = 3
        case profile = 4
        
        var title: String {
            switch self {
            case .home:
                return LocalizationManager.shared.localizedString(for: "tab_home")
            case .market:
                return LocalizationManager.shared.localizedString(for: "tab_market")
            case .community:
                return LocalizationManager.shared.localizedString(for: "tab_community")
            case .assistant:
                return LocalizationManager.shared.localizedString(for: "tab_assistant")
            case .profile:
                return LocalizationManager.shared.localizedString(for: "tab_profile")
            }
        }
        
        var icon: String {
            switch self {
            case .home:
                return "house.fill"
            case .market:
                return "cart.fill"
            case .community:
                return "person.3.fill"
            case .assistant:
                return "sparkles"
            case .profile:
                return "person.crop.circle"
            }
        }
    }
    
    // MARK: - Deep Linking
    public enum DeepLink {
        case assistantOpenThread(id: String)
        case marketplaceProduct(id: String)
        case communityPost(id: String)
        case profileSettings
    }
    
    // MARK: - Cross-Feature Communication
    public func navigateToTab(_ tab: Tab, deepLink: DeepLink? = nil) {
        selectedTab = tab
        pendingDeepLink = deepLink
    }
    
    public func consumeDeepLink() -> DeepLink? {
        let link = pendingDeepLink
        pendingDeepLink = nil
        return link
    }
    
    // MARK: - Notification Management
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        // Keep only the last 50 notifications
        if notifications.count > 50 {
            notifications = Array(notifications.prefix(50))
        }
    }
    
    public func markNotificationAsRead(_ id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
        }
    }
    
    public func clearAllNotifications() {
        notifications.removeAll()
    }
    
    // MARK: - Tab Icon Helper
    public func tabIcon(for tab: Tab) -> String {
        return tab.icon
    }
}

// MARK: - Supporting Models (preserved and enhanced)
struct AppNotification: Identifiable, Codable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool = false
    
    enum NotificationType: String, Codable {
        case info = "info"
        case success = "success"
        case warning = "warning"
        case error = "error"
        
        var color: Color {
            switch self {
            case .info:
                return .blue
            case .success:
                return .green
            case .warning:
                return .orange
            case .error:
                return .red
            }
        }
    }
}
