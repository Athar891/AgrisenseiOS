# ❓ Frequently Asked Questions (FAQ)

Common questions and answers about AgriSense iOS development and usage.

---

## 📱 General Questions

### What is AgriSense?

AgriSense is an intelligent iOS application designed to empower farmers with cutting-edge AI technology, real-time market intelligence, and community support. It combines features like continuous voice AI assistance (Krishi AI), crop management, market price tracking, and agricultural e-commerce into a single platform.

### What iOS versions are supported?

AgriSense requires **iOS 16.0 or later**. It's optimized for:
- iOS 16.x
- iOS 17.x
- Latest iOS versions

### What devices are supported?

- iPhone 8 and later
- iPad (with iOS 16+)
- iPad Pro
- Optimized for iPhone 12 and newer

### Is AgriSense free to use?

Yes, AgriSense is currently free to use with all core features available at no cost. Some premium features may be added in the future.

---

## 🛠 Development Questions

### How do I set up the development environment?

See the complete [Installation Guide](Installation-Guide.md) for step-by-step instructions. Quick summary:

1. Install Xcode 15.0+
2. Clone the repository
3. Add Firebase configuration
4. Set up API keys
5. Build and run

### What technologies does AgriSense use?

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Backend**: Firebase (Auth, Firestore, Storage, Functions)
- **AI/ML**: Google Gemini AI 2.0
- **APIs**: OpenWeatherMap, data.gov.in, Cloudinary
- **Package Manager**: Swift Package Manager (SPM)

### Why won't the project build?

Common solutions:

1. **Clean Build Folder**: `⌘⇧K`
2. **Clear Derived Data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```
3. **Reset Package Caches**:
   - File → Packages → Reset Package Caches
   - File → Packages → Resolve Package Versions
4. **Check Firebase Config**: Ensure `GoogleService-Info.plist` is present
5. **Verify API Keys**: Check `Secrets.swift` exists with valid keys

### How do I get API keys?

**OpenWeatherMap** (Free):
1. Sign up at [openweathermap.org](https://openweathermap.org/api)
2. Navigate to API Keys section
3. Copy your key

**Google Gemini AI** (Free tier available):
1. Visit [ai.google.dev](https://ai.google.dev/)
2. Sign in with Google
3. Create API key
4. Copy the key

**Cloudinary** (Free tier):
1. Sign up at [cloudinary.com](https://cloudinary.com/)
2. Go to Dashboard
3. Note Cloud Name
4. Create unsigned upload preset

### How do I run tests?

**In Xcode**:
- Press `⌘U` to run all tests
- Click play button next to individual test

**Command line**:
```bash
xcodebuild test \
  -project Agrisense.xcodeproj \
  -scheme Agrisense \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro'
