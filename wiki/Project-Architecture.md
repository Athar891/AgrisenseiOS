# 🏗 Project Architecture

Comprehensive overview of AgriSense iOS application architecture, design patterns, and system organization.

---

## 📐 Architecture Overview

AgriSense follows the **MVVM (Model-View-ViewModel)** architecture pattern with additional service layers for complex business logic. The application is built using SwiftUI and follows Apple's modern app development guidelines.

```
┌─────────────────────────────────────────────────────────┐
│                      Presentation Layer                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │              SwiftUI Views                        │  │
│  │  • Dashboard • Marketplace • Crop Management     │  │
│  │  • AI Assistant • Community • Profile            │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                    ViewModel Layer                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │          @StateObject / @ObservableObject         │  │
│  │  • AppState • UserManager • CropManager          │  │
│  │  • CartManager • OrderManager                     │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                     Service Layer                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │  • LiveAIService • WeatherService                │  │
│  │  • EnhancedTTSService • VoiceTranscription       │  │
│  │  • GeminiAIService • MandiPriceService           │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                      Model Layer                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  • Crop • User • Order • Product                 │  │
│  │  • WeatherData • MarketPrice • Community         │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                   │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Firebase • Cloudinary • APIs • Local Storage    │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Design Patterns

### 1. MVVM (Model-View-ViewModel)

**Purpose**: Separation of concerns, testability, and maintainability

**Implementation**:
- **Model**: Data structures and business logic
- **View**: SwiftUI views with minimal logic
- **ViewModel**: Observable objects managing state and business logic

**Example**:
```swift
// Model
struct Crop: Identifiable, Codable {
    let id: String
    var name: String
    var type: CropType
    var healthStatus: HealthStatus
}

// ViewModel
class CropManager: ObservableObject {
    @Published var crops: [Crop] = []
    @Published var isLoading = false
    
    func fetchCrops() async throws {
        // Business logic
    }
}

// View
struct CropListView: View {
    @StateObject private var cropManager = CropManager()
    
    var body: some View {
        List(cropManager.crops) { crop in
            CropRowView(crop: crop)
        }
    }
}
```

### 2. Repository Pattern

**Purpose**: Abstract data layer and provide single source of truth

**Implementation**:
- Managers act as repositories
- Centralized data access
- Caching strategies

**Example**:
```swift
class UserManager: ObservableObject {
    @Published var currentUser: User?
    private let db = Firestore.firestore()
    
    func fetchUser(id: String) async throws -> User {
        // Fetch from Firebase
    }
    
    func updateUser(_ user: User) async throws {
        // Update in Firebase
    }
}
```

### 3. Service Layer Pattern

**Purpose**: Encapsulate complex business logic and external integrations

**Services**:
- `LiveAIService`: AI assistant orchestration
- `GeminiAIService`: Gemini API integration
- `WeatherService`: Weather data fetching
- `EnhancedTTSService`: Text-to-speech
- `VoiceTranscriptionService`: Speech-to-text
- `MandiPriceService`: Market price data

### 4. Singleton Pattern

**Used For**: Shared resources and managers

**Examples**:
```swift
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    private init() {}
}

class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}
}
```

### 5. Observer Pattern

**Implementation**: Combine framework with `@Published` properties

```swift
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isDarkMode = false
    @Published var selectedLanguage: String = "en"
}
```

### 6. Factory Pattern

**Used For**: Model creation and initialization

```swift
struct AIContextBuilder {
    static func buildContext(
        conversationHistory: [Message],
        screenContent: String?,
        cameraFeed: UIImage?
    ) -> AIContext {
        // Build and return context
    }
}
```

### 7. Strategy Pattern

**Used For**: AI model selection and fallback

```swift
class GeminiAIService {
    private var modelStrategy: [AIModel] = [
        .flash2Experimental,
        .flash2Thinking,
        .flash15,
        .pro15
    ]
    
