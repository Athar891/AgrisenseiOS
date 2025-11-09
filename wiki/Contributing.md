# 🤝 Contributing Guide

Thank you for your interest in contributing to AgriSense! This guide will help you get started with contributing to the project.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)

---

## 📜 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of:
- Experience level
- Gender identity and expression
- Sexual orientation
- Disability
- Personal appearance
- Body size
- Race or ethnicity
- Age
- Religion
- Nationality

### Our Standards

**Positive Behavior**:
- ✅ Using welcoming and inclusive language
- ✅ Being respectful of differing viewpoints
- ✅ Gracefully accepting constructive criticism
- ✅ Focusing on what's best for the community
- ✅ Showing empathy towards others

**Unacceptable Behavior**:
- ❌ Trolling, insulting, or derogatory comments
- ❌ Personal or political attacks
- ❌ Public or private harassment
- ❌ Publishing others' private information
- ❌ Unprofessional conduct

---

## 🚀 Getting Started

### Prerequisites

1. **Read the Documentation**
   - [Installation Guide](Installation-Guide.md)
   - [Quick Start](Quick-Start.md)
   - [Project Architecture](Project-Architecture.md)

2. **Setup Development Environment**
   ```bash
   # Clone the repository
   git clone https://github.com/Athar891/AgrisenseiOS.git
   cd AgrisenseiOS
   
   # Install dependencies (Xcode handles SPM packages)
   open Agrisense.xcodeproj
   ```

3. **Create a GitHub Account**
   - Fork the repository
   - Star the project ⭐

### First Contribution

**Good First Issues**:
- Look for issues tagged with `good first issue`
- Documentation improvements
- Bug fixes
- UI enhancements
- Test coverage improvements

**Where to Start**:
1. Browse [open issues](https://github.com/Athar891/AgrisenseiOS/issues)
2. Comment on issue you want to work on
3. Wait for maintainer approval
4. Fork and create branch
5. Start coding!

---

## 🔄 Development Workflow

### 1. Fork & Clone

```bash
# Fork repository on GitHub (click Fork button)

# Clone your fork
git clone https://github.com/YOUR_USERNAME/AgrisenseiOS.git
cd AgrisenseiOS

# Add upstream remote
git remote add upstream https://github.com/Athar891/AgrisenseiOS.git
```

### 2. Create Feature Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description

# Or for documentation
git checkout -b docs/what-you-are-documenting
```

**Branch Naming Convention**:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation
- `refactor/` - Code refactoring
- `test/` - Test improvements
- `chore/` - Maintenance tasks

### 3. Make Changes

```bash
# Open in Xcode
open Agrisense.xcodeproj

# Make your changes
# Follow coding standards (see below)
# Write tests
# Update documentation
```

### 4. Test Your Changes

```bash
# Run tests in Xcode
⌘U

# Or via command line
xcodebuild test \
  -project Agrisense.xcodeproj \
  -scheme Agrisense \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro'

# Test on physical device
# Build and run on multiple iOS versions
```

### 5. Commit Changes

```bash
# Stage changes
git add .

# Commit with meaningful message
git commit -m "Add: feature description"

# Or use conventional commits
git commit -m "feat: add crop disease detection"
```

### 6. Push to Fork

```bash
# Push to your fork
git push origin feature/your-feature-name
```

### 7. Create Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Fill in PR template
4. Request review from maintainers
5. Address review comments
6. Wait for approval and merge

---

## 📝 Coding Standards

### Swift Style Guide

#### 1. Naming Conventions

```swift
// Classes, Structs, Enums, Protocols: PascalCase
class UserManager { }
struct Crop { }
enum CropType { }
protocol Identifiable { }

// Variables, Functions, Properties: camelCase
var userName: String
func fetchCrops() { }
let isLoading: Bool

// Constants: camelCase or SCREAMING_SNAKE_CASE for globals
let maxRetries = 3
let API_BASE_URL = "https://api.example.com"

// Boolean variables: should read as assertions
var isLoading: Bool  // ✅
var loading: Bool    // ❌

var hasError: Bool   // ✅
var error: Bool      // ❌
```

#### 2. Code Organization

```swift
// MARK: - Type Definition
class CropManager: ObservableObject {
    
    // MARK: - Properties
    @Published var crops: [Crop] = []
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        // Setup
    }
    
    // MARK: - Public Methods
    func fetchCrops() async throws {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func validateCrop(_ crop: Crop) -> Bool {
        // Implementation
    }
}
```

#### 3. SwiftUI View Structure

```swift
struct CropListView: View {
    // MARK: - Properties
    @StateObject private var cropManager = CropManager()
    @State private var isShowingAddView = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Crops")
                .toolbar { toolbarContent }
        }
    }
    
    // MARK: - View Components
    private var contentView: some View {
        List(cropManager.crops) { crop in
            CropRow(crop: crop)
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Add") { isShowingAddView = true }
        }
    }
}
```

#### 4. Error Handling

```swift
// Use custom error types
enum CropError: LocalizedError {
    case invalidInput
    case networkFailure
    case notFound(id: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid crop data provided"
        case .networkFailure:
            return "Network connection failed"
        case .notFound(let id):
            return "Crop with ID \(id) not found"
        }
    }
}

