# AgriSense iOS - AI Coding Agent Instructions

## Architecture Overview

AgriSense is a SwiftUI-based agricultural marketplace app with role-based user experiences (Farmer/Seller). The app follows MVVM with ObservableObject pattern, dependency injection through CoreKit, and comprehensive localization support.

### Core Dependencies & Services
- **Firebase**: Authentication (GoogleSignIn), Firestore database, Analytics
- **External APIs**: Gemini AI (agricultural advice), OpenWeather, Cloudinary (image uploads)
- **Key Services**: Located in `Agrisense/Services/` and `Agrisense/CoreKit/`

## Essential Patterns

### 1. App State Management
```swift
// Central state lives in AppState.swift - always inject as @EnvironmentObject
@StateObject private var appState = AppState()
@StateObject private var userManager = UserManager()
@StateObject private var localizationManager = LocalizationManager.shared

// Tab navigation through AppState.Tab enum (.home, .market, .community, .assistant, .profile)
appState.selectedTab = .assistant
```

### 2. User Type Conditional Logic
```swift
// CRITICAL: All features must respect user roles
if userManager.currentUser?.userType == .farmer {
    // Farmer-specific features (crop management, purchase flow)
} else {
    // Seller-specific features (inventory management, sales analytics)
}
```

### 3. Secrets Management
- **NEVER hardcode API keys** - use `Secrets.swift` (copy from `_Secrets.example.swift`)
- Pattern: `Secrets.geminiAPIKey`, `Secrets.openWeatherAPIKey`, `Secrets.cloudinaryCloudName`
- `Secrets.swift` is git-ignored for security

### 4. Localization (Multi-language Support)
```swift
// ALWAYS use localized strings - never hardcode text
@EnvironmentObject var localizationManager: LocalizationManager
Text(localizationManager.localizedString(for: "key_name"))

// Supported: en, hi, bn, ta, te (English, Hindi, Bengali, Tamil, Telugu)
```

### 5. Loading State Management
```swift
// Use centralized loading states from LoadingStateManager.shared
@StateObject private var loadingManager = LoadingStateManager.shared
loadingManager.setLoading(true, for: LoadingStateKeys.loadProducts)

// Skeleton loading patterns in Views/Demo/LoadingStateDemoView.swift
```

## Navigation & Routing

### Main Structure (AgrisenseApp.swift)
```swift
// App entry → ContentView → TabView with 5 tabs
ContentView() // Checks authentication state
├── DashboardView() (.home tab)
├── MarketplaceView() (.market tab) 
├── CommunityView() (.community tab)
├── AssistantView() (.assistant tab)
└── ProfileView() (.profile tab)

// Unauthenticated flow
AuthenticationView() → OnboardingView → RoleSelectionView
```

### Deep Linking Pattern
```swift
// Use AppState for cross-tab navigation
appState.navigateToTab(.assistant, deepLink: .assistantOpenThread(id: "123"))
let pendingLink = appState.consumeDeepLink()
```

## Data Models & Managers

### Core Models (`Models/`)
- **User**: Role-based (farmer/seller), profile management
- **Crop**: Farmer's crop tracking, health monitoring
- **Product**: Marketplace items, category-based
- **Order**: Purchase flow, status tracking

### Service Managers (ObservableObject pattern)
- **UserManager**: Authentication, Firestore user data, profile updates
- **CartManager**: Shopping cart state, checkout flow
- **ProductManager**: Marketplace CRUD operations
- **CropManager**: Farmer-specific crop lifecycle management

## AI Integration (Assistant Feature)

### Gemini AI Service Pattern
```swift
// Initialize with API key from Secrets
_geminiService = State(initialValue: GeminiAIService(apiKey: Secrets.geminiAPIKey))

// Context-aware prompts based on user type and app state
context: AIContext(userType: .farmer, location: user.location, activeCrops: user.crops)
```

### Voice Integration
- VoiceTranscriptionService with silence detection
- Speech-to-text for agricultural queries
- Typing animation effects for AI responses

## Firebase Integration

### Authentication Flow
```swift
// Google Sign-In configured in AppDelegate
// UserManager.listenToAuthState() → loadUserFromFirestore()
// Role selection during signup stored in Firestore
```

### Firestore Structure
```
users/{uid} → { name, email, userType, profileImage, location, crops[] }
products/{productId} → marketplace items
orders/{orderId} → purchase transactions
```

## Build & Development

### Build Command
```bash
# Use the configured build task
xcodebuild -project Agrisense.xcodeproj -scheme Agrisense -sdk iphonesimulator -configuration Debug build
```

### Testing Strategy
- Unit tests in `AgrisenseTests/` for security, image compression
- UI tests in `AgrisenseUITests/` for critical user flows
- No test mocks in main app code - use CoreKit/MockServices.swift

### Common Gotchas
1. **Always check user authentication state** before accessing Firebase
2. **UserDefaults persistence** for dark mode, language preferences
3. **Cloudinary upload requires UNSIGNED presets** (configured server-side)
4. **Tab state management** - dismiss keyboards on tab switches
5. **Loading states** - use skeleton views, not just spinners

## Development Workflow

### When Adding New Features
1. Check if user role affects functionality (farmer vs seller)
2. Add localization keys to `*.lproj/Localizable.strings`
3. Use appropriate loading states from LoadingStateManager
4. Follow ObservableObject pattern for data management
5. Test with both user types and multiple languages

### File Organization
- `Views/` organized by feature area (Dashboard, Marketplace, Community, etc.)
- `CoreKit/` for dependency injection and service protocols
- `Utils/` for cross-cutting concerns (loading states, security, etc.)
- `Models/` for data structures and business logic managers

This architecture prioritizes role-based experiences, comprehensive localization, secure API integration, and maintainable state management patterns.