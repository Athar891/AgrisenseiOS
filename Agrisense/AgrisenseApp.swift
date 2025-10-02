import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configure Google Sign-In with client ID
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            return true
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        // Initialize Google Sign-In
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            // Silent restoration - no need for logging in production
        }
        return true
    }
    
    // Handle URL for Google Sign-In
    func application(_ app: UIApplication, 
                    open url: URL, 
                    options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct AgrisenseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userManager = UserManager()
    @StateObject private var appState = AppState()
    @StateObject private var localizationManager = LocalizationManager.shared
    
    private var colorScheme: ColorScheme? {
        appState.isDarkMode ? .dark : .light
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userManager)
                .environmentObject(appState)
                .environmentObject(localizationManager)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    configureAppearance()
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
    
    private func configureAppearance() {
        // Configure tab bar appearance for proper dark/light mode support
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        // Set adaptive background colors
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        // Configure normal state (unselected tabs)
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        // Configure selected state
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Apply the appearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

struct ContentView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            Group {
                if userManager.isAuthenticated {
                TabView(selection: $appState.selectedTab) {
                    DashboardView()
                        .tabItem {
                            Image(systemName: appState.tabIcon(for: .home))
                            Text(AppState.Tab.home.title)
                        }
                        .tag(AppState.Tab.home)
                    
                    MarketplaceView()
                        .tabItem {
                            Image(systemName: appState.tabIcon(for: .market))
                            Text(AppState.Tab.market.title)
                        }
                        .tag(AppState.Tab.market)
                    
                    CommunityView()
                        .tabItem {
                            Image(systemName: appState.tabIcon(for: .community))
                            Text(AppState.Tab.community.title)
                        }
                        .tag(AppState.Tab.community)
                    
                    AssistantView()
                        .tabItem {
                            Image(systemName: appState.tabIcon(for: .assistant))
                            Text(AppState.Tab.assistant.title)
                        }
                        .tag(AppState.Tab.assistant)
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: appState.tabIcon(for: .profile))
                            Text(AppState.Tab.profile.title)
                        }
                        .tag(AppState.Tab.profile)
                }
                } else {
                    AuthenticationView()
                }
            }
            .opacity(showSplash ? 0 : 1)
            
            // Splash screen overlay
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Show splash screen for 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}