    func processWithFallback() async throws -> Response {
        for model in modelStrategy {
            do {
                return try await process(with: model)
            } catch {
                continue // Try next model
            }
        }
        throw AIError.allModelsFailed
    }
}
```

---

## 📁 Directory Structure

```
AgriSense(iOS)/
├── Agrisense/
│   ├── AgrisenseApp.swift          # App entry point
│   ├── GoogleService-Info.plist    # Firebase config
│   ├── Info.plist                  # App configuration
│   │
│   ├── Models/                     # Data models & managers
│   │   ├── Crop.swift
│   │   ├── UserManager.swift
│   │   ├── CartManager.swift
│   │   ├── OrderManager.swift
│   │   ├── ProductManager.swift
│   │   ├── CropManager.swift
│   │   ├── WeatherData.swift
│   │   ├── MarketPrice.swift
│   │   ├── AppState.swift
│   │   └── ...
│   │
│   ├── Views/                      # SwiftUI views
│   │   ├── Dashboard/
│   │   │   ├── DashboardView.swift
│   │   │   ├── WeatherCard.swift
│   │   │   └── MandiPriceCard.swift
│   │   ├── Assistant/
│   │   │   ├── LiveAIView.swift
│   │   │   └── VoiceIndicatorView.swift
│   │   ├── Marketplace/
│   │   │   ├── MarketplaceView.swift
│   │   │   ├── ProductListView.swift
│   │   │   └── CartView.swift
│   │   ├── Authentication/
│   │   ├── Community/
│   │   ├── Profile/
│   │   └── Components/             # Reusable components
│   │
│   ├── Services/                   # Business logic services
│   │   ├── AI/
│   │   │   ├── GeminiAIService.swift
│   │   │   ├── AIModels.swift
│   │   │   └── AIContextBuilder.swift
│   │   ├── LiveAIService.swift
│   │   ├── EnhancedTTSService.swift
│   │   ├── VoiceTranscriptionService.swift
│   │   ├── WakeWordDetectionService.swift
│   │   ├── WeatherService.swift
│   │   ├── MandiPriceService.swift
│   │   ├── CameraService.swift
│   │   └── WebSearchService.swift
│   │
│   ├── Utils/                      # Utility classes
│   │   ├── NetworkMonitor.swift
│   │   ├── SecureStorage.swift
│   │   ├── ErrorHandling.swift
│   │   ├── ImageCompression.swift
│   │   ├── AudioSessionManager.swift
│   │   └── ...
│   │
│   ├── CoreKit/                    # Core functionality
│   │   └── LocalizationManager.swift
│   │
│   ├── Assets.xcassets/            # Images and assets
│   └── Localization/               # Multi-language support
│       ├── en.lproj/
│       ├── hi.lproj/
│       ├── bn.lproj/
│       ├── ta.lproj/
│       └── te.lproj/
│
├── AgrisenseTests/                 # Unit tests
├── AgrisenseUITests/               # UI tests
├── Screenshots/                    # App screenshots
└── Agrisense.xcodeproj/           # Xcode project
```

---

## 🔄 Data Flow

### Authentication Flow

```
┌──────────────┐
│  LoginView   │
└──────┬───────┘
       │ User enters credentials
       ↓
┌──────────────┐
│ UserManager  │
└──────┬───────┘
       │ Firebase Auth
       ↓
┌──────────────┐
│   Firebase   │
└──────┬───────┘
       │ Auth Token
       ↓
┌──────────────┐
│   AppState   │ Updates isAuthenticated
└──────┬───────┘
       │
       ↓
┌──────────────┐
│ DashboardView│ Navigates to main view
└──────────────┘
```

### AI Assistant Flow

```
┌──────────────────┐
│   LiveAIView     │
└────────┬─────────┘
         │ User speaks
         ↓
┌────────────────────┐
│ WakeWordDetection  │ Detects "Krishi AI"
└────────┬───────────┘
         │ Activates listening
         ↓
┌────────────────────┐
│VoiceTranscription  │ Converts speech to text
└────────┬───────────┘
         │ Transcribed text
         ↓
┌────────────────────┐
│  LiveAIService     │ Orchestrates AI logic
└────────┬───────────┘
         │ Builds context
         ↓
┌────────────────────┐
│ GeminiAIService    │ Sends to Gemini API
└────────┬───────────┘
         │ AI response
         ↓
┌────────────────────┐
│ EnhancedTTSService │ Converts text to speech
└────────┬───────────┘
         │ Plays audio
         ↓
┌────────────────────┐
│   LiveAIView       │ Updates UI with response
└────────────────────┘
```

### Crop Management Flow

```
┌──────────────┐
│ AddCropView  │
└──────┬───────┘
       │ User adds crop
       ↓
┌──────────────┐
│ CropManager  │ Validates input
└──────┬───────┘
       │ Upload image
       ↓
┌──────────────┐
│  Cloudinary  │ Returns image URL
└──────┬───────┘
       │ Image URL
       ↓
┌──────────────┐
│   Firestore  │ Saves crop data
└──────┬───────┘
       │ Success
       ↓
