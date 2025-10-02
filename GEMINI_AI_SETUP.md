# Gemini AI Integration Setup Guide

This guide explains how to set up the Gemini 2.0 AI integration in your AgriSense iOS app.

## Overview

The app now uses **Google's Gemini 2.0 Flash Experimental** model to power the "Krishi AI" assistant. This provides intelligent, context-aware responses for agricultural queries.

## Getting Your Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Get API Key" or "Create API Key"
4. Copy your API key (starts with `AIza...`)

## Configuration Options

### Option 1: Environment Variable (Recommended for Development)

1. In Xcode, select your scheme at the top
2. Choose "Edit Scheme..."
3. Select "Run" from the left sidebar
4. Go to the "Arguments" tab
5. Under "Environment Variables", add:
   - **Name:** `GEMINI_API_KEY`
   - **Value:** Your API key (e.g., `AIzaSyA...`)

### Option 2: Secrets.swift File (Recommended for Production)

1. Open `Agrisense/Models/Secrets.swift`
2. Add your Gemini API key:

```swift
enum Secrets {
    static let geminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
}
```

3. Uncomment the line in `AIModels.swift` (line ~444):

```swift
// return Secrets.geminiAPIKey  // <- Uncomment this line
```

4. **IMPORTANT:** Never commit `Secrets.swift` to version control
   - It's already in `.gitignore`
   - Use `_Secrets.example.swift` as a template

## Features Implemented

### 1. Gemini 2.0 Model Integration
- Uses `gemini-2.0-flash-exp` for fast, accurate responses
- Supports text-only and text+image queries
- Context-aware responses based on user's location, crops, weather, etc.

### 2. Splash Screen with "Krishi AI" Branding
- Animated gradient text with pulsing effect
- Displays on app startup for 2.5 seconds
- Smooth fade transition to main app

### 3. Minimal Listening Overlay
- Clean, distraction-free design
- Animated green indicator at bottom of screen
- Simple "Listening..." text with pulse animation
- Tap anywhere to stop recording

## File Structure

```
Agrisense/
├── Services/
│   └── AI/
│       ├── AIModels.swift           # Core AI models and AIServiceManager
│       ├── GeminiAIService.swift    # Gemini 2.0 API implementation
│       └── AIContextBuilder.swift   # Context building utilities
├── Views/
│   ├── Assistant/
│   │   └── AssistantView.swift      # Main AI chat interface
│   └── Components/
│       └── SplashScreenView.swift   # "Krishi AI" splash screen
└── Models/
    ├── Secrets.swift                # API keys (not in git)
    └── _Secrets.example.swift       # Template for Secrets.swift
```

## Usage

### Basic Text Query

The AI assistant automatically uses Gemini 2.0 when you send a message:

```swift
// In AssistantView
private func sendMessage(_ text: String) {
    // Automatically calls GeminiAIService
    Task {
        let response = try await geminiService?.sendMessage(text, context: context)
        // Display response
    }
}
```

### With Image Analysis

```swift
let response = try await geminiService?.sendMessageWithImage(
    "What disease does this plant have?",
    image: cropImage,
    context: context
)
```

## API Limits

- **Free Tier:** 60 requests per minute
- **Paid Tier:** Higher limits available

## Troubleshooting

### "Please configure your Gemini API key"

- Check that your API key is set correctly
- Verify the key is active in Google AI Studio
- Try regenerating the key if it's not working

### Network Errors

- Check your internet connection
- Verify you haven't exceeded rate limits
- Ensure the API key has proper permissions

### Build Errors

If you see compilation errors:
1. Clean build folder: `Cmd + Shift + K`
2. Rebuild: `Cmd + B`
3. Check that all new files are included in your target

## Security Best Practices

1. **Never** commit API keys to version control
2. Use environment variables for development
3. Use Secrets.swift for production (ensure it's in .gitignore)
4. Consider using a backend server to proxy API calls in production
5. Implement rate limiting to prevent abuse

## Customization

### Change the AI Model

Edit `GeminiAIService.swift`:

```swift
private let model = "gemini-2.0-flash-exp" // Change to other models
// Options: gemini-pro, gemini-pro-vision, etc.
```

### Adjust Response Parameters

Modify the generation config in `sendMessage()`:

```swift
"generationConfig": [
    "temperature": 0.7,      // Creativity (0.0-1.0)
    "topK": 40,              // Sampling diversity
    "topP": 0.95,            // Nucleus sampling
    "maxOutputTokens": 1024  // Max response length
]
```

## Testing

Run the app and test the AI assistant:

1. Launch the app - you'll see the "Krishi AI" splash screen
2. Navigate to the "Assistant" tab
3. Try queries like:
   - "What's the weather like for farming today?"
   - "How do I identify crop diseases?"
   - "When should I plant tomatoes?"

## Support

For issues with:
- **Gemini API:** [Google AI Studio Support](https://ai.google.dev/docs)
- **App Issues:** Check the main README.md or open an issue

## Next Steps

- [ ] Implement image analysis for crop disease detection
- [ ] Add streaming responses for real-time feedback
- [ ] Integrate with local weather and market data
- [ ] Add multi-language support
- [ ] Implement conversation history persistence

---

**Note:** This implementation uses the experimental Gemini 2.0 model. Monitor [Google AI updates](https://ai.google.dev) for model changes and improvements.
