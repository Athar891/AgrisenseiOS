# AddCropView Refactoring - Quick Reference

## 📋 Key Code Snippets

### 1. CropType Enum
```swift
enum CropType: String, CaseIterable, Codable {
    case wheat = "Wheat"
    case rice = "Rice"
    case corn = "Corn"
    case tomato = "Tomato"
    case potato = "Potato"
    
    var icon: String {
        switch self {
        case .wheat: return "🌾"
        case .rice: return "🌾"
        case .corn: return "🌽"
        case .tomato: return "🍅"
        case .potato: return "🥔"
        }
    }
    
    var growthDurationDays: Int {
        switch self {
        case .wheat: return 120
        case .rice: return 120
        case .corn: return 90
        case .tomato: return 75
        case .potato: return 90
        }
    }
}
```

### 2. Automated Harvest Date Calculation
```swift
func updateExpectedHarvestDate() {
    let calendar = Calendar.current
    let daysToAdd = selectedCropType.growthDurationDays
    expectedHarvestDate = calendar.date(
        byAdding: .day, 
        value: daysToAdd, 
        to: plantingDate
    ) ?? plantingDate
}
```

### 3. GPS Location Request
```swift
func requestLocation() {
    guard CLLocationManager.locationServicesEnabled() else {
        locationError = "Location services are disabled."
        return
    }
    
    let authStatus = locationManager.authorizationStatus
    
    switch authStatus {
    case .notDetermined:
        locationManager.requestWhenInUseAuthorization()
    case .restricted, .denied:
        locationError = "Location access denied."
    case .authorizedWhenInUse, .authorizedAlways:
        fetchCurrentLocation()
    @unknown default:
        locationError = "Unknown authorization status."
    }
}
```

### 4. Reverse Geocoding
```swift
private func formatAddress(from placemark: CLPlacemark?) -> String {
    guard let placemark = placemark else { return "Unknown Location" }
    
    var components: [String] = []
    
    if let locality = placemark.locality {
        components.append(locality)
    }
    if let administrativeArea = placemark.administrativeArea {
        components.append(administrativeArea)
    }
    if let country = placemark.country {
        components.append(country)
    }
    
    return components.isEmpty ? "Location acquired" : components.joined(separator: ", ")
}
```

### 5. Plot Size Unit Conversion
```swift
enum PlotSizeUnit: String, CaseIterable, Codable {
    case acres = "Acres"
    case hectares = "Hectares"
    
    func toHectares(_ value: Double) -> Double {
        switch self {
        case .acres: return value * 0.404686
        case .hectares: return value
        }
    }
}

// Usage:
var plotSizeInHectares: Double? {
    guard let value = Double(plotSize) else { return nil }
    return plotSizeUnit.toHectares(value)
}
```

### 6. Form Validation
```swift
var isFormValid: Bool {
    // Must have GPS location
    guard locationData != nil else { return false }
    
    // Must have valid plot size > 0
    guard !plotSize.isEmpty,
          let plotValue = Double(plotSize),
          plotValue > 0 else { return false }
    
    return true
}
```

### 7. Crop Creation
```swift
func createCrop() -> Crop? {
    guard let location = locationData else { return nil }
    
    let fieldLocationString = "\(location.displayString) (\(location.coordinatesString))"
    
    let crop = Crop(
        name: "\(selectedCropType.icon) \(selectedCropType.displayName)",
        plantingDate: plantingDate,
        expectedHarvestDate: expectedHarvestDate,
        currentGrowthStage: currentGrowthStage,
        healthStatus: healthStatus,
        fieldLocation: fieldLocationString,
        notes: notes.isEmpty ? "Plot Size: \(formattedPlotSize)" : "Plot Size: \(formattedPlotSize)\n\(notes)",
        cropImage: nil
    )
    
    return crop
}
```

### 8. SwiftUI Crop Type Picker
```swift
Picker("Crop Type", selection: $viewModel.selectedCropType) {
    ForEach(CropType.allCases, id: \.self) { cropType in
        HStack {
            Text(cropType.icon)
            Text(cropType.displayName)
        }
        .tag(cropType)
    }
}
.onChange(of: viewModel.selectedCropType) { _, _ in
    viewModel.onCropTypeChanged()
}
```

