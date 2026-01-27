# AddCropView - UI Flow & Interaction Guide

## 🎨 Visual Layout

```
╔═══════════════════════════════════════════════════════╗
║             🌾 Add New Crop                     [Cancel]║
╠═══════════════════════════════════════════════════════╣
║                                                        ║
║  ┌─ SMART CROP SELECTION ────────────────────────┐  ║
║  │                                                 │  ║
║  │  Crop Type:  [🌾 Wheat ▼]                     │  ║
║  │  Growth Duration:                   120 days   │  ║
║  │                                                 │  ║
║  └─────────────────────────────────────────────────┘  ║
║                                                        ║
║  ┌─ PLANTING & HARVEST SCHEDULE ─────────────────┐  ║
║  │                                                 │  ║
║  │  Planting Date:    [Jan 26, 2026 >]           │  ║
║  │  Expected Harvest:         May 26, 2026       │  ║
║  │                                    ↑ (auto)    │  ║
║  └─────────────────────────────────────────────────┘  ║
║                                                        ║
║  ┌─ 📍 FIELD LOCATION (GPS REQUIRED) ────────────┐  ║
║  │                                                 │  ║
║  │  [📍 Use Current GPS Location]                 │  ║
║  │                                                 │  ║
║  │  OR (after GPS capture):                       │  ║
║  │                                                 │  ║
║  │  📍 New Delhi, Delhi, India           [✖]     │  ║
║  │     28.6139, 77.2090                           │  ║
║  │                                                 │  ║
║  └─────────────────────────────────────────────────┘  ║
║                                                        ║
║  ┌─ 🌾 PLOT SIZE (FOR FERTILIZER CALC.) ─────────┐  ║
║  │                                                 │  ║
║  │  [____5____]  [Acres ▼]                       │  ║
║  │  Equivalent:              2.02 hectares        │  ║
║  │                                                 │  ║
║  └─────────────────────────────────────────────────┘  ║
║                                                        ║
║  ┌─ CURRENT STATUS ────────────────────────────────┐ ║
║  │                                                  │ ║
║  │  Growth Stage:   [Seeding ▼]                   │ ║
║  │  Health Status:  [Good ▼]                      │ ║
║  │                                                  │ ║
║  └──────────────────────────────────────────────────┘ ║
║                                                        ║
║  ┌─ CROP IMAGE (OPTIONAL) ──────────────────────────┐║
║  │                                                    │║
║  │  [📷 Select Crop Image]                          │║
║  │                                                    │║
║  └────────────────────────────────────────────────────┘║
║                                                        ║
║  ┌─ NOTES (OPTIONAL) ───────────────────────────────┐║
║  │                                                    │║
║  │  [Additional notes...]                           │║
║  │                                                    │║
║  └────────────────────────────────────────────────────┘║
║                                                        ║
║              [Add Crop] (Enabled when valid)          ║
║                                                        ║
╚═══════════════════════════════════════════════════════╝
```

---

## 🔄 State Transitions

### 1. Initial Load
```
State: Empty Form
- Crop Type: Wheat (default)
- Planting Date: Today
- Expected Harvest: Today + 120 days (Wheat duration)
- Location: Not set (GPS button visible)
- Plot Size: Empty
- Add Button: DISABLED ❌
```

### 2. After Selecting Different Crop
```
User Action: Select "🌽 Corn"

Changes:
✓ Growth Duration: 120 days → 90 days
✓ Expected Harvest: Recalculated (Planting Date + 90 days)
✓ Add Button: Still DISABLED (no location/plot size)
```

### 3. After Changing Planting Date
```
User Action: Change Planting Date to "Jan 15, 2026"

Changes:
✓ Expected Harvest: Recalculated (Jan 15 + 90 days = Apr 15, 2026)
✓ Add Button: Still DISABLED (no location/plot size)
```