```

See [Testing Guide](Testing-Guide.md) for details.

---

## 🤖 Krishi AI Questions

### What is Krishi AI?

Krishi AI is AgriSense's advanced voice-powered AI assistant with:
- Continuous listening capability
- Wake word activation ("Krishi AI")
- Real-time interruption support
- Multi-modal intelligence (voice, camera, screen)
- Multi-language support (English, Hindi, Bengali, Tamil, Telugu)

### How do I activate Krishi AI?

1. **Wake Word**: Say "Krishi AI" or "Hey Krishi"
2. **Manual**: Tap the microphone button
3. **Auto**: AI automatically processes when you stop speaking

### Why isn't the wake word working?

**Troubleshooting**:
1. **Check Microphone Permission**:
   - Settings → AgriSense → Microphone → Enabled
2. **Check Speech Recognition**:
   - Settings → AgriSense → Speech Recognition → Enabled
3. **Pronunciation**: Try variations:
   - "Krishi AI"
   - "Krishna AI"
   - "Krishi"
4. **Background Noise**: Reduce ambient noise
5. **Restart App**: Force quit and relaunch

### Can I interrupt Krishi AI while it's speaking?

Yes! Simply:
1. Start speaking (AI will automatically stop)
2. Tap the stop button
3. Say the wake word again

### What languages does Krishi AI support?

- 🇬🇧 English (en)
- 🇮🇳 Hindi (hi)
- 🇮🇳 Bengali (bn)
- 🇮🇳 Tamil (ta)
- 🇮🇳 Telugu (te)

Change language in: Profile → Settings → Language

### Why is AI response slow?

**Possible causes**:
1. **Network Connection**: Check internet speed
2. **API Limits**: You may have hit rate limits
3. **Server Load**: Gemini AI servers may be busy
4. **Large Context**: Complex queries take longer

**Solutions**:
- Ensure good internet connection
- Wait a moment and try again
- Simplify your query
- Check API quota in Google AI Studio

---

## 🌱 Crop Management Questions

### How do I add a crop?

1. Go to **Crops** tab
2. Tap **+ Add Crop** button
3. Fill in details:
   - Crop name
   - Type/Category
   - Planting date
   - Location
   - Upload photo (optional)
4. Tap **Save**

### Can I track multiple crops?

Yes! Add as many crops as you need. Each crop is tracked individually with its own:
- Growth stage
- Health status
- Photos
- Notes
- Reminders

### How do I upload crop photos?

1. Open crop details
2. Tap camera icon or "Add Photo"
3. Choose:
   - **Take Photo**: Use camera
   - **Choose from Library**: Select existing photo
4. Photo is automatically uploaded to cloud

### Why won't my crop photo upload?

**Troubleshooting**:
1. **Check Internet**: Ensure stable connection
2. **Photo Size**: Large photos take time (auto-compressed)
3. **Permissions**: Settings → AgriSense → Photos → Enabled
4. **Cloudinary Config**: Verify credentials in `Secrets.swift`

### Can I export crop data?

Currently in development. Future versions will support:
- PDF export
- CSV export
- Share reports via email

---

## 🛒 Marketplace Questions

### How do I buy products?

1. Browse products in **Marketplace** tab
2. Tap product to view details
3. Tap **Add to Cart**
4. Go to **Cart** (top right icon)
5. Tap **Checkout**
6. Enter delivery address
7. Choose payment method
8. Confirm order

### What payment methods are supported?

Currently supporting:
- Credit/Debit Cards
- UPI
- Net Banking
- Cash on Delivery (COD)

### How do I track my orders?

1. Go to **Profile** tab
2. Tap **My Orders**
3. View order status:
   - Pending
   - Processing
   - Shipped
   - Delivered

### Can I cancel an order?

Yes, if order status is still "Pending" or "Processing":
1. Go to **My Orders**
2. Select order
3. Tap **Cancel Order**
4. Confirm cancellation

Shipped orders cannot be cancelled but can be returned.

---

## 🔒 Security & Privacy Questions

### Is my data secure?

Yes! AgriSense implements multiple security layers:
- **Firebase Authentication**: Secure user authentication
- **Encrypted Storage**: Sensitive data encrypted in Keychain
- **HTTPS Only**: All network calls use HTTPS
- **Input Validation**: Prevents injection attacks
- **Rate Limiting**: Protects against abuse

See [Security Documentation](Security.md) for details.

### What data does AgriSense collect?

**Collected Data**:
- Account information (email, name, phone)
- Crop data (names, photos, locations)
- Usage analytics (anonymous)
- Voice recordings (for AI, processed in real-time, not stored)

**Not Collected**:
- Payment card details (handled by payment gateway)
- Personal conversations (AI context not stored)

### Can I delete my account?

Yes:
1. Go to **Profile** → **Settings**
2. Tap **Account**
3. Tap **Delete Account**
4. Confirm deletion

**Warning**: This permanently deletes:
- Your account
- All crop data
- Order history
- Cannot be undone

### Where is my data stored?

- **User Data**: Firebase Firestore (Cloud)
- **Images**: Cloudinary (Cloud)
- **Local Cache**: Device storage (temporary)
- **Secure Data**: iOS Keychain (device)

---

## 🌍 Localization Questions

### How do I change the app language?

1. Go to **Profile** → **Settings**
2. Tap **Language**
3. Select your preferred language:
   - English
   - हिन्दी (Hindi)
   - বাংলা (Bengali)
   - தமிழ் (Tamil)
   - తెలుగు (Telugu)
4. App restarts with new language

### Is the AI assistant available in all languages?

Yes! Krishi AI supports:
- Understanding and responding in all 5 languages
- Mixed language conversations
- Automatic language detection

### Can I add a new language?

For developers: Yes, follow localization guide:
1. Add `.lproj` folder for language code
2. Create `Localizable.strings` file
3. Translate all keys
4. Update `LocalizationManager`

See [Localization Guide](Localization.md) for details.

---

## 🐛 Troubleshooting

### App crashes on launch

**Solutions**:
1. **Force Quit**: Swipe up from app switcher
2. **Restart Device**: Power off and on
3. **Reinstall App**: Delete and reinstall from Xcode
4. **Check Logs**: View crash logs in Xcode
5. **Update iOS**: Ensure iOS is up to date

### Firebase authentication fails

**Common Issues**:
1. **Invalid Email**: Check email format
2. **Weak Password**: Use 8+ characters with numbers/symbols
3. **Network Issue**: Check internet connection
4. **Firebase Config**: Verify `GoogleService-Info.plist`

### Google Sign-In not working

**Troubleshooting**:
1. **Check Bundle ID**: Must match Firebase config
2. **URL Scheme**: Verify in Info.plist
3. **OAuth Client**: Ensure iOS client ID is correct
4. **Google Services**: Check Firebase console for enabled auth

### Weather data not loading

**Solutions**:
1. **API Key**: Verify OpenWeatherMap API key is valid
2. **Location**: Enable location services
3. **Network**: Check internet connection
4. **API Quota**: Check if you've exceeded free tier limits

### Microphone not working

**Check**:
1. **Permissions**: Settings → AgriSense → Microphone → Enabled
2. **Hardware**: Test mic in Voice Memos app
3. **Audio Session**: Restart app
4. **Bluetooth**: Disconnect Bluetooth devices if causing issues

---

## 📱 Device-Specific Questions

### Does it work on iPad?

Yes! AgriSense is compatible with iPad running iOS 16+. The interface adapts to larger screens.

### Can I use it on Mac?

Not currently. AgriSense is iOS-only. Mac support (via Catalyst) may be added in future.

### What about Apple Watch?

Not currently supported. Apple Watch companion app is on the roadmap.

---

## 🚀 Feature Requests

### How do I request a new feature?

1. Check [existing issues](https://github.com/Athar891/AgrisenseiOS/issues)
2. If not found, [create new issue](https://github.com/Athar891/AgrisenseiOS/issues/new)
3. Use "Feature Request" template
4. Provide clear description and use case

### What features are coming soon?

Check the [Roadmap](Roadmap.md) for planned features:
- Offline mode
- Crop disease detection
- Weather alerts
- Community forums
- Expert consultations
- And more!

### Can I contribute to development?

Absolutely! See [Contributing Guide](Contributing.md) for how to:
- Report bugs
- Submit pull requests
- Improve documentation
- Suggest features

---

## 🆘 Getting More Help

### Documentation didn't answer my question

**Resources**:
- 📖 [Full Wiki](Home.md) - Complete documentation
- 🐛 [GitHub Issues](https://github.com/Athar891/AgrisenseiOS/issues) - Bug reports
- 💬 [Discussions](https://github.com/Athar891/AgrisenseiOS/discussions) - Q&A
- 📧 Email: support@agrisense.app

### How do I report a bug?

1. Check [existing issues](https://github.com/Athar891/AgrisenseiOS/issues)
2. Create [new issue](https://github.com/Athar891/AgrisenseiOS/issues/new)
3. Include:
   - iOS version
   - Device model
   - Steps to reproduce
   - Screenshots/videos
   - Error messages

### How can I contact support?

- **Email**: support@agrisense.app
- **GitHub**: [Create an issue](https://github.com/Athar891/AgrisenseiOS/issues)
- **Response Time**: Usually within 24-48 hours

---

## 💡 Tips & Tricks

### Best practices for using Krishi AI

1. **Speak Clearly**: Articulate words clearly
2. **Reduce Noise**: Find quiet environment
3. **Specific Questions**: Be specific for better answers
4. **Use Context**: Reference previous messages
5. **Try Languages**: Mix languages if comfortable

### Optimizing crop management

1. **Regular Updates**: Update crop status weekly
2. **Photos**: Take photos from multiple angles
3. **Notes**: Add detailed notes and observations
4. **Reminders**: Set reminders for important tasks
5. **Location**: Tag accurate field locations

### Marketplace tips

1. **Compare**: Check multiple products before buying
2. **Reviews**: Read product reviews
3. **Bulk Orders**: Look for bulk discounts
4. **Wishlist**: Save items for later
5. **Notifications**: Enable order status notifications

---

## 📊 Performance Questions

### App is running slow

**Optimization Tips**:
1. **Close Background Apps**: Free up memory
2. **Clear Cache**: Settings → AgriSense → Clear Cache
3. **Update App**: Install latest version
4. **Restart Device**: Fresh start often helps
5. **Storage**: Ensure device has free space

### Battery drain

**Solutions**:
1. **Background Refresh**: Disable if not needed
2. **Location Services**: Use "While Using App"
3. **Continuous Listening**: Disable if not using AI
4. **Brightness**: Reduce screen brightness
5. **Update iOS**: Latest iOS has battery improvements

---

## 📈 Analytics & Insights

### Does AgriSense collect analytics?

Yes, we collect anonymous usage analytics to:
- Improve app performance
- Understand feature usage
- Fix crashes and bugs
- Plan new features

**You can opt out**: Settings → Privacy → Analytics → Disable

### What analytics are collected?

- Feature usage (which features are used most)
- App crashes (to fix bugs)
- Performance metrics (loading times)
- General usage patterns

**Not collected**: Personal data, conversations, exact locations

---

**Still have questions?** Ask in [GitHub Discussions](https://github.com/Athar891/AgrisenseiOS/discussions) or [create an issue](https://github.com/Athar891/AgrisenseiOS/issues)!