┌──────────────┐
│ CropManager  │ Updates @Published crops
└──────┬───────┘
       │
       ↓
┌──────────────┐
│ CropListView │ Displays updated list
└──────────────┘
```

---

## 🔐 Security Architecture

### Layers of Security

1. **Authentication Layer**
   - Firebase Authentication
   - Secure token storage
   - Biometric authentication support

2. **Network Layer**
   - HTTPS only
   - Certificate pinning
   - Request encryption

3. **Data Layer**
   - Encrypted local storage (Keychain)
   - Firestore security rules
   - Input validation

4. **API Layer**
   - Rate limiting
   - API key rotation
   - Request signing

See [Security Documentation](Security.md) for details.

---

## ⚡ Performance Optimizations

### 1. Lazy Loading
- Images loaded on-demand
- Firestore pagination
- Lazy stacks in lists

### 2. Caching
- Weather data cached (30 min)
- Market prices cached (1 hour)
- Image caching with URLCache

### 3. Background Processing
- Image compression in background
- Async/await for network calls
- Background tasks for updates

### 4. Memory Management
- Weak references for delegates
- Image downsampling
- Proper deallocation

---

## 🧪 Testing Architecture

### Unit Tests
- Model validation
- Manager logic
- Utility functions

### UI Tests
- User flows
- Navigation
- Form validation

### Integration Tests
- Firebase integration
- API communication
- Service interactions

See [Testing Guide](Testing-Guide.md) for details.

---

## 🌐 Networking Architecture

### API Structure

```swift
protocol APIService {
    func fetch<T: Decodable>(_ endpoint: String) async throws -> T
}

class SecureNetworkManager: APIService {
    private let session: URLSession
    private let rateLimiter: RateLimiter
    
    func fetch<T: Decodable>(_ endpoint: String) async throws -> T {
        // Rate limiting
        try await rateLimiter.checkLimit()
        
        // Build request
        let request = try buildRequest(endpoint)
        
        // Execute with retry
        return try await executeWithRetry(request)
    }
}
```

### Retry Mechanism

```swift
class RetryMechanism {
    func executeWithRetry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: () async throws -> T
    ) async throws -> T {
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                if attempt == maxAttempts { throw error }
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        throw NetworkError.maxRetriesExceeded
    }
}
```

---

## 📱 State Management

### Global State

```swift
// AppState.swift
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isDarkMode = false
    @Published var selectedLanguage = "en"
    @Published var currentUser: User?
}
```

### Feature-Specific State

```swift
// CropManager.swift
class CropManager: ObservableObject {
    @Published var crops: [Crop] = []
    @Published var isLoading = false
    @Published var error: Error?
}
```

### View-Local State

```swift
// CropDetailView.swift
struct CropDetailView: View {
    @State private var isEditing = false
    @State private var showAlert = false
}
```

---

## 🔌 Dependency Injection

### Environment Objects

```swift
// App level
@main
struct AgrisenseApp: App {
    @StateObject private var userManager = UserManager()
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userManager)
                .environmentObject(appState)
        }
    }
}

// View level
struct DashboardView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
}
```

---

## 🎨 UI Architecture

### Component Hierarchy

```
ContentView
├── MainTabView
│   ├── DashboardView
│   │   ├── WeatherCard
│   │   ├── MandiPriceCard
│   │   └── CropSummaryCard
│   ├── MarketplaceView
│   │   ├── ProductGrid
│   │   └── CategoryFilter
│   ├── LiveAIView
│   │   ├── VoiceIndicator
│   │   └── TranscriptView
│   ├── CommunityView
│   └── ProfileView
└── Components (Shared)
    ├── CustomButton
    ├── LoadingView
    ├── ErrorView
    └── ImagePicker
```

---

## 📊 Analytics & Monitoring

### Event Tracking

```swift
enum AnalyticsEvent {
    case userSignUp
    case cropAdded
    case productPurchased
    case aiQueryMade
}

class AnalyticsManager {
    func track(_ event: AnalyticsEvent) {
        // Firebase Analytics
    }
}
```

---

## 🚀 Next Steps

- [Code Structure](Code-Structure.md) - Detailed file organization
- [Services Architecture](Services-Architecture.md) - Service layer details
- [Firebase Integration](Firebase-Integration.md) - Backend integration
- [AI & ML Integration](AI-ML-Integration.md) - AI implementation

---

**Questions?** Check the [FAQ](FAQ.md) or [create an issue](https://github.com/Athar891/AgrisenseiOS/issues).