### 4. After GPS Location Capture
```
User Action: Tap "📍 Use Current GPS Location"

Process:
1. Button shows: "Getting Location..." with spinner
2. iOS permission dialog (if first time)
3. CoreLocation fetches coordinates
4. Reverse geocoding converts to address
5. Display: "New Delhi, Delhi, India (28.6139, 77.2090)"

Changes:
✓ Location: SET ✅
✓ Clear button (X) appears
✓ Add Button: Still DISABLED (no plot size)
```

### 5. After Entering Plot Size
```
User Action: Enter "5" and select "Acres"

Changes:
✓ Plot Size: 5 ac
✓ Equivalent Display: "2.02 hectares"
✓ Add Button: NOW ENABLED ✅
```

### 6. Ready to Submit
```
State: Form Valid
- Crop Type: 🌽 Corn
- Planting Date: Jan 15, 2026
- Expected Harvest: Apr 15, 2026 (auto)
- Location: New Delhi (28.6139, 77.2090)
- Plot Size: 5 ac (2.02 ha)
- Growth Stage: Seeding
- Health Status: Good
- Add Button: ENABLED ✅

User Action: Tap "Add Crop"
→ Validates form
→ Uploads image (if selected)
→ Creates Crop object
→ Saves to Firestore
→ Dismisses view
→ Returns to Dashboard
```

---

## 🎯 Interactive Elements

### Crop Type Picker
```swift
Interaction: Tap to expand
Options:
  🌾 Wheat    (120 days)
  🌾 Rice     (120 days)
  🌽 Corn     (90 days)
  🍅 Tomato   (75 days)
  🥔 Potato   (90 days)

On Selection:
→ Updates growth duration display
→ Auto-recalculates expected harvest date
```

### Planting Date Picker
```swift
Interaction: Tap to open calendar
Range: Up to tomorrow (cannot be far future)
Display: Standard iOS date picker

On Change:
→ Auto-recalculates expected harvest date
```

### GPS Location Button
```swift
States:
1. Initial:    [📍 Use Current GPS Location]
2. Loading:    [⏳ Getting Location...]
3. Captured:   [📍 City, State, Country (lat, long)] [✖]

Permissions Flow:
- Not Determined → Request permission
- Denied        → Show error message
- Granted       → Fetch location

On Success:
→ Displays geocoded address
→ Shows coordinates
→ Enables clear button
```

### Plot Size Input
```swift
Field:   [___] (Decimal keyboard)
Picker:  [Acres ▼] or [Hectares ▼]
Display: "Equivalent: X.XX hectares"

Validation:
→ Must be numeric
→ Must be > 0
→ Real-time conversion display
```

---

## ⚠️ Error States

### Location Errors
```
Scenario 1: Location Services Disabled
Message: "Location services are disabled. Please enable them in Settings."
Display: Red text below GPS button

Scenario 2: Permission Denied
Message: "Location access denied. Please enable location permissions in Settings."
Display: Red text below GPS button

Scenario 3: GPS Timeout/Failure
Message: "Unable to get your location. Please try again."
Display: Red text below GPS button

Solution: User can tap button again to retry
```

### Form Validation Errors
```
Submit without Location:
Alert: "Please set your field location using GPS."

Submit without Plot Size:
Alert: "Please enter the plot size."

Submit with Invalid Plot Size (0 or negative):
Alert: "Please enter a valid plot size greater than 0."

Submit with Future Planting Date:
Alert: "Planting date cannot be more than 1 day in the future."
```

---

## 📱 Responsive Behavior

### Dark Mode
```
Colors Auto-Adjust:
- Backgrounds: System background
- Text: Dynamic primary/secondary
- Buttons: Semantic blues/greens
- Errors: System red
- Success: System green
```

### Keyboard Management
```
Plot Size Field:
- Shows decimal keyboard
- Dismiss on scroll or tap outside
- Form auto-scrolls to keep field visible
```

### Loading States
```
Adding Crop:
- Full-screen overlay (semi-transparent)
- Centered spinner with message
- "Adding crop..." text
- Blocks all interaction
```

