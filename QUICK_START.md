# Quick Start Guide - Krishi AI Features

## 🚀 Getting Started in 5 Minutes

### Step 1: Add Your Gemini API Key

Choose **ONE** of these methods:

#### Method A: Environment Variable (Easiest for Testing)
1. In Xcode, click on your scheme name at the top
2. Select **"Edit Scheme..."**
3. Go to **Run** → **Arguments** tab
4. Under "Environment Variables", click **+**
5. Add:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: Your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
6. Click **Close**

#### Method B: Secrets File (Better for Production)
1. Open `Agrisense/Models/Secrets.swift`
2. Add your key:
```swift
static let geminiAPIKey = "YOUR_API_KEY_HERE"
```
3. Uncomment line ~444 in `AIModels.swift`

### Step 2: Build & Run
1. Press `Cmd + B` to build
2. Press `Cmd + R` to run
3. You'll see the "Krishi AI" splash screen! 🎉

### Step 3: Test the Features

#### Test Splash Screen
- Launch the app
- See "Krishi AI" with gradient animation
- Auto-dismisses after 2.5 seconds

#### Test AI Chat
1. Go to **Assistant** tab
2. Type: "What crops should I plant this season?"
3. Get AI response from Gemini 2.0!

#### Test Voice Input
1. Tap the microphone button 🎤
2. See minimal listening overlay at bottom
3. Speak your question
4. Tap anywhere to stop
5. Text appears in chat box

## 📱 Features Checklist

- ✅ Gemini 2.0 Flash AI integration
- ✅ "Krishi AI" branded splash screen with gradient animation
- ✅ Minimal, clean listening overlay
- ✅ Context-aware AI responses
- ✅ Voice transcription support
- ✅ Image analysis capability (for crop diseases)

## 🎨 UI Components

### Splash Screen
- **Duration**: 2.5 seconds
- **Animation**: Gradient shift, scale + fade
- **Customization**: Edit `SplashScreenView.swift`

### Listening Overlay
- **Position**: Bottom of screen (100pt from bottom)
- **Color**: Green
- **Animation**: Pulsing dots
- **Dismissal**: Tap anywhere

### Chat Interface
- **User Messages**: Blue, right-aligned
- **AI Messages**: Gray, left-aligned
- **Input**: Integrated toolbar with voice button

## 🔧 Customization

### Change Splash Duration
In `AgrisenseApp.swift`, line ~125:
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { // Change 2.5 to your duration
    withAnimation(.easeOut(duration: 0.5)) {
        showSplash = false
    }
}
```

### Change Listening Overlay Color
In `AssistantView.swift`, search for `ListeningAnimationView`:
```swift
.fill(Color.green)  // Change to any color
```

### Adjust AI Creativity
In `GeminiAIService.swift`, line ~40:
```swift
"temperature": 0.7,  // 0.0 = factual, 1.0 = creative
```

## 🐛 Troubleshooting

### "Please configure your Gemini API key"
- ✅ Check API key is set correctly
- ✅ Try regenerating key from Google AI Studio
- ✅ Ensure no extra spaces in the key

### Build Errors
```bash
# Clean build folder
Cmd + Shift + K

# Clean derived data
Xcode → Product → Clean Build Folder

# Rebuild
Cmd + B
```

### Voice Not Working
- Check microphone permissions in Settings
- Test with simple phrases first
- Ensure device is not on silent mode

## 📊 API Usage Limits

| Tier | Requests/Minute | Cost |
|------|-----------------|------|
| Free | 60 | $0 |
| Paid | Higher | Variable |

Monitor usage at [Google AI Studio](https://makersuite.google.com/app/apikey)

## 💡 Pro Tips

1. **Test with real queries**: "What's the best time to plant tomatoes?"
2. **Try image analysis**: Take photo of plant → Ask "What disease is this?"
3. **Use quick actions**: Tap "Tools" for common questions
4. **Context matters**: Location and crop data enhance AI responses

## 🎯 What to Test

### Basic Functionality
- [ ] App launches with splash screen
- [ ] Splash screen animates smoothly
- [ ] App transitions to main view after 2.5s
- [ ] Can type and send messages
- [ ] AI responds with relevant answers
- [ ] Voice button shows listening overlay
- [ ] Voice transcription works
- [ ] Messages scroll smoothly

### Advanced Features
- [ ] AI provides context-aware responses
- [ ] Image upload and analysis works
- [ ] Quick actions provide relevant prompts
- [ ] Error messages are helpful
- [ ] Dark mode works correctly
- [ ] Animations are smooth (60fps)

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `GEMINI_AI_SETUP.md` | Detailed API setup |
| `IMPLEMENTATION_SUMMARY.md` | Technical overview |
| `VISUAL_DESIGN_SPECS.md` | Design specifications |
| This file | Quick reference |

## 🚨 Important Notes

1. **Never commit API keys** to version control
2. **Test in simulator first** before device
3. **Monitor API usage** to avoid unexpected charges
4. **Respect rate limits** (60 req/min on free tier)
5. **Handle errors gracefully** for better UX

## 📞 Need Help?

- **Gemini API Docs**: https://ai.google.dev/docs
- **Google AI Studio**: https://makersuite.google.com
- **Firebase Console**: https://console.firebase.google.com

## 🎉 You're Ready!

Your AgriSense app now has:
- ✨ Professional branded splash screen
- 🤖 Gemini 2.0 AI assistant
- 🎤 Clean voice input UI
- 📱 Modern iOS design

Press `Cmd + R` and test it out!

---

**Quick Reference Version**: 1.0  
**Last Updated**: October 2, 2025  
**Status**: ✅ Ready for Testing
