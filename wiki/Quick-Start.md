# 🚀 Quick Start Guide

Get up and running with AgriSense iOS development in just 5 minutes!

---

## ⚡ Prerequisites Check

Before starting, ensure you have:

- ✅ macOS 13.0+ installed
- ✅ Xcode 15.0+ installed
- ✅ Git installed
- ✅ GitHub account (for cloning)

**Don't have these?** → See [Installation Guide](Installation-Guide.md)

---

## 🎯 5-Minute Setup

### Step 1: Clone Repository (1 min)

```bash
# Clone the repository
git clone https://github.com/Athar891/AgrisenseiOS.git

# Navigate to directory
cd AgrisenseiOS
```

### Step 2: Open in Xcode (1 min)

```bash
# Open project
open Agrisense.xcodeproj
```

Wait for Xcode to:
- Load project
- Index files
- Resolve Swift packages (automatic)

### Step 3: Quick Firebase Setup (2 min)

1. **Get Firebase Config**:
   - Visit [Firebase Console](https://console.firebase.google.com/)
   - Use existing project or create new one
   - Download `GoogleService-Info.plist`

2. **Add to Project**:
   ```bash
   # Copy to Agrisense folder
   cp ~/Downloads/GoogleService-Info.plist ./Agrisense/
   ```

3. **Verify in Xcode**:
   - File should appear in Agrisense folder
   - Target membership: Agrisense ✅

### Step 4: Add API Keys (1 min)

Create `Secrets.swift` in `Agrisense/Models/`:

```swift
import Foundation

enum Secrets {
    static let weatherAPIKey = "YOUR_KEY_HERE"  // Get from openweathermap.org
    static let geminiAPIKey = "YOUR_KEY_HERE"   // Get from ai.google.dev
    static let cloudinaryCloudName = "YOUR_CLOUD_NAME"
    static let cloudinaryUploadPreset = "YOUR_PRESET"
}
```

**Quick API Keys** (Optional for first run):
- Weather: [openweathermap.org](https://openweathermap.org/api) (Free tier)
- Gemini AI: [ai.google.dev](https://ai.google.dev/) (Free tier)
- Cloudinary: [cloudinary.com](https://cloudinary.com/) (Free tier)

### Step 5: Build & Run (30 sec)

1. Select target: **Agrisense**
2. Select device: **iPhone 14 Pro** (or any simulator)
3. Press `⌘R` (Command + R)
4. Wait for build... ⏳
5. App launches! 🎉

---

## 🎮 First Run

### What You'll See

1. **Splash Screen** - AgriSense logo
2. **Welcome Screen** - App introduction
3. **Sign In/Sign Up** - Authentication screen

### Create Test Account

```
Email: test@agrisense.com
Password: TestPassword123!
```

Or use **Google Sign-In** for faster setup.

---

## 🧭 Quick Tour

### Main Features to Explore

#### 1. Dashboard (Home) 🏠
- Weather information
- Market prices
- Quick actions

#### 2. AI Assistant 🤖
- Tap microphone icon
- Say "Krishi AI" to activate
- Ask a question about farming

#### 3. Crop Management 🌱
- Tap "Add Crop" button
- Fill in crop details
- View your crop portfolio

#### 4. Marketplace 🛒
- Browse products
- Add to cart
- Checkout flow

---

## 💻 Development Workflow

### Making Changes

```bash
# Create feature branch
git checkout -b feature/my-new-feature

# Make your changes in Xcode

# Build and test
⌘B  # Build
⌘R  # Run
⌘U  # Test

# Commit changes
git add .
git commit -m "Add: my new feature"

# Push to GitHub
git push origin feature/my-new-feature
```

### Testing Your Changes

```bash
# Run unit tests
⌘U

# Or via command line
xcodebuild test \
  -project Agrisense.xcodeproj \
  -scheme Agrisense \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro'
```

---

## 🎨 Quick Customization

### Change App Theme

```swift
// Agrisense/Models/AppState.swift
@Published var isDarkMode = true  // Change to true for dark mode
```

### Change Default Language

```swift
// Agrisense/CoreKit/LocalizationManager.swift
@Published var currentLanguage = "hi"  // "hi" for Hindi, "en" for English
```

### Modify AI Assistant Voice

```swift
// Agrisense/Services/EnhancedTTSService.swift
utterance.rate = 0.6        // Speed (0.0 - 1.0)
utterance.pitchMultiplier = 1.2  // Pitch (0.5 - 2.0)
```

---

## 🔧 Common Tasks

### Add New View

1. **Create SwiftUI View**:
   ```swift
   // Agrisense/Views/MyNewView.swift
   import SwiftUI
   
   struct MyNewView: View {
       var body: some View {
           Text("Hello, AgriSense!")
       }
   }
   ```

2. **Add to Navigation**:
   ```swift
   // In parent view
   NavigationLink("Go to My View") {
       MyNewView()
   }
   ```

### Add New Model

```swift
// Agrisense/Models/MyModel.swift
import Foundation

struct MyModel: Identifiable, Codable {
    let id: String
    var name: String
    var createdAt: Date
}
```

### Add New Service

```swift
// Agrisense/Services/MyService.swift
import Foundation

class MyService: ObservableObject {
    @Published var data: [MyModel] = []
    
    func fetchData() async throws {
        // Fetch logic here
    }
}
```

---

## 📱 Test on Real Device

### Setup

1. **Connect iPhone** via USB
2. **Trust Computer** (on device)
3. **Enable Developer Mode**:
   - Settings → Privacy & Security → Developer Mode → ON
4. **Select Device** in Xcode
5. **Build & Run** (`⌘R`)

### First Time Setup

- Xcode will register device automatically
- May need to verify in Settings → General → VPN & Device Management

---

## 🐛 Quick Fixes

### Build Fails?

```bash
# Clean build folder
⌘⇧K

# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Rebuild
⌘B
```

### Packages Won't Resolve?

```bash
# In Xcode menu
File → Packages → Reset Package Caches
File → Packages → Resolve Package Versions
```

### Simulator Issues?

```bash
# Reset simulator
xcrun simctl erase all

# Restart simulator
killall Simulator
```

### Firebase Connection Issues?

1. Check `GoogleService-Info.plist` is present
2. Verify bundle ID matches Firebase config
3. Check internet connection
4. Look for errors in console

---

## 📖 What's Next?

### Learn the Architecture

- **[Project Architecture](Project-Architecture.md)** - Understand the codebase
- **[Code Structure](Code-Structure.md)** - File organization
- **[Design Patterns](Design-Patterns.md)** - Coding patterns used

### Explore Features

- **[Live AI Assistant](Live-AI-Assistant.md)** - Krishi AI deep dive
- **[Crop Management](Crop-Management.md)** - Crop system details
- **[Marketplace](Marketplace.md)** - E-commerce implementation

### Start Contributing

- **[Contributing Guide](Contributing.md)** - How to contribute
- **[Coding Standards](Coding-Standards.md)** - Code style guide
- **[Testing Guide](Testing-Guide.md)** - Writing tests

---

## 💡 Pro Tips

### Xcode Shortcuts

```
⌘B         Build
⌘R         Run
⌘.         Stop
⌘U         Test
⌘⇧K        Clean
⌘⇧Y        Show/Hide Console
⌘⇧O        Quick Open
⌘⌥J        Jump to Definition
⌘/         Comment/Uncomment
```

### Debugging

```
po variableName           Print object in console
p variableName            Print value
expr variableName = value Modify at runtime
```

### Simulator Controls

```
⌘K         Toggle keyboard
⌘→         Rotate right
⌘←         Rotate left
⌘⇧H        Home button
⌘⇧H (2x)   App switcher
```

---

## 🎯 Challenge: Your First Feature

### Goal: Add a "Hello Farmer" Banner

**Time**: ~10 minutes

**Steps**:

1. **Open DashboardView.swift**
   ```bash
   # Quick open in Xcode
   ⌘⇧O → Type "DashboardView" → Enter
   ```

2. **Add Banner at Top**
   ```swift
   var body: some View {
       VStack {
           // Add this
           Text("👋 Hello, Farmer!")
               .font(.largeTitle)
               .padding()
               .background(Color.green.opacity(0.2))
               .cornerRadius(10)
           
           // Existing content...
       }
   }
   ```

3. **Build & Run** (`⌘R`)

4. **See Your Changes!** 🎉

**Bonus**: Make it personalized:
```swift
Text("👋 Hello, \(userManager.currentUser?.name ?? "Farmer")!")
```

---

## 📞 Need Help?

### Resources

- 📖 **[Full Documentation](Home.md)** - Complete wiki
- 🐛 **[Troubleshooting](Troubleshooting.md)** - Common issues
- ❓ **[FAQ](FAQ.md)** - Frequently asked questions
- 💬 **[GitHub Issues](https://github.com/Athar891/AgrisenseiOS/issues)** - Report bugs

### Community

- 💬 Join discussions
- 🤝 Connect with contributors
- 📧 Email: support@agrisense.app

---

## ✅ Checklist

Before moving forward, ensure:

- [ ] Project builds successfully
- [ ] App runs on simulator
- [ ] Firebase connected
- [ ] Can create test account
- [ ] All main tabs accessible
- [ ] No console errors (warnings OK)

---

**Ready to dive deeper?** → [Project Architecture](Project-Architecture.md)

**Want to contribute?** → [Contributing Guide](Contributing.md)

**Need setup help?** → [Installation Guide](Installation-Guide.md)

---

<div align="center">

**Happy Coding! 🚀**

Made with ❤️ for AgriSense

</div>
