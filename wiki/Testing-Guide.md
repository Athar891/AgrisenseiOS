# 🧪 Testing Guide

Comprehensive guide for testing AgriSense iOS application including unit tests, UI tests, and best practices.

---

## 📋 Table of Contents

- [Testing Overview](#testing-overview)
- [Unit Testing](#unit-testing)
- [UI Testing](#ui-testing)
- [Integration Testing](#integration-testing)
- [Test Coverage](#test-coverage)
- [Best Practices](#best-practices)
- [CI/CD Integration](#cicd-integration)

---

## 🎯 Testing Overview

### Testing Strategy

AgriSense uses a comprehensive testing approach:

```
┌─────────────────────────────────────────┐
│         End-to-End Tests (5%)           │
│     Critical user flows & scenarios     │
├─────────────────────────────────────────┤
│          UI Tests (15%)                 │
│     User interface & interactions       │
├─────────────────────────────────────────┤
│        Integration Tests (30%)          │
│   Services, APIs, Firebase integration  │
├─────────────────────────────────────────┤
│         Unit Tests (50%)                │
│   Models, managers, utilities, logic    │
└─────────────────────────────────────────┘
```

### Test Targets

- **AgrisenseTests**: Unit and integration tests
- **AgrisenseUITests**: UI and end-to-end tests

### Running Tests

**Xcode**:
```
⌘U - Run all tests
⌘⌥U - Run test again
⌘⌃⌥G - Run last test
```

**Command Line**:
```bash
# Run all tests
xcodebuild test \
  -project Agrisense.xcodeproj \
  -scheme Agrisense \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro'

# Run specific test
xcodebuild test \
  -project Agrisense.xcodeproj \
  -scheme Agrisense \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  -only-testing:AgrisenseTests/CropManagerTests/testFetchCrops
```

---

## 🔬 Unit Testing

### Setup

```swift
import XCTest
@testable import Agrisense

class CropManagerTests: XCTestCase {
    
    // System Under Test
    var sut: CropManager!
    
    override func setUp() {
        super.setUp()
        sut = CropManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}
```

### Testing Models

```swift
class CropTests: XCTestCase {
    
    func testCropInitialization() {
        // Given
        let id = UUID().uuidString
        let name = "Wheat"
        let type = CropType.cereal
        
        // When
        let crop = Crop(
            id: id,
            name: name,
            type: type,
            plantingDate: Date(),
            healthStatus: .good
        )
        
        // Then
        XCTAssertEqual(crop.id, id)
        XCTAssertEqual(crop.name, name)
        XCTAssertEqual(crop.type, type)
        XCTAssertEqual(crop.healthStatus, .good)
    }
    
    func testCropValidation() {
        // Given
        let crop = Crop(
            id: UUID().uuidString,
            name: "",  // Invalid empty name
            type: .cereal,
            plantingDate: Date(),
            healthStatus: .good
        )
        
        // When
        let isValid = crop.isValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testCropCodable() throws {
        // Given
        let crop = Crop(
            id: UUID().uuidString,
            name: "Rice",
            type: .cereal,
            plantingDate: Date(),
            healthStatus: .excellent
        )
        
        // When
        let encoded = try JSONEncoder().encode(crop)
        let decoded = try JSONDecoder().decode(Crop.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.name, crop.name)
        XCTAssertEqual(decoded.type, crop.type)
    }
}
```

### Testing Managers (ViewModels)

```swift
class CropManagerTests: XCTestCase {
    var sut: CropManager!
    
    override func setUp() {
        super.setUp()
        sut = CropManager()
    }
    
    func testFetchCrops() async throws {
        // Given
        XCTAssertTrue(sut.crops.isEmpty)
        
        // When
        try await sut.fetchCrops(for: "test-user-id")
        
        // Then
        XCTAssertFalse(sut.crops.isEmpty)
        XCTAssertGreaterThan(sut.crops.count, 0)
    }
    
    func testAddCrop() async throws {
        // Given
        let initialCount = sut.crops.count
        let newCrop = Crop(
            id: UUID().uuidString,
            name: "Test Crop",
            type: .vegetable,
            plantingDate: Date(),
            healthStatus: .good
        )
        
        // When
        try await sut.addCrop(newCrop)
        
        // Then
        XCTAssertEqual(sut.crops.count, initialCount + 1)
        XCTAssertTrue(sut.crops.contains { $0.id == newCrop.id })
    }
    
    func testDeleteCrop() async throws {
        // Given
        let crop = Crop(
            id: UUID().uuidString,
            name: "Delete Me",
            type: .fruit,
            plantingDate: Date(),
            healthStatus: .fair
        )
        try await sut.addCrop(crop)
        let countAfterAdd = sut.crops.count
        
        // When
        try await sut.deleteCrop(crop.id)
        
        // Then
        XCTAssertEqual(sut.crops.count, countAfterAdd - 1)
        XCTAssertFalse(sut.crops.contains { $0.id == crop.id })
    }
    
    func testUpdateCrop() async throws {
        // Given
        var crop = Crop(
            id: UUID().uuidString,
            name: "Original Name",
            type: .cereal,
            plantingDate: Date(),
            healthStatus: .good
        )
        try await sut.addCrop(crop)
        
        // When
        crop.name = "Updated Name"
        crop.healthStatus = .excellent
        try await sut.updateCrop(crop)
        
        // Then
        let updatedCrop = sut.crops.first { $0.id == crop.id }
        XCTAssertEqual(updatedCrop?.name, "Updated Name")
        XCTAssertEqual(updatedCrop?.healthStatus, .excellent)
    }
}
```

### Testing Services

```swift
class WeatherServiceTests: XCTestCase {
    var sut: WeatherService!
    
    override func setUp() {
        super.setUp()
        sut = WeatherService()
    }
    
    func testFetchWeather() async throws {
        // Given
        let latitude = 28.6139
        let longitude = 77.2090
        
        // When
        let weather = try await sut.fetchWeather(
            latitude: latitude,
            longitude: longitude
        )
        
        // Then
        XCTAssertNotNil(weather)
        XCTAssertNotNil(weather.temperature)
        XCTAssertNotNil(weather.description)
    }
    
    func testWeatherCaching() async throws {
        // Given
        let latitude = 28.6139
        let longitude = 77.2090
        
        // When - First fetch
        let weather1 = try await sut.fetchWeather(
            latitude: latitude,
            longitude: longitude
        )
        
        // When - Second fetch (should use cache)
        let weather2 = try await sut.fetchWeather(
            latitude: latitude,
            longitude: longitude
        )
        
        // Then
        XCTAssertEqual(weather1.temperature, weather2.temperature)
    }
}
```

### Testing Utilities

```swift
class ImageCompressionTests: XCTestCase {
    
    func testCompressImage() {
        // Given
        let image = UIImage(systemName: "photo")!
        let targetSize: CGFloat = 100 * 1024 // 100KB
        
        // When
        let compressed = ImageCompression.compress(
            image: image,
            targetSizeKB: targetSize
        )
        
        // Then
        XCTAssertNotNil(compressed)
        let compressedSize = compressed?.jpegData(compressionQuality: 1.0)?.count ?? 0
        XCTAssertLessThanOrEqual(compressedSize, Int(targetSize))
    }
}

class InputValidatorTests: XCTestCase {
    
    func testValidEmail() throws {
        // Valid emails
        XCTAssertNoThrow(try InputValidator.validateEmail("user@example.com"))
        XCTAssertNoThrow(try InputValidator.validateEmail("test.user@domain.co.in"))
    }
    
    func testInvalidEmail() {
        // Invalid emails
        XCTAssertThrowsError(try InputValidator.validateEmail("invalid"))
        XCTAssertThrowsError(try InputValidator.validateEmail("@example.com"))
        XCTAssertThrowsError(try InputValidator.validateEmail("user@"))
    }
    
    func testValidPhoneNumber() throws {
        XCTAssertNoThrow(try InputValidator.validatePhoneNumber("+919876543210"))
        XCTAssertNoThrow(try InputValidator.validatePhoneNumber("9876543210"))
    }
    
    func testInvalidPhoneNumber() {
        XCTAssertThrowsError(try InputValidator.validatePhoneNumber("123"))
        XCTAssertThrowsError(try InputValidator.validatePhoneNumber("abcdefghij"))
    }
}
```

### Mocking

```swift
// Mock Firebase Firestore
class MockFirestore: Firestore {
    var mockData: [String: Any] = [:]
    var shouldFail = false
    
    override func collection(_ collectionPath: String) -> CollectionReference {
        return MockCollectionReference(data: mockData, shouldFail: shouldFail)
    }
}

// Mock Network Service
class MockNetworkService: NetworkService {
    var mockResponse: Data?
    var mockError: Error?
    
    override func fetch<T: Decodable>(_ endpoint: String) async throws -> T {
        if let error = mockError {
            throw error
        }
        
        if let data = mockResponse {
            return try JSONDecoder().decode(T.self, from: data)
        }
        
        throw NetworkError.noData
    }
}

// Usage in tests
class UserManagerTests: XCTestCase {
    var sut: UserManager!
    var mockFirestore: MockFirestore!
    
    override func setUp() {
        super.setUp()
        mockFirestore = MockFirestore()
        sut = UserManager(firestore: mockFirestore)
    }
    
    func testFetchUserSuccess() async throws {
        // Given
        mockFirestore.mockData = [
            "name": "Test User",
            "email": "test@example.com"
        ]
        
        // When
        let user = try await sut.fetchUser(id: "test-id")
        
        // Then
        XCTAssertEqual(user.name, "Test User")
    }
    
    func testFetchUserFailure() async {
        // Given
        mockFirestore.shouldFail = true
        
        // When/Then
        do {
            _ = try await sut.fetchUser(id: "test-id")
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
```

---

## 🎨 UI Testing

### Setup

```swift
import XCTest

class AgrisenseUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
}
```

### Testing Navigation

```swift
class NavigationUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testTabBarNavigation() {
        // Test Dashboard tab
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.exists)
        dashboardTab.tap()
        
        // Test Marketplace tab
        let marketplaceTab = app.tabBars.buttons["Marketplace"]
        XCTAssertTrue(marketplaceTab.exists)
        marketplaceTab.tap()
        
        // Test AI Assistant tab
        let aiTab = app.tabBars.buttons["AI Assistant"]
        XCTAssertTrue(aiTab.exists)
        aiTab.tap()
    }
    
    func testNavigationFlow() {
        // Navigate to Crop List
        app.navigationBars.buttons["Crops"].tap()
        XCTAssertTrue(app.navigationBars["Crops"].exists)
        
        // Navigate to Add Crop
        app.navigationBars.buttons["Add"].tap()
        XCTAssertTrue(app.navigationBars["Add Crop"].exists)
        
        // Go back
        app.navigationBars.buttons["Back"].tap()
        XCTAssertTrue(app.navigationBars["Crops"].exists)
    }
}
```

### Testing User Interactions

```swift
class UserInteractionUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testAddCrop() {
        // Navigate to Add Crop
        app.tabBars.buttons["Crops"].tap()
        app.navigationBars.buttons["Add"].tap()
        
        // Fill form
        let nameField = app.textFields["Crop Name"]
        nameField.tap()
        nameField.typeText("Test Wheat")
        
        // Select type
        app.buttons["Crop Type"].tap()
        app.buttons["Cereal"].tap()
        
        // Select planting date
        app.datePickers.firstMatch.tap()
        
        // Submit
        app.buttons["Save"].tap()
        
        // Verify crop added
        XCTAssertTrue(app.staticTexts["Test Wheat"].exists)
    }
    
    func testSearchFunctionality() {
        // Navigate to Marketplace
        app.tabBars.buttons["Marketplace"].tap()
        
        // Tap search field
        let searchField = app.searchFields["Search products"]
        searchField.tap()
        searchField.typeText("fertilizer")
        
        // Wait for results
        let resultExists = app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS[c] 'fertilizer'"))
            .firstMatch
            .waitForExistence(timeout: 5)
        
        XCTAssertTrue(resultExists)
    }
}
```

### Testing Accessibility

```swift
class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testVoiceOverLabels() {
        // Check important buttons have labels
        let addButton = app.buttons["Add Crop"]
        XCTAssertTrue(addButton.exists)
        XCTAssertNotNil(addButton.label)
        
        // Check images have labels
        let cropImage = app.images["Crop Photo"]
        XCTAssertTrue(cropImage.exists)
        XCTAssertNotNil(cropImage.label)
    }
    
    func testDynamicTypeSupport() {
        // Test with larger text sizes
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        app.launch()
        
        // Verify UI still accessible
        XCTAssertTrue(app.buttons["Dashboard"].isHittable)
    }
}
```

---

## 🔗 Integration Testing

### Testing Firebase Integration

```swift
class FirebaseIntegrationTests: XCTestCase {
    var userManager: UserManager!
    
    override func setUp() {
        super.setUp()
        userManager = UserManager()
    }
    
    func testUserCreationAndRetrieval() async throws {
        // Given
        let testEmail = "test\(UUID())@example.com"
        let testPassword = "TestPassword123!"
        
        // When - Create user
        try await userManager.signUp(
            email: testEmail,
            password: testPassword,
            name: "Test User"
        )
        
        // Then - Verify user created
        XCTAssertNotNil(userManager.currentUser)
        XCTAssertEqual(userManager.currentUser?.email, testEmail)
        
        // Cleanup
        try await userManager.deleteAccount()
    }
    
    func testCropFirestoreOperations() async throws {
        // Given
        let cropManager = CropManager()
        let testCrop = Crop(
            id: UUID().uuidString,
            name: "Integration Test Crop",
            type: .vegetable,
            plantingDate: Date(),
            healthStatus: .good
        )
        
        // When - Add to Firestore
        try await cropManager.addCrop(testCrop)
        
        // Then - Fetch and verify
        try await cropManager.fetchCrops(for: "test-user")
        XCTAssertTrue(cropManager.crops.contains { $0.id == testCrop.id })
        
        // Cleanup
        try await cropManager.deleteCrop(testCrop.id)
    }
}
```

---

## 📊 Test Coverage

### Viewing Coverage

**Xcode**:
1. Edit Scheme → Test → Options
2. Check "Gather coverage for"
3. Run tests (⌘U)
4. View Report Navigator → Coverage tab

**Command Line**:
```bash
xcodebuild test \
  -project Agrisense.xcodeproj \
  -scheme Agrisense \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath ./test-results.xcresult
```

### Coverage Goals

| Component | Target Coverage |
|-----------|----------------|
| Models | 90%+ |
| Managers | 80%+ |
| Services | 75%+ |
| Utilities | 85%+ |
| Views | 50%+ |
| Overall | 70%+ |

---

## ✅ Best Practices

### 1. Follow AAA Pattern

```swift
func testExample() {
    // Arrange (Given)
    let sut = SystemUnderTest()
    let input = "test input"
    
    // Act (When)
    let result = sut.process(input)
    
    // Assert (Then)
    XCTAssertEqual(result, expected)
}
```

### 2. One Assertion Per Test (Usually)

```swift
// ✅ Good - focused test
func testUserNameIsCorrect() {
    let user = User(name: "John")
    XCTAssertEqual(user.name, "John")
}

// ❌ Avoid - testing multiple things
func testUser() {
    let user = User(name: "John", age: 30, email: "john@example.com")
    XCTAssertEqual(user.name, "John")
    XCTAssertEqual(user.age, 30)
    XCTAssertEqual(user.email, "john@example.com")
}
```

### 3. Use Descriptive Test Names

```swift
// ✅ Good - clear what's being tested
func testFetchCropsReturnsEmptyArrayWhenUserHasNoCrops()
func testAddCropThrowsErrorWhenNameIsEmpty()

// ❌ Avoid - unclear
func testCrops()
func testError()
```

### 4. Test Edge Cases

```swift
func testWithEmptyInput()
func testWithNilValue()
func testWithMaximumValue()
func testWithNegativeValue()
func testWithSpecialCharacters()
```

### 5. Clean Up After Tests

```swift
override func tearDown() {
    sut = nil
    // Clean up any test data
    // Reset singletons
    super.tearDown()
}
```

---

## 🚀 CI/CD Integration

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app
    
    - name: Run tests
      run: |
        xcodebuild test \
          -project Agrisense.xcodeproj \
          -scheme Agrisense \
          -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
          -enableCodeCoverage YES
    
    - name: Upload coverage
      uses: codecov/codecov-action@v2
```

---

## 📚 Related Documentation

- [Contributing Guide](Contributing.md)
- [Coding Standards](Coding-Standards.md)
- [Project Architecture](Project-Architecture.md)

---

**Questions about testing?** [Create an issue](https://github.com/Athar891/AgrisenseiOS/issues)