### 9. Read-Only Harvest Date Display
```swift
HStack {
    Text("Expected Harvest")
        .foregroundColor(.secondary)
    Spacer()
    Text(viewModel.expectedHarvestDate, style: .date)
        .foregroundColor(.green)
        .fontWeight(.semibold)
}
.padding(.vertical, 4)
```

### 10. GPS Location Button
```swift
Button(action: {
    viewModel.requestLocation()
}) {
    HStack {
        if viewModel.isGettingLocation {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        } else {
            Image(systemName: "location.circle.fill")
                .foregroundColor(.blue)
        }
        
        Text(viewModel.isGettingLocation ? "Getting Location..." : "📍 Use Current GPS Location")
            .foregroundColor(.blue)
            .fontWeight(.medium)
    }
}
.disabled(viewModel.isGettingLocation)
```

### 11. Location Display with Clear
```swift
if let location = viewModel.locationData {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.green)
            Text(location.displayString)
                .font(.body)
            Spacer()
            Button(action: {
                viewModel.clearLocation()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        
        Text(location.coordinatesString)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.leading, 24)
    }
}
```

### 12. Plot Size Input with Unit Picker
```swift
HStack {
    TextField("Enter size", text: $viewModel.plotSize)
        .keyboardType(.decimalPad)
        .frame(maxWidth: .infinity)
    
    Picker("Unit", selection: $viewModel.plotSizeUnit) {
        ForEach(PlotSizeUnit.allCases, id: \.self) { unit in
            Text(unit.displayName).tag(unit)
        }
    }
    .pickerStyle(.menu)
    .frame(width: 120)
}

// Conversion display
if let hectares = viewModel.plotSizeInHectares {
    HStack {
        Text("Equivalent")
            .foregroundColor(.secondary)
        Spacer()
        Text(String(format: "%.2f hectares", hectares))
            .foregroundColor(.primary)
            .font(.caption)
    }
}
```

---

## 🎯 Usage Examples

### Example 1: Adding Wheat Crop
```swift
// User selections:
selectedCropType = .wheat
plantingDate = Date() // Jan 26, 2026
// Auto-calculated:
expectedHarvestDate = May 26, 2026 (120 days later)

// Result:
Crop(
    name: "🌾 Wheat",
    plantingDate: Jan 26, 2026,
    expectedHarvestDate: May 26, 2026,
    fieldLocation: "New Delhi, Delhi, India (28.6139, 77.2090)",
    notes: "Plot Size: 5 ac"
)
```

### Example 2: Adding Tomato Crop
```swift
// User selections:
selectedCropType = .tomato
plantingDate = Feb 1, 2026
// Auto-calculated:
expectedHarvestDate = Apr 17, 2026 (75 days later)

// Result:
Crop(
    name: "🍅 Tomato",
    plantingDate: Feb 1, 2026,
    expectedHarvestDate: Apr 17, 2026,
    fieldLocation: "Mumbai, Maharashtra, India (19.0760, 72.8777)",
    notes: "Plot Size: 2 ha"
)
```

---

## 🔧 Testing Checklist

### Unit Tests
```swift
// Test date calculation
func testHarvestDateCalculation() {
    let viewModel = AddCropViewModel()
    viewModel.selectedCropType = .corn
    viewModel.plantingDate = Date()
    viewModel.updateExpectedHarvestDate()
    
    let expectedDate = Calendar.current.date(
        byAdding: .day, 
        value: 90, 
        to: viewModel.plantingDate
    )
    
    XCTAssertEqual(viewModel.expectedHarvestDate, expectedDate)
}

// Test form validation
func testFormValidation() {
    let viewModel = AddCropViewModel()
    
    // Should be invalid without location
    XCTAssertFalse(viewModel.isFormValid)
    
    // Add location
    viewModel.locationData = LocationData(
        latitude: 28.6139, 
        longitude: 77.2090, 
        address: "New Delhi"
    )
    
    // Still invalid without plot size
    XCTAssertFalse(viewModel.isFormValid)
    
    // Add plot size
    viewModel.plotSize = "5"
    
    // Now should be valid
    XCTAssertTrue(viewModel.isFormValid)
}
```

