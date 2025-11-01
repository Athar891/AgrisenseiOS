# 🌾 AgriSense iOS

<div align="center">

![AgriSense Logo](screenshots/logo.png)

**An intelligent AI-powered agricultural assistant for modern farmers**

[![Platform](https://img.shields.io/badge/platform-iOS-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Firebase](https://img.shields.io/badge/Firebase-Integrated-yellow.svg)](https://firebase.google.com)

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Architecture](#-architecture) • [Technologies](#-technologies) • [Contributing](#-contributing)

</div>

---

## 📖 Overview

**AgriSense** is a comprehensive iOS application designed to empower farmers with cutting-edge AI technology, real-time market intelligence, and community support. Built with SwiftUI and Firebase, AgriSense combines advanced features like continuous voice AI assistance, crop management, market price tracking, and agricultural community networking into a single, intuitive platform.

### 🎯 Mission

To bridge the technology gap in agriculture by providing farmers with accessible, intelligent tools for better decision-making, increased productivity, and enhanced profitability.

---

## ✨ Features

### 🤖 Live AI Assistant (Krishi AI)

The crown jewel of AgriSense - an advanced voice-powered AI assistant with revolutionary continuous listening capabilities.

#### Key Capabilities:
- **Continuous Listening**: Always-on voice recognition that never stops listening
- **Real-time Interruption**: Interrupt the AI at any time while it's speaking
- **Wake Word Detection**: Activate with "Krishi AI" voice command
- **Context-Aware Conversations**: Maintains conversation history for relevant responses
- **Multi-modal Intelligence**: 
  - Voice-to-voice natural conversations
  - Screen sharing and visual analysis
  - Real-time camera feed analysis
  - Web search integration for latest information
- **Multi-language Support**: Available in English, Hindi, Bengali, Tamil, and Telugu
- **Intelligent Auto-Processing**: Automatically detects when you stop speaking and processes input
- **Subtitle Support**: Optional real-time subtitles for accessibility

#### AI Models Used:
- Primary: Gemini 2.0 Flash Experimental
- Fallback Chain: Gemini 2.0 Flash Thinking → Gemini 1.5 Flash → Gemini 1.5 Pro
- Smart model switching for optimal performance and reliability

#### Technical Highlights:
- Enhanced TTS (Text-to-Speech) with interruption support
- Advanced voice transcription with noise filtering
- Real-time audio level monitoring
- Automatic silence detection (1.2s threshold)
- Seamless state management (Standby → Listening → Thinking → Responding)

![Live AI Assistant](screenshots/live_ai_assistant.png)
![Voice Interaction](screenshots/voice_interaction.png)

---

### 📊 Smart Dashboard

Your agricultural command center with real-time insights and actionable data.

#### Features:
- **Weather Integration**: 
  - Current conditions and 7-day forecasts
  - Temperature, humidity, wind speed, and precipitation
  - Weather-based farming recommendations
  - Location-based automatic weather updates

- **Market Price Intelligence**:
  - Real-time Mandi (agricultural market) prices
  - Government data.gov.in API integration
  - Commodity price trends and analysis
  - Cached data for offline access
  - Price alerts and notifications

- **Crop Management Dashboard**:
  - Visual crop portfolio overview
  - Growth stage tracking
  - Health status monitoring
  - Quick access to crop details
  - Interactive crop cards with images

- **Quick Actions**:
  - Add new crops with one tap
  - Access soil testing information
  - View detailed market analysis
  - Navigate to weather details

![Dashboard](screenshots/dashboard.png)
![Weather View](screenshots/weather.png)
![Market Prices](screenshots/market_prices.png)

---

### 🌱 Comprehensive Crop Management

Professional-grade crop tracking and management tools.

#### Core Features:
- **Detailed Crop Profiles**:
  - Crop name, type, and variety
  - Planting and expected harvest dates
  - Field location and area size
  - Growth stage monitoring (Seedling → Vegetative → Flowering → Fruiting → Harvesting)
  - Health status tracking (Excellent → Good → Fair → Poor → Critical)

- **Visual Documentation**:
  - High-quality crop photos with Cloudinary integration
  - Image compression and optimization
  - Secure image upload with validation
  - Image gallery for crop history

- **Crop History & Analytics**:
  - Historical yield data
  - Growth pattern analysis
  - Treatment and intervention logs
  - Notes and observations

- **Smart Reminders**:
  - Watering schedules
  - Fertilizer application
  - Pesticide treatment
  - Harvest readiness alerts

- **Soil Testing Integration**:
  - Soil health monitoring
  - Nutrient level tracking
  - pH and moisture analysis
  - Fertilizer recommendations

![Crop Management](screenshots/crop_management.png)
![Add Crop](screenshots/add_crop.png)
![Crop Details](screenshots/crop_details.png)

---

### 🛒 Agricultural Marketplace

A comprehensive e-commerce platform for agricultural products and supplies.

#### Features:
- **Product Categories**:
  - Seeds and saplings
  - Fertilizers and pesticides
  - Agricultural equipment and tools
  - Organic products
  - Farm machinery

- **Shopping Experience**:
  - Intuitive product browsing
  - Advanced search and filters
  - Detailed product descriptions
  - High-quality product images
  - Price comparison

- **Cart & Checkout**:
  - Smart shopping cart management
  - Multiple payment options
  - Order tracking
  - Delivery address management
  - Order history and reordering

- **Seller Features**:
  - Product listing management
  - Inventory tracking
  - Sales analytics
  - Customer reviews and ratings

- **Security**:
  - Secure payment processing
  - Encrypted transactions
  - User data protection
  - Rate limiting to prevent abuse

![Marketplace](screenshots/marketplace.png)
![Product Details](screenshots/product_details.png)
![Shopping Cart](screenshots/cart.png)

---

### 👥 Community & Networking

Connect with fellow farmers, agricultural experts, and enthusiasts.

#### Features:
- **Discussion Forums**:
  - Topic-based discussions (Crops, Soil, Water, Pests, Market, Technology, General)
  - Post creation with rich text support
  - Like, comment, and share functionality
  - Tag-based organization
  - Real-time updates

- **Agricultural Events**:
  - Local farming events
  - Workshops and training sessions
  - Mandi (market) schedules
  - Government scheme announcements
  - Event registration and reminders

- **Expert Network**:
  - Connect with agricultural experts
  - Agronomists and soil scientists
  - Pest management specialists
  - Market analysts
  - Direct messaging and consultations

- **Community Groups**:
  - Join location-based farmer groups
  - Crop-specific communities
  - Organic farming networks
  - Technology adoption groups
  - Knowledge sharing platforms

![Community](screenshots/community.png)
![Discussions](screenshots/discussions.png)
![Events](screenshots/events.png)
![Experts](screenshots/experts.png)

---

### 👤 User Profile & Settings

Personalized experience with comprehensive user management.

#### Features:
- **Profile Management**:
  - Personal information editing
  - Profile photo upload (Cloudinary integration)
  - Location and contact details
  - Farm information

- **Authentication**:
  - Email/Password authentication
  - Google Sign-In integration
  - Secure session management
  - Password reset functionality
  - Account verification

- **Preferences**:
  - Language selection (5 languages supported)
  - Dark/Light mode toggle
  - Notification settings
  - Privacy controls
  - Data synchronization

- **Order Management**:
  - Order history and tracking
  - Saved addresses
  - Payment methods
  - Delivery preferences

- **App Settings**:
  - Cache management
  - Offline mode preferences
  - Audio and voice settings
  - Accessibility options

![Profile](screenshots/profile.png)
![Settings](screenshots/settings.png)

---

## 📱 Screenshots

### Onboarding & Authentication
<div align="center">
<img src="screenshots/splash_screen.png" width="250"/>
<img src="screenshots/login.png" width="250"/>
<img src="screenshots/signup.png" width="250"/>
</div>

### Core Features
<div align="center">
<img src="screenshots/dashboard_overview.png" width="250"/>
<img src="screenshots/ai_assistant_orb.png" width="250"/>
<img src="screenshots/crop_list.png" width="250"/>
</div>

### AI Assistant in Action
<div align="center">
<img src="screenshots/ai_listening.png" width="250"/>
<img src="screenshots/ai_thinking.png" width="250"/>
<img src="screenshots/ai_responding.png" width="250"/>
</div>

### Marketplace & Shopping
<div align="center">
<img src="screenshots/product_catalog.png" width="250"/>
<img src="screenshots/cart_view.png" width="250"/>
<img src="screenshots/checkout.png" width="250"/>
</div>

### Community Features
<div align="center">
<img src="screenshots/discussion_feed.png" width="250"/>
<img src="screenshots/event_details.png" width="250"/>
<img src="screenshots/expert_profile.png" width="250"/>
</div>

---

## 🚀 Installation

### Prerequisites

- **macOS**: Ventura (13.0) or later
- **Xcode**: 15.0 or later
- **iOS Deployment Target**: iOS 16.0+
- **Swift**: 5.9+
- **CocoaPods** or **Swift Package Manager**

### Required Accounts & API Keys

1. **Firebase Project**: 
   - Create a project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication, Firestore, and Storage
   
2. **Google Cloud**:
   - Enable Google Sign-In API
   - Get Gemini AI API key
   
3. **Cloudinary Account**:
   - For image storage and optimization
   - Get cloud name and upload preset
   
4. **Data.gov.in API Key**:
   - For Mandi price data
   - Register at [data.gov.in](https://data.gov.in)

### Setup Instructions

1. **Clone the Repository**
```bash
git clone https://github.com/Athar891/AgrisenseiOS.git
cd AgrisenseiOS
```

2. **Configure Firebase**
```bash
# Download GoogleService-Info.plist from Firebase Console
# Place it in the Agrisense/ directory
cp /path/to/GoogleService-Info.plist Agrisense/
```

3. **Set Up Secrets**

Create or update `Agrisense/Models/Secrets.swift`:

```swift
struct Secrets {
    // Gemini AI Configuration
    static let geminiAPIKey = "YOUR_GEMINI_API_KEY"
    
    // Cloudinary Configuration
    static let cloudinaryCloudName = "YOUR_CLOUD_NAME"
    static let cloudinaryUploadPreset = "YOUR_UPLOAD_PRESET"
    static let cloudinaryProductImagesPreset = "YOUR_PRODUCT_PRESET"
    
    // Mandi API Configuration
    static let mandiAPIKey = "YOUR_MANDI_API_KEY"
}
```

4. **Install Dependencies**

Using Swift Package Manager (recommended):
```bash
# Dependencies are automatically resolved by Xcode
# Just open the project and build
```

Or if using CocoaPods:
```bash
pod install
open Agrisense.xcworkspace
```

5. **Configure Firebase Rules**

Deploy the Firestore security rules:
```bash
firebase deploy --only firestore:rules
```

6. **Build and Run**
```bash
# Open in Xcode
open Agrisense.xcodeproj

# Or build from command line
xcodebuild -project Agrisense.xcodeproj -scheme Agrisense -sdk iphonesimulator -configuration Debug build
```

7. **Run Tests**
```bash
# Run unit tests
xcodebuild test -project Agrisense.xcodeproj -scheme Agrisense -destination 'platform=iOS Simulator,name=iPhone 15'

# Or use the test task
# Tests available: UnitTests.xctestplan, UITests.xctestplan
```

---

## 🏗️ Architecture

### Project Structure

```
AgriSense(iOS)/
├── Agrisense/
│   ├── AgrisenseApp.swift          # Main app entry point
│   ├── GoogleService-Info.plist    # Firebase configuration
│   ├── Info.plist                  # App configuration
│   │
│   ├── Models/                     # Data models and business logic
│   │   ├── UserManager.swift       # User authentication & profile
│   │   ├── CropManager.swift       # Crop data management
│   │   ├── CartManager.swift       # Shopping cart logic
│   │   ├── ProductManager.swift    # Product catalog management
│   │   ├── OrderManager.swift      # Order processing
│   │   ├── AddressManager.swift    # Address management
│   │   ├── MarketPriceManager.swift # Market data
│   │   ├── WeatherService.swift    # Weather integration
│   │   ├── LocationManager.swift   # GPS and location
│   │   ├── AppState.swift          # Global app state
│   │   └── Secrets.swift           # API keys (gitignored)
│   │
│   ├── Views/                      # SwiftUI views
│   │   ├── Assistant/              # AI Assistant UI
│   │   │   ├── LiveAIInteractionView.swift
│   │   │   ├── AssistantView.swift
│   │   │   ├── ChatGPTStyleOrb.swift
│   │   │   └── AnimatedGradientBorder.swift
│   │   │
│   │   ├── Dashboard/              # Dashboard views
│   │   │   ├── DashboardView.swift
│   │   │   ├── WeatherView.swift
│   │   │   ├── MarketPricesView.swift
│   │   │   ├── CropDetailView.swift
│   │   │   ├── AddCropView.swift
│   │   │   └── SoilTestView.swift
│   │   │
│   │   ├── Marketplace/            # E-commerce views
│   │   │   ├── MarketplaceView.swift
│   │   │   ├── CartView.swift
│   │   │   └── AddressViews.swift
│   │   │
│   │   ├── Community/              # Social features
│   │   │   ├── CommunityView.swift
│   │   │   ├── DiscussionsView.swift
│   │   │   ├── EventsView.swift
│   │   │   ├── ExpertsView.swift
│   │   │   ├── GroupsView.swift
│   │   │   └── NewPostView.swift
│   │   │
│   │   ├── Authentication/         # Auth flows
│   │   ├── Profile/                # User profile
│   │   └── Components/             # Reusable UI components
│   │
│   ├── Services/                   # Service layer
│   │   ├── AI/                     # AI services
│   │   │   ├── GeminiAIService.swift      # Google Gemini integration
│   │   │   ├── AIContextBuilder.swift     # Context management
│   │   │   └── AIModels.swift             # AI data models
│   │   │
│   │   ├── LiveAIService.swift            # Live AI orchestration
│   │   ├── VoiceTranscriptionService.swift # Speech-to-text
│   │   ├── EnhancedTTSService.swift       # Text-to-speech
│   │   ├── WakeWordDetectionService.swift # "Krishi AI" detection
│   │   ├── WebSearchService.swift         # Web search integration
│   │   ├── CameraService.swift            # Camera integration
│   │   ├── ScreenRecordingService.swift   # Screen sharing
│   │   └── MandiPriceService.swift        # Market price API
│   │
│   ├── Utils/                      # Utility classes
│   │   ├── SecureNetworkManager.swift     # Network security
│   │   ├── SecureStorage.swift            # Keychain wrapper
│   │   ├── ErrorHandling.swift            # Error management
│   │   ├── RateLimiter.swift              # Rate limiting
│   │   ├── ImageCompression.swift         # Image optimization
│   │   ├── ImageValidator.swift           # Image security
│   │   ├── InputValidator.swift           # Input validation
│   │   ├── NetworkMonitor.swift           # Connectivity monitoring
│   │   ├── AudioSessionManager.swift      # Audio management
│   │   └── FileManager+Extensions.swift   # File utilities
│   │
│   ├── CoreKit/                    # Core functionality
│   │   └── LocalizationManager.swift      # Multi-language support
│   │
│   ├── Assets.xcassets/            # Images and assets
│   └── Localizations/              # Language files
│       ├── en.lproj/               # English
│       ├── hi.lproj/               # Hindi
│       ├── bn.lproj/               # Bengali
│       ├── ta.lproj/               # Tamil
│       └── te.lproj/               # Telugu
│
├── AgrisenseTests/                 # Unit tests
├── AgrisenseUITests/               # UI tests
└── test-reports/                   # Test results

```

### Design Patterns

#### MVVM Architecture
- **Models**: Data structures and business logic
- **Views**: SwiftUI declarative UI
- **ViewModels**: `@ObservableObject` classes managing state

#### Service Layer Pattern
- Separation of concerns
- Reusable service classes
- Dependency injection

#### Repository Pattern
- Data access abstraction
- Firebase Firestore integration
- Local caching strategy

#### Observer Pattern
- Combine framework for reactive programming
- `@Published` properties for state management
- Real-time data synchronization

---

## 🛠️ Technologies

### Core Frameworks
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming and data flow
- **AVFoundation**: Audio/video capture and playback
- **Vision**: Image analysis and processing
- **CoreLocation**: GPS and location services
- **ReplayKit**: Screen recording capabilities

### Backend & Cloud Services
- **Firebase Authentication**: User management and OAuth
- **Firebase Firestore**: NoSQL cloud database
- **Firebase Storage**: File storage (alternative to Cloudinary)
- **Google Sign-In SDK**: OAuth integration

### AI & Machine Learning
- **Google Gemini AI**: Advanced language models
  - Gemini 2.0 Flash Experimental
  - Gemini 2.0 Flash Thinking
  - Gemini 1.5 Flash & Pro
- **Speech Recognition**: Apple's Speech framework
- **Natural Language Processing**: Context-aware conversations

### Third-Party Services
- **Cloudinary**: Image CDN and optimization
- **Data.gov.in API**: Government agricultural data
- **OpenWeatherMap** (or similar): Weather data

### Development Tools
- **Xcode**: 15.0+
- **Swift Package Manager**: Dependency management
- **XCTest**: Unit and UI testing
- **Git**: Version control

### Security & Performance
- **Keychain Services**: Secure credential storage
- **SSL Certificate Pinning**: Network security
- **Rate Limiting**: API protection
- **Image Validation**: Security scanning
- **Input Sanitization**: XSS and injection prevention

---

## 🔐 Security Features

### Data Protection
- **Secure Storage**: Keychain integration for sensitive data
- **Encrypted Communication**: HTTPS/TLS for all API calls
- **SSL Pinning**: Certificate validation for critical APIs
- **Token Management**: Secure OAuth token storage

### Input Validation
- **Image Validation**: Format, size, and content checks
- **Input Sanitization**: XSS and SQL injection prevention
- **Phone Number Validation**: Format verification
- **Email Validation**: RFC-compliant checking

### Rate Limiting
- **API Protection**: Request throttling per user
- **Image Upload Limits**: Prevents spam and abuse
- **Configurable Timeouts**: Per-endpoint limits
- **Automatic Retry**: With exponential backoff

### Privacy
- **GDPR Compliant**: User data handling
- **Privacy Settings**: User-controlled data sharing
- **Data Encryption**: At rest and in transit
- **Audit Logging**: Security event tracking

---

## 🌍 Localization

AgriSense supports **5 languages** to reach diverse farming communities:

| Language | Code | Regions |
|----------|------|---------|
| English | en | Global |
| Hindi | hi | North India |
| Bengali | bn | West Bengal, Bangladesh |
| Tamil | ta | Tamil Nadu, Sri Lanka |
| Telugu | te | Andhra Pradesh, Telangana |

### Implementation
- SwiftUI native localization
- `LocalizationManager` for runtime switching
- Separate `.strings` files per language
- RTL support ready (for future Arabic/Urdu)

---

## 🧪 Testing

### Unit Tests
```bash
# Run all unit tests
xcodebuild test -project Agrisense.xcodeproj -scheme Agrisense -testPlan UnitTests.xctestplan

# Test coverage
- UserManagerTests: Authentication and profile management
- SecurityUtilsTests: Security and validation
- EnhancedImageCompressionTests: Image processing
```

### UI Tests
```bash
# Run UI tests
xcodebuild test -project Agrisense.xcodeproj -scheme Agrisense -testPlan UITests.xctestplan
```

### Test Reports
- HTML reports generated in `test-reports/`
- Code coverage metrics
- Performance benchmarks

---

## 📈 Performance Optimization

### Image Optimization
- **Compression**: Automatic image compression before upload
- **CDN**: Cloudinary for fast global delivery
- **Lazy Loading**: On-demand image loading
- **Caching**: Local and CDN-level caching

### Network Optimization
- **Request Batching**: Combine multiple requests
- **Caching Strategy**: Offline-first approach
- **Background Sync**: Non-blocking data updates
- **Connection Monitoring**: Adaptive behavior

### AI Performance
- **Model Fallback**: Automatic switching on failures
- **Rate Limit Handling**: Smart retry mechanisms
- **Context Optimization**: Efficient prompt engineering
- **Response Streaming**: Progressive UI updates

### App Performance
- **Lazy Views**: On-demand view loading
- **Memory Management**: Proper lifecycle handling
- **Background Tasks**: Efficient resource usage
- **Battery Optimization**: Power-efficient operations

---

## 🚧 Known Issues & Limitations

### Current Limitations
1. **Offline Mode**: Limited functionality without internet
2. **Voice Recognition**: Requires quiet environment for best results
3. **Image Upload**: 1MB size limit per image
4. **API Rate Limits**: Daily quotas on external APIs

### Planned Improvements
- [ ] Offline crop database
- [ ] Noise cancellation for voice input
- [ ] Batch image upload
- [ ] Premium tier with higher limits

---

## 🗺️ Roadmap

### Phase 1: Core Enhancement (Q1 2026)
- [ ] Improved offline capabilities
- [ ] Advanced crop disease detection using ML
- [ ] Weather-based crop recommendations
- [ ] Push notifications for price alerts

### Phase 2: Social Features (Q2 2026)
- [ ] Video tutorials and courses
- [ ] Live expert consultations
- [ ] Farmer-to-farmer marketplace
- [ ] Success stories and case studies

### Phase 3: Advanced AI (Q3 2026)
- [ ] Predictive yield analytics
- [ ] Pest outbreak predictions
- [ ] Market trend forecasting
- [ ] Personalized farming calendar

### Phase 4: Expansion (Q4 2026)
- [ ] More language support (Punjabi, Marathi, Kannada)
- [ ] Government scheme integration
- [ ] Loan and insurance assistance
- [ ] Supply chain tracking

---

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

### Getting Started
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines
- Follow Swift style guide and conventions
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting

### Areas for Contribution
- 🌐 Additional language translations
- 🐛 Bug fixes and issue resolution
- 📱 UI/UX improvements
- 🧪 Test coverage expansion
- 📚 Documentation enhancements
- ✨ New feature development

### Code Review Process
1. All PRs require at least one review
2. CI/CD checks must pass
3. Documentation must be updated
4. Tests must be included

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 Athar Reza

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 👨‍💻 Author

**Athar Reza**
- GitHub: [@Athar891](https://github.com/Athar891)
- Email: [contact@agrisense.app](mailto:contact@agrisense.app)
- LinkedIn: [Athar Reza](https://linkedin.com/in/athar-reza)

---

## 🙏 Acknowledgments

### Open Source Libraries
- [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk)
- [Google Sign-In iOS](https://github.com/google/GoogleSignIn-iOS)
- [SDWebImage](https://github.com/SDWebImage/SDWebImage)

### APIs & Services
- **Google Gemini AI**: Advanced AI capabilities
- **Firebase**: Backend infrastructure
- **Cloudinary**: Image management
- **Data.gov.in**: Government agricultural data
- **OpenWeatherMap**: Weather data

### Inspiration
- Agricultural communities worldwide
- Digital India initiatives
- Farmers who inspired this project

---

## 📞 Support

### Getting Help
- 📧 Email: support@agrisense.app
- 💬 Discord: [Join our community](https://discord.gg/agrisense)
- 🐛 Issues: [GitHub Issues](https://github.com/Athar891/AgrisenseiOS/issues)
- 📖 Wiki: [Documentation](https://github.com/Athar891/AgrisenseiOS/wiki)

### FAQ

**Q: Do I need an internet connection?**  
A: Yes, most features require internet. Limited offline functionality is available.

**Q: Is my data secure?**  
A: Yes, we use industry-standard encryption and security practices.

**Q: Which iOS versions are supported?**  
A: iOS 16.0 and later.

**Q: Is AgriSense free?**  
A: Core features are free. Premium features planned for future releases.

**Q: Can I use this for commercial farming?**  
A: Yes, AgriSense is suitable for farms of all sizes.

---

## 📊 Project Statistics

![GitHub stars](https://img.shields.io/github/stars/Athar891/AgrisenseiOS?style=social)
![GitHub forks](https://img.shields.io/github/forks/Athar891/AgrisenseiOS?style=social)
![GitHub issues](https://img.shields.io/github/issues/Athar891/AgrisenseiOS)
![GitHub pull requests](https://img.shields.io/github/issues-pr/Athar891/AgrisenseiOS)
![GitHub last commit](https://img.shields.io/github/last-commit/Athar891/AgrisenseiOS)
![GitHub code size](https://img.shields.io/github/languages/code-size/Athar891/AgrisenseiOS)

---

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Athar891/AgrisenseiOS&type=Date)](https://star-history.com/#Athar891/AgrisenseiOS&Date)

---

<div align="center">

**Made with ❤️ for farmers everywhere**

**Empowering Agriculture Through Technology**

[⬆ Back to Top](#-agrisense-ios)

</div>
