# 📦 Installation Guide

Complete setup instructions for AgriSense iOS development environment.

---

## 📋 Prerequisites

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **iOS Deployment Target**: iOS 16.0+
- **RAM**: Minimum 8GB (16GB recommended)
- **Disk Space**: At least 10GB free space

### Required Software

1. **Xcode**
   ```bash
   # Install from Mac App Store or download from
   # https://developer.apple.com/xcode/
   
   # Verify installation
   xcodebuild -version
   ```

2. **Command Line Tools**
   ```bash
   xcode-select --install
   ```

3. **Git**
   ```bash
   # Check if Git is installed
   git --version
   
   # If not installed, it will prompt for installation
   ```

4. **CocoaPods** (Optional, if needed for dependencies)
   ```bash
   sudo gem install cocoapods
   pod --version
   ```

---

## 🔧 Development Environment

### 1. Clone the Repository

```bash
# Clone the repository
git clone https://github.com/Athar891/AgrisenseiOS.git

# Navigate to project directory
cd AgrisenseiOS

# Check current branch
git branch
```

### 2. Firebase Setup

#### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Add iOS app to your Firebase project
4. Download `GoogleService-Info.plist`

#### Configure Firebase

```bash
# Place GoogleService-Info.plist in Agrisense folder
cp ~/Downloads/GoogleService-Info.plist ./Agrisense/
```

**Important**: Ensure `GoogleService-Info.plist` is added to Xcode target:
- Open Xcode
- Drag `GoogleService-Info.plist` to Agrisense folder
- Check "Copy items if needed"
- Select Agrisense target

#### Firebase Services to Enable

1. **Authentication**
   - Email/Password provider
   - Google Sign-In provider
   - Phone authentication (optional)

2. **Cloud Firestore**
   - Create database in production mode
   - Set up security rules (see [Firebase Integration](Firebase-Integration.md))

3. **Cloud Storage**
   - Enable storage bucket
   - Configure storage rules

4. **Cloud Functions** (if using)
   - Set up Node.js functions

### 3. API Keys Configuration

Create `Secrets.swift` in `Agrisense/Models/` directory:

```swift
// Agrisense/Models/Secrets.swift
import Foundation

enum Secrets {
    // OpenWeatherMap API Key
    static let weatherAPIKey = "YOUR_OPENWEATHER_API_KEY"
    
    // Google Gemini AI API Key
    static let geminiAPIKey = "YOUR_GEMINI_API_KEY"
    
    // Cloudinary Configuration
    static let cloudinaryCloudName = "YOUR_CLOUD_NAME"
    static let cloudinaryUploadPreset = "YOUR_UPLOAD_PRESET"
    
    // Government Data API (if required)
    static let govDataAPIKey = "YOUR_GOV_DATA_API_KEY" // Optional
}
```

#### Getting API Keys

