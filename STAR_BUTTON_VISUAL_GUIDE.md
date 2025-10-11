# Government Scheme Star Button - Visual Guide

## Feature Overview
This document provides a visual guide to the new star button feature on Government Scheme cards.

## UI Layout

```
┌─────────────────────────────────────────────────────┐
│  Government Schemes Section                         │
│                                                      │
│  ┌──────────────────┐  ┌──────────────────┐        │
│  │ PM-Kisan    ⭐   │  │ PMFBY        ⭐  │        │
│  │ Samman Nidhi     │  │                  │        │
│  │                  │  │ Crop insurance   │        │
│  │ Direct income... │  │ natural risks... │        │
│  │                  │  │                  │        │
│  │ [Visit Site]     │  │ [Visit Site]     │        │
│  └──────────────────┘  └──────────────────┘        │
└─────────────────────────────────────────────────────┘
```

## Star Button Specifications

### Position
- **Location:** Top-right corner of each Government Scheme card
- **Padding:** 8pt from top and right edges
- **Alignment:** `.topTrailing` in ZStack

### Appearance
- **Icon:** SF Symbol `star.fill`
- **Size:** 16pt font
- **Color:** Yellow (`.yellow`)
- **Background:** System background color
- **Shape:** Circle with 32x32pt frame
- **Shadow:** Subtle shadow for depth

### Interaction Flow

```
User Action                    System Response
───────────                    ───────────────
1. Tap Star Button      →      Present Assistant Modal
                               
2. Modal Opens          →      Show AssistantView with
                               loading state
                               
3. Auto-send Query      →      "Please provide a 
                               comprehensive summary of 
                               [Scheme Name]..."
                               
4. AI Processes         →      Display thinking indicator
                               
5. Response Ready       →      Show typed response
                               with animation
                               
6. User Reviews         →      Can ask follow-ups or
                               dismiss modal
```

## Query Template

The automatically generated query follows this format:

```
"Please provide a comprehensive summary of the [SCHEME_NAME] 
government scheme for farmers, including eligibility criteria, 
benefits, and how to apply."
```

### Example Queries by Scheme

**PM-Kisan Samman Nidhi:**
```
"Please provide a comprehensive summary of the PM-Kisan Samman Nidhi 
government scheme for farmers, including eligibility criteria, 
benefits, and how to apply."
```

**Pradhan Mantri Fasal Bima Yojana:**
```
"Please provide a comprehensive summary of the Pradhan Mantri Fasal 
Bima Yojana government scheme for farmers, including eligibility 
criteria, benefits, and how to apply."
```

## User Experience Flow Diagram

```
┌─────────────┐
│  Dashboard  │
│    View     │
└──────┬──────┘
       │
       │ User scrolls to
       │ Government Schemes
       │
       ▼
┌─────────────┐
│   Scheme    │
│    Card     │ ⭐ ← User taps star
└──────┬──────┘
       │
       │ Sheet presents
       │
       ▼
┌─────────────┐
│  Assistant  │
│    Modal    │
└──────┬──────┘
       │
       │ Auto-sends query
       │ (0.5s delay)
       │
       ▼
┌─────────────┐
│   Gemini    │
│  AI Process │
└──────┬──────┘
       │
       │ Streaming response
       │ with typing effect
       │
       ▼
┌─────────────┐
│   Display   │
│  Response   │
└──────┬──────┘
       │
       │ User can continue
       │ or dismiss
       │
       ▼
┌─────────────┐
│ Back to     │
│ Dashboard   │
└─────────────┘
```

## Dark Mode Considerations

The star button adapts to dark mode:
- Background uses `.systemBackground` (adapts automatically)
- Yellow star color remains visible in both modes
- Shadow opacity is subtle to work in both themes

## Accessibility

### VoiceOver Support
The star button should be accessible via VoiceOver with the label:
"Ask AI Assistant about [Scheme Name]"

### Dynamic Type
- Icon scales with user's preferred text size
- Button hit area remains 32x32pt minimum

## Animation Details

### Button Press
- No explicit animation (uses system default)
- Haptic feedback could be added in future

### Modal Presentation
- Uses SwiftUI's default sheet transition
- Slides up from bottom with system timing

### Auto-send Delay
- **Delay:** 0.5 seconds after modal appears
- **Reason:** Ensures view is fully rendered
- **User Experience:** Appears instant but prevents race conditions

## Error Handling

### If Gemini API Key Missing
```
Assistant displays:
"Please configure your Gemini API key to use the assistant."
```

### If Network Error
```
Assistant displays:
"Sorry, I encountered an error: [error description]"
```

### If User Dismisses Before Response
- Modal closes
- Background task continues but discards result
- No memory leak or state corruption

## Code Structure

```
DashboardView.swift
├── GovernmentSchemesSection
│   └── GovernmentSchemeCard (Modified)
│       ├── @State showAssistant
│       ├── ZStack with star button
│       ├── .sheet(isPresented: $showAssistant)
│       └── createSchemeQuery() helper
│
AssistantView.swift
├── init(initialMessage: String?)
├── @State hasProcessedInitialMessage
└── .onAppear (auto-send logic)
```

## Testing Checklist

- [ ] Star button visible on all scheme cards
- [ ] Star button properly positioned in top-right
- [ ] Tapping star opens Assistant modal
- [ ] Modal presents with smooth animation
- [ ] Query auto-sends after 0.5s delay
- [ ] AI response displays with typing effect
- [ ] User can ask follow-up questions
- [ ] Dismissing modal returns to Dashboard
- [ ] Works in light mode
- [ ] Works in dark mode
- [ ] Localization works for all languages
- [ ] No memory leaks when opening/closing multiple times
- [ ] Works on different iPhone sizes
- [ ] Keyboard dismisses properly
- [ ] VoiceOver announces button correctly

## Performance Considerations

- Sheet presentation is lazy-loaded
- AssistantView only initializes when sheet opens
- Gemini service reuses existing instance
- No performance impact on Dashboard scrolling
- Modal dismissed = view deallocated properly