---

## 🔢 Data Validation Rules

| Field | Required | Validation Rule |
|-------|----------|----------------|
| Crop Type | Yes | Must select from enum |
| Planting Date | Yes | ≤ Tomorrow |
| Expected Harvest | Auto | Calculated (read-only) |
| Location | Yes | Must have GPS data |
| Plot Size | Yes | > 0, numeric |
| Plot Size Unit | Yes | Acres or Hectares |
| Growth Stage | Yes | Default: Seeding |
| Health Status | Yes | Default: Good |
| Image | No | Optional |
| Notes | No | Optional |

---

## 🎬 Complete User Journey Example

```
1. User opens "Add New Crop" from Dashboard
   ↓
2. Selects Crop: 🍅 Tomato (75 days)
   ↓
3. Sets Planting Date: Feb 1, 2026
   → Harvest auto-updates: Apr 17, 2026 ✅
   ↓
4. Taps "📍 Use Current GPS Location"
   → iOS asks: "Allow Agrisense to access your location?"
   → User taps "Allow While Using App"
   → Location captured: "Mumbai, Maharashtra, India"
   → Coordinates: (19.0760, 72.8777)
   ↓
5. Enters Plot Size: 2 Hectares
   → Equivalent shown: 2.00 hectares
   ↓
6. (Optional) Takes photo of field
   ↓
7. (Optional) Adds note: "South field near well"
   ↓
8. Taps "Add Crop"
   → Validation passes ✅
   → Crop saved to Firestore
   → Returns to Dashboard
   → New crop appears in list:
      "🍅 Tomato - 74 days until harvest"
```

---

## 🧩 Component Hierarchy

```
AddCropView
├── NavigationView
│   └── Form
│       ├── Section: Smart Crop Selection
│       │   ├── Picker (CropType)
│       │   └── Text (Growth Duration)
│       │
│       ├── Section: Planting & Harvest Schedule
│       │   ├── DatePicker (Planting Date)
│       │   └── HStack (Expected Harvest - read-only)
│       │
│       ├── Section: Field Location
│       │   ├── If location == nil:
│       │   │   └── Button (Get GPS)
│       │   └── Else:
│       │       ├── Address Display
│       │       ├── Coordinates Display
│       │       └── Clear Button
│       │
│       ├── Section: Plot Size
│       │   ├── HStack
│       │   │   ├── TextField (Size)
│       │   │   └── Picker (Unit)
│       │   └── HStack (Equivalent display)
│       │
│       ├── Section: Current Status
│       │   ├── Picker (Growth Stage)
│       │   └── Picker (Health Status)
│       │
│       ├── Section: Crop Image
│       │   └── PhotosPicker
│       │
│       ├── Section: Notes
│       │   └── TextField (Multiline)
│       │
│       └── Section: Action
│           └── Button (Add Crop)
│               └── disabled(!viewModel.isFormValid)
```

---

## 💡 Developer Notes

### Key Features
- **Automatic Date Calculation**: No manual harvest date errors
- **GPS Precision**: Accurate coordinates for future features
- **Unit Conversion**: Seamless acres ↔ hectares handling
- **Validation**: Cannot submit incomplete/invalid data
- **User Feedback**: Real-time form state indicators

### Future Integration Points
- [ ] Weather API: Use GPS for location-specific forecasts
- [ ] Pest Alerts: Regional pest risk based on coordinates
- [ ] Market Prices: Nearby mandi prices via location
- [ ] Fertilizer Calc: "Apply X kg per Y acres/hectares"
- [ ] Soil Data: Coordinate-based soil type lookup

### Performance Considerations
- GPS timeout: 5 seconds (adjustable)
- Geocoding: Async, doesn't block UI
- Image upload: Happens after form validation
- Form validation: Real-time computed property

---

**The refactored AddCropView provides a professional, smart, and user-friendly experience for farmers while collecting precise data for advanced agricultural features.** 🌾✨
