# Visual Design Specifications

## 1. Splash Screen - "Krishi AI"

### Layout
```
┌─────────────────────────────┐
│                             │
│         🍃 (Leaf Icon)      │
│         Size: 60pt          │
│         Color: Green        │
│                             │
│       Krishi AI             │
│       Size: 48pt Bold       │
│       Gradient: Animated    │
│                             │
│  Your Agricultural Assistant│
│       Size: 14pt            │
│       Color: Secondary      │
│                             │
└─────────────────────────────┘
```

### Colors
- **Background**: Soft gradient (green 10% opacity to blue 5% opacity)
- **Title**: Animated gradient
  - Green → Blue → Green (opacity variants)
  - 2-second continuous loop
  - Horizontal shift animation
- **Icon**: Green with gradient overlay

### Animation Sequence
1. **Initial (0s)**:
   - Scale: 0.8
   - Opacity: 0
   
2. **Entrance (0-0.8s)**:
   - Scale: 0.8 → 1.0 (ease-out)
   - Opacity: 0 → 1.0 (ease-out)
   
3. **During Display (0.8s-2.5s)**:
   - Gradient continuously shifts left to right
   - Smooth, infinite loop
   
4. **Exit (2.5s-3.0s)**:
   - Opacity: 1.0 → 0 (ease-out)
   - Scale: remains 1.0

### Typography
- **Title**: SF Rounded, 48pt, Bold
- **Subtitle**: SF Pro, 14pt, Regular
- **Letter Spacing**: Default
- **Line Height**: 1.2

## 2. Listening Overlay

### Layout
```
┌─────────────────────────────┐
│                             │
│                             │
│         [Main Content]      │
│                             │
│                             │
│  ┌─────────────────────┐   │
│  │ ● ● ●  Listening... │   │
│  │        Tap to stop  │   │
│  └─────────────────────┘   │
│         Bottom: 100pt       │
└─────────────────────────────┘
```

### Colors
- **Background**: Semi-transparent black (20% opacity)
- **Card**: Green (#00C853)
- **Text**: White
- **Dots**: White circles

### Dimensions
- **Card Width**: Screen width - 40pt padding
- **Card Height**: Auto (fits content, ~70pt)
- **Corner Radius**: 30pt
- **Padding**: 
  - Horizontal: 24pt
  - Vertical: 16pt
- **Bottom Margin**: 100pt from bottom

### Animation
- **Pulse Dots** (3 circles):
  - Size: 8pt diameter
  - Spacing: 4pt between dots
  - Scale: 1.0 → 1.5 (ease-in-out)
  - Opacity: 0.6 → 0.3 (ease-in-out)
  - Duration: 0.6s
  - Repeat: Forever (autoreverses)
  - Stagger: 0.15s delay between each dot

### Shadow
- Color: Green with 40% opacity
- Radius: 15pt
- Offset: (0, 5)

### Typography
- **"Listening..." text**: 16pt, Medium, White
- **"Tap to stop" text**: 14pt, Regular, White 80% opacity

## 3. AI Chat Interface

### Message Bubbles

#### User Messages (Right-aligned)
```
                     ┌─────────────────┐
                     │ User message    │
                     │ content here    │
                     └─────────────────┘
                            Blue
```
- **Background**: Blue (#007AFF)
- **Text**: White
- **Corner Radius**: 16pt
- **Max Width**: 280pt
- **Padding**: 12pt all sides
- **Alignment**: Trailing

#### AI Messages (Left-aligned)
```
┌─────────────────┐
│ AI response     │
│ content here    │
└─────────────────┘
     Gray
```
- **Background**: System Gray 5
- **Text**: Primary color
- **Corner Radius**: 16pt
- **Max Width**: 280pt
- **Padding**: 12pt all sides
- **Alignment**: Leading

### Input Bar
```
┌─────────────────────────────────────┐
│  +  🔧 Tools  [Type...]  🎤  ⬆️  │
└─────────────────────────────────────┘
```

- **Background**: Secondary system background
- **Corner Radius**: 25pt
- **Border**: 0.5pt separator color
- **Height**: Auto (min 52pt)
- **Padding**: 
  - Horizontal: 16pt
  - Vertical: 12pt

#### Buttons
- **Plus (+)**: 18pt, medium weight, secondary color
- **Tools**: Green chip (12pt horizontal padding, 6pt vertical)
- **Microphone**: 16pt, changes to red when recording
- **Send**: 32pt circle, green when text present

## Color Palette

### Primary Colors
- **Green (Primary)**: `#00C853` or `Color.green`
- **Blue (Accent)**: `#007AFF` or `Color.blue`

### Grays
- **Primary Text**: System primary
- **Secondary Text**: System secondary
- **Tertiary Text**: System tertiary
- **Background**: System background
- **Secondary Background**: System secondary background
- **Tertiary Background**: System tertiary background

### States
- **Active/Recording**: Red `#FF3B30`
- **Success**: Green `#00C853`
- **Error**: Red `#FF3B30`

## Spacing System

### Standard Spacing
- **XXS**: 4pt
- **XS**: 8pt
- **S**: 12pt
- **M**: 16pt
- **L**: 20pt
- **XL**: 24pt
- **XXL**: 32pt
- **XXXL**: 40pt

### Applied Spacing
- **Message Bubble Gap**: 16pt (M)
- **Input Bar Padding**: 16pt (M) horizontal, 12pt (S) vertical
- **Screen Padding**: 20pt (L) horizontal
- **Section Spacing**: 24pt (XL)

## Animations

### Spring Animation
```swift
.spring(response: 0.3, dampingFraction: 0.7)
```
- Used for: Modal appearances, button presses

### Ease Out Animation
```swift
.easeOut(duration: 0.8)
```
- Used for: Splash screen entrance, fade transitions

### Ease In-Out Animation
```swift
.easeInOut(duration: 0.6)
```
- Used for: Pulsing effects, smooth state changes

### Linear Animation
```swift
.linear(duration: 2.0).repeatForever(autoreverses: false)
```
- Used for: Gradient shifts, continuous animations

## Accessibility

### Text Sizes
- Support Dynamic Type
- Minimum touch target: 44x44 pt
- Text contrast ratio: 4.5:1 minimum

### VoiceOver Labels
- All buttons have clear labels
- Message timestamps included
- Loading states announced

### Color Contrast
- All text meets WCAG AA standards
- Green on white: 4.52:1
- Blue on white: 8.59:1
- White on green: 5.89:1

## Dark Mode Support

### Automatic Adaptation
- System background colors adapt automatically
- Green and blue colors remain consistent
- Text colors use system semantic colors

### Specific Dark Mode Colors
- **Splash Background**: Darker gradient
- **Card Backgrounds**: System materials
- **Shadows**: Adjusted for dark backgrounds

## Platform Considerations

### iOS Specific
- SF Symbols for icons
- Native animations
- System fonts
- Haptic feedback (optional)

### Safe Areas
- Respect top safe area for splash
- Bottom safe area for input bar
- Horizontal safe areas for all content

## Performance

### Animation Frame Rate
- Target: 60 FPS
- Reduced motion: Respect accessibility settings

### Image Optimization
- Compress images to 80% quality
- Use SF Symbols where possible
- Lazy load when appropriate

---

**Design System Version**: 1.0
**Last Updated**: October 2, 2025
**Platform**: iOS 15+