// Use Result type for complex operations
func fetchCrop(id: String) async -> Result<Crop, CropError> {
    // Implementation
}

// Use throws for straightforward operations
func saveCrop(_ crop: Crop) async throws {
    // Implementation
}
```

#### 5. Comments & Documentation

```swift
/// Manages crop data and operations
///
/// This class handles all crop-related operations including:
/// - Fetching crops from Firestore
/// - Creating and updating crops
/// - Deleting crops
/// - Image upload to Cloudinary
class CropManager: ObservableObject {
    
    /// Fetches all crops for the current user
    ///
    /// - Returns: Array of crops
    /// - Throws: `CropError.networkFailure` if network request fails
    func fetchCrops() async throws -> [Crop] {
        // Implementation
    }
}
```

### Code Quality

#### ✅ DO's

```swift
// Use meaningful variable names
let userName = user.name  // ✅
let x = user.name        // ❌

// Use guard for early returns
guard let user = currentUser else { return }  // ✅
if currentUser == nil { return }  // ❌ (less clear)

// Use async/await
func fetchData() async throws {  // ✅
    let data = try await service.fetch()
}

// Use type inference when obvious
let count = 0  // ✅
let count: Int = 0  // ❌ (redundant)

// Use trailing closures
button.action {  // ✅
    doSomething()
}
```

#### ❌ DON'Ts

```swift
// Don't use force unwrapping (except in tests)
let name = user.name!  // ❌ Dangerous

// Don't use magic numbers
if crops.count > 50 { }  // ❌
let maxCrops = 50
if crops.count > maxCrops { }  // ✅

// Don't create massive functions
func doEverything() {  // ❌
    // 500 lines of code
}

// Don't ignore errors
try? riskyOperation()  // ❌ (usually)
do {  // ✅
    try riskyOperation()
} catch {
    handleError(error)
}
```

---

## 💬 Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```bash
# Feature
git commit -m "feat(crops): add disease detection feature"

# Bug fix
git commit -m "fix(auth): resolve Google Sign-In crash on iOS 16"

# Documentation
git commit -m "docs(readme): update installation instructions"

# With body
git commit -m "feat(ai): add voice interruption support

Added ability to interrupt AI while speaking by:
- Implementing stop mechanism in TTS service
- Adding interrupt button to UI
- Handling state transitions properly

Closes #123"
```

---

## 🔀 Pull Request Process

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed
- [ ] Tested on physical device

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests pass locally
```

### Review Process

1. **Automated Checks**
   - Build success
   - Tests pass
   - No SwiftLint violations

2. **Code Review**
   - At least one approval required
   - Address all comments
   - Resolve all conversations

3. **Merge**
   - Squash and merge (default)
   - Delete branch after merge

---

## 🧪 Testing Requirements

### Minimum Requirements

- **Unit Test Coverage**: > 70%
- **UI Test Coverage**: Critical user flows
- **No Crashes**: On iOS 16, 17
- **Performance**: No regressions

### Writing Tests

```swift
// Unit Test Example
class CropManagerTests: XCTestCase {
    var sut: CropManager!
    
    override func setUp() {
        super.setUp()
        sut = CropManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testFetchCrops() async throws {
        // Given
        let expectedCount = 5
        
        // When
        try await sut.fetchCrops()
        
        // Then
        XCTAssertEqual(sut.crops.count, expectedCount)
    }
}
```

---

## 📚 Documentation

### Requirements

- Update README.md if needed
- Add inline comments for complex logic
- Update wiki pages for new features
- Include code examples
- Add screenshots for UI changes

### Documentation Style

```swift
/// Brief one-line description
///
/// Detailed description explaining:
/// - What the function does
/// - When to use it
/// - Any important considerations
///
/// - Parameters:
///   - param1: Description of param1
///   - param2: Description of param2
/// - Returns: Description of return value
/// - Throws: Possible errors that can be thrown
///
/// # Example
/// ```swift
/// let result = try await function(param1: value1, param2: value2)
/// ```
func function(param1: Type1, param2: Type2) async throws -> ReturnType {
    // Implementation
}
```

---

## 🏆 Recognition

### Contributors

All contributors will be:
- Listed in CONTRIBUTORS.md
- Credited in release notes
- Mentioned in project README
- Given contributor badge

### Star Contributors

Contributors with significant impact may receive:
- Special recognition
- Priority review
- Collaborator status

---

## ❓ Questions?

- **General Questions**: [Discussions](https://github.com/Athar891/AgrisenseiOS/discussions)
- **Bug Reports**: [Issues](https://github.com/Athar891/AgrisenseiOS/issues)
- **Security Issues**: security@agrisense.app
- **Email**: support@agrisense.app

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

<div align="center">

**Thank you for contributing to AgriSense! 🌾**

Every contribution, no matter how small, helps make farming smarter.

</div>