1. **OpenWeatherMap API**
   - Sign up at [OpenWeatherMap](https://openweathermap.org/api)
   - Navigate to API Keys section
   - Copy your API key

2. **Google Gemini AI API**
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Sign in with Google account
   - Create API key
   - Copy the API key

3. **Cloudinary**
   - Sign up at [Cloudinary](https://cloudinary.com/)
   - Go to Dashboard
   - Note your Cloud Name
   - Create an unsigned upload preset:
     - Settings → Upload → Upload presets
     - Add upload preset (unsigned)

4. **Government Data API** (Optional)
   - Visit [data.gov.in](https://data.gov.in/)
   - Register for API access
   - Request API key

### 4. Google Sign-In Setup

#### Configure OAuth Client

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to APIs & Services → Credentials
4. Create OAuth 2.0 Client ID:
   - Application Type: iOS
   - Bundle ID: `com.yourcompany.agrisense`
   - Download the configuration

#### Update Info.plist

Add URL scheme to `Agrisense/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

### 5. Project Configuration

#### Update Bundle Identifier

1. Open project in Xcode
2. Select Agrisense target
3. Go to Signing & Capabilities
4. Update Bundle Identifier to your unique identifier
5. Select your development team

#### Capabilities to Enable

- **Background Modes**
  - Audio, AirPlay, and Picture in Picture
  - Background fetch
  - Remote notifications

- **Push Notifications**
  - Enable push notifications capability

- **App Groups** (if using)
  - Add app group identifier

---

## 🏗 Building the Project

### 1. Open in Xcode

```bash
# Open the project
open Agrisense.xcodeproj
```

### 2. Select Scheme

1. In Xcode, select scheme: **Agrisense**
2. Select target device or simulator
3. Recommended: iPhone 14 Pro or later simulator

### 3. Install Dependencies

The project uses Swift Package Manager for dependencies. Xcode will automatically resolve packages on first build.

**If you encounter issues:**

```bash
# In Xcode
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
```

### 4. Build the Project

**Option 1: Using Xcode**
- Press `⌘B` (Command + B) to build
- Press `⌘R` (Command + R) to build and run

**Option 2: Using Command Line**

```bash
# Build for simulator
xcodebuild -project Agrisense.xcodeproj \
  -scheme Agrisense \
  -sdk iphonesimulator \
  -configuration Debug \
  build

# Or use the task (if configured)
# See .vscode/tasks.json
```

### 5. Run on Simulator

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 14 Pro"

# Run the app
xcodebuild -project Agrisense.xcodeproj \
  -scheme Agrisense \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  build
```

### 6. Run on Physical Device

1. **Connect device** via USB
2. **Trust computer** on device
3. **Select device** in Xcode
4. **Enable Developer Mode** on iOS device:
   - Settings → Privacy & Security → Developer Mode
5. **Build and Run** (`⌘R`)

---

## 🔍 Verification

### Test Basic Functionality

After installation, verify:

1. **App Launches** ✅
   - No crashes on launch
   - Splash screen appears

2. **Authentication** ✅
   - Email/Password sign-up works
   - Google Sign-In works
   - Sign-out functionality

3. **Firebase Connection** ✅
   - Check Xcode console for Firebase initialization logs
   - Test Firestore read/write

4. **API Integration** ✅
   - Weather data loads
   - Market prices fetch successfully

5. **AI Assistant** ✅
   - Voice recognition activates
   - Gemini AI responds correctly

### Check Logs

Look for these success messages in Xcode console:

```
✅ Firebase configured successfully
✅ Google Sign-In initialized
✅ Location services authorized
✅ Weather data fetched
✅ Gemini AI service ready
```

---

## 🐛 Common Issues

### Issue: Build Fails with Package Resolution Error

**Solution:**
```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Reset package caches in Xcode
File → Packages → Reset Package Caches
```

### Issue: GoogleService-Info.plist Not Found

**Solution:**
1. Verify file is in `Agrisense/` directory
2. Check file is added to Agrisense target
3. Clean build folder (`⌘⇧K`)
4. Rebuild project

### Issue: Code Signing Error

**Solution:**
1. Go to Signing & Capabilities
2. Enable "Automatically manage signing"
3. Select your team
4. Change bundle identifier if needed

### Issue: Simulator Not Running

**Solution:**
```bash
# Kill all simulator processes
killall Simulator

# Reset simulator
xcrun simctl erase all

# Reboot simulator
xcrun simctl boot "iPhone 14 Pro"
```

### Issue: Firebase Not Connecting

**Solution:**
1. Verify `GoogleService-Info.plist` is correct
2. Check Firebase project settings
3. Ensure bundle ID matches Firebase configuration
4. Check internet connection

---

## 🔄 Updating Dependencies

### Swift Packages

```bash
# In Xcode
File → Packages → Update to Latest Package Versions
```

### Firebase

```bash
# Check for Firebase updates
# Xcode will notify of available updates
# Or manually update in Package Dependencies
```

---

## 📚 Next Steps

After successful installation:

1. **[Quick Start Guide](Quick-Start.md)** - Build your first feature
2. **[Project Architecture](Project-Architecture.md)** - Understand the codebase
3. **[Contributing Guide](Contributing.md)** - Start contributing

---

## 💡 Tips

- **Use Simulator Shortcuts**: 
  - `⌘K` - Toggle keyboard
  - `⌘→` - Rotate right
  - `⌘⇧H` - Home button

- **Debug Efficiently**:
  - Enable Zombie Objects for memory debugging
  - Use View Debugger (`Debug → View Debugging → Capture View Hierarchy`)
  - Profile with Instruments (`⌘I`)

- **Version Control**:
  - Create feature branches for development
  - Commit frequently with meaningful messages
  - Pull latest changes regularly

---

## 🆘 Getting Help

If you encounter issues:

1. Check [Troubleshooting Guide](Troubleshooting.md)
2. Search [GitHub Issues](https://github.com/Athar891/AgrisenseiOS/issues)
3. Create new issue with:
   - Xcode version
   - iOS version
   - Error messages
   - Steps to reproduce

---

**Ready to start developing?** → [Quick Start Guide](Quick-Start.md)