### UI Tests
```swift
func testAddCropFlow() {
    let app = XCUIApplication()
    app.launch()
    
    // Navigate to Add Crop
    app.buttons["Add Crop"].tap()
    
    // Select crop type
    app.pickers["Crop Type"].tap()
    app.pickerWheels.element.adjust(toPickerWheelValue: "Corn")
    
    // Select planting date
    app.datePickers["Planting Date"].tap()
    // ... select date
    
    // Get GPS location
    app.buttons["Use Current GPS Location"].tap()
    // ... handle permission dialog
    
    // Enter plot size
    app.textFields["Enter size"].tap()
    app.textFields["Enter size"].typeText("5")
    
    // Submit
    XCTAssertTrue(app.buttons["Add Crop"].isEnabled)
    app.buttons["Add Crop"].tap()
    
    // Verify navigation back
    XCTAssertTrue(app.navigationBars["Dashboard"].exists)
}
```

---

## 📊 Data Flow

```
User Input → ViewModel → Validation → Crop Creation → Firestore
     ↓           ↓            ↓              ↓             ↓
  UI State   Published    isFormValid    createCrop()   Save
              Props
```

### Detailed Flow:
1. **User selects crop type** → `selectedCropType` updated → `onCropTypeChanged()` → `updateExpectedHarvestDate()`
2. **User changes planting date** → `plantingDate` updated → `onPlantingDateChanged()` → `updateExpectedHarvestDate()`
3. **User taps GPS button** → `requestLocation()` → CLLocationManager → `locationData` updated → UI refreshes
4. **User enters plot size** → `plotSize` updated → `isFormValid` computed → Button enabled
5. **User taps Add Crop** → `validateForm()` → `createCrop()` → Upload image (if any) → Save to Firestore

---

## 🚀 Performance Tips

1. **Location Timeout**: Currently 5 seconds. Adjust if needed:
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 5) { ... }
```

2. **Geocoding**: Cached by iOS. Repeated requests for same coordinates are fast.

3. **Form Validation**: Computed property, no manual state management:
```swift
var isFormValid: Bool { /* computed */ }
```

4. **Image Upload**: Only happens on submission, not on selection:
```swift
if let cropImage = viewModel.cropImage {
    imageUrl = try await cropManager.uploadCropImage(cropImage, userId: userId)
}
```

---

## 🎓 Learning Resources

### CoreLocation
- [Apple Docs: CLLocationManager](https://developer.apple.com/documentation/corelocation/cllocationmanager)
- [Requesting Location Permissions](https://developer.apple.com/documentation/corelocation/requesting_authorization_to_use_location_services)

### SwiftUI Forms
- [Form Documentation](https://developer.apple.com/documentation/swiftui/form)
- [Picker Styles](https://developer.apple.com/documentation/swiftui/picker)

### MVVM Pattern
- [Design Patterns in Swift](https://refactoring.guru/design-patterns/swift)
- [MVVM with SwiftUI](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)

---

## ✅ Completed Features Summary

| Feature | Implementation | File Location |
|---------|---------------|---------------|
| CropType Enum | 5 crops with durations | `AddCropViewModel.swift:13-45` |
| Auto Harvest Date | Calendar calculation | `AddCropViewModel.swift:152-156` |
| GPS Integration | CoreLocation + Geocoding | `AddCropViewModel.swift:166-246` |
| Plot Size | Acres/Hectares conversion | `AddCropViewModel.swift:47-69` |
| Form Validation | Location + Size required | `AddCropViewModel.swift:105-115` |
| UI Layout | 8 sections with styling | `AddCropView.swift:20-218` |
| Error Handling | Comprehensive messages | Both files |

---

**All features implemented successfully with clean architecture and proper error handling!** ✨
