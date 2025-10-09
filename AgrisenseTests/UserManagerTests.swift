import Testing
import XCTest
@testable import Agrisense
import FirebaseAuth
import FirebaseFirestore

struct UserManagerTests {
    
    @Test func testUserManagerInitialization() async throws {
        // Arrange
        let userManager = UserManager()
        
        // Assert
        #expect(userManager.currentUser == nil)
        #expect(!userManager.isAuthenticated)
    }
    
    @Test func testSignUp_WithValidCredentials_ShouldSucceed() async throws {
        // Arrange
        let mockAuth = MockFirebaseAuth()
        let mockFirestore = MockFirestore()
        let userManager = UserManager(auth: mockAuth, firestore: mockFirestore)
        
        let testEmail = "test@example.com"
        let testPassword = "StrongPassword123!"
        let testName = "Test User"
        let testUserType = UserType.farmer
        
        // Act
        try await userManager.signUp(
            email: testEmail, 
            password: testPassword, 
            fullName: testName, 
            userType: testUserType
        )
        
        // Assert
        #expect(mockAuth.createdUser != nil)
        #expect(mockAuth.createdUser?.email == testEmail)
        #expect(mockFirestore.documents.count > 0)
        
        if let userData = mockFirestore.documents.first?.value as? [String: Any] {
            #expect(userData["email"] as? String == testEmail)
            #expect(userData["name"] as? String == testName)
            #expect(userData["userType"] as? String == testUserType.rawValue)
        } else {
            #fail("User data not saved to Firestore")
        }
    }
    
    @Test func testSignUp_WithInvalidEmail_ShouldThrow() async throws {
        // Arrange
        let userManager = UserManager()
        let invalidEmail = "invalid-email"
        let validPassword = "StrongPassword123!"
        
        // Act & Assert
        await #throwsError(ValidationError.invalidEmail) {
            try await userManager.signUp(
                email: invalidEmail,
                password: validPassword,
                fullName: "Test User",
                userType: .farmer
            )
        }
    }
    
    @Test func testSignUp_WithWeakPassword_ShouldThrow() async throws {
        // Arrange
        let userManager = UserManager()
        let validEmail = "test@example.com"
        let weakPassword = "password"
        
        // Act & Assert
        await #throwsError(ValidationError.weakPassword) {
            try await userManager.signUp(
                email: validEmail,
                password: weakPassword,
                fullName: "Test User",
                userType: .farmer
            )
        }
    }
    
    @Test func testSignIn_WithValidCredentials_ShouldUpdateAuthState() async throws {
        // Arrange
        let mockAuth = MockFirebaseAuth()
        let mockFirestore = MockFirestore()
        let userManager = UserManager(auth: mockAuth, firestore: mockFirestore)
        
        let testEmail = "test@example.com"
        let testPassword = "StrongPassword123!"
        let testUserId = "test-user-id"
        
        // Setup mock response
        mockAuth.setupSuccessfulSignIn(userId: testUserId)
        mockFirestore.setupUserDocument(userId: testUserId, data: [
            "name": "Test User",
            "email": testEmail,
            "userType": UserType.farmer.rawValue
        ])
        
        // Act
        try await userManager.signIn(email: testEmail, password: testPassword)
        
        // Assert
        #expect(userManager.isAuthenticated)
        #expect(userManager.currentUser != nil)
        #expect(userManager.currentUser?.email == testEmail)
        #expect(userManager.currentUser?.userType == .farmer)
    }
    
    @Test func testSignOut_WhenSignedIn_ShouldUpdateAuthState() async throws {
        // Arrange
        let mockAuth = MockFirebaseAuth()
        let userManager = UserManager(auth: mockAuth)
        mockAuth.setupSuccessfulSignIn(userId: "test-user-id")
        
        // Sign in first
        try await userManager.signIn(email: "test@example.com", password: "StrongPassword123!")
        #expect(userManager.isAuthenticated)
        
        // Act
        try await userManager.signOut()
        
        // Assert
        #expect(!userManager.isAuthenticated)
        #expect(userManager.currentUser == nil)
    }
    
    @Test func testUpdateProfile_WithValidData_ShouldSucceed() async throws {
        // Arrange
        let mockAuth = MockFirebaseAuth()
        let mockFirestore = MockFirestore()
        let userManager = UserManager(auth: mockAuth, firestore: mockFirestore)
        
        let userId = "test-user-id"
        mockAuth.setupSuccessfulSignIn(userId: userId)
        mockFirestore.setupUserDocument(userId: userId, data: [
            "name": "Original Name",
            "email": "test@example.com",
            "userType": UserType.farmer.rawValue
        ])
        
        // Sign in first
        try await userManager.signIn(email: "test@example.com", password: "StrongPassword123!")
        
        // Act
        try await userManager.updateProfile(fullName: "Updated Name", phoneNumber: "1234567890", location: "Test Location")
        
        // Assert
        let updatedData = mockFirestore.getDocument(collection: "users", documentId: userId)
        #expect(updatedData?["name"] as? String == "Updated Name")
        #expect(updatedData?["phoneNumber"] as? String == "1234567890")
        #expect(updatedData?["location"] as? String == "Test Location")
    }
    
    @Test func testRateLimiting_ExceedsLimit_ShouldThrow() async throws {
        // Arrange
        let userManager = UserManager()
        let email = "test@example.com"
        let password = "StrongPassword123!"
        
        // Manually trigger rate limit
        for _ in 1...RateLimitConfig.signupMaxAttempts {
            RateLimiter.shared.recordEvent(key: "signup_\(email)")
        }
        
        // Act & Assert
        await #throwsError { error in
            if case RateLimitError.exceeded = error {
                return true
            }
            return false
        } running: {
            try await userManager.signUp(
                email: email,
                password: password,
                fullName: "Test User",
                userType: .farmer
            )
        }
    }
}

// MARK: - Mock Classes for Testing

class MockFirebaseAuth {
    var createdUser: MockUser?
    var currentUser: MockUser?
    var signOutCalled = false
    var authStateListeners = [(FirebaseAuth.User?) -> Void]()
    
    func createUser(withEmail email: String, password: String) async throws -> AuthDataResult {
        let mockUser = MockUser(uid: UUID().uuidString, email: email)
        self.createdUser = mockUser
        let mockAuthResult = MockAuthDataResult(user: mockUser)
        return mockAuthResult
    }
    
    func signIn(withEmail email: String, password: String) async throws -> AuthDataResult {
        guard let currentUser = self.currentUser else {
            throw NSError(domain: "FirebaseAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mock user set"])
        }
        return MockAuthDataResult(user: currentUser)
    }
    
    func signOut() throws {
        signOutCalled = true
        currentUser = nil
        notifyAuthStateListeners()
    }
    
    func setupSuccessfulSignIn(userId: String) {
        let mockUser = MockUser(uid: userId, email: "test@example.com")
        self.currentUser = mockUser
        notifyAuthStateListeners()
    }
    
    func addStateDidChangeListener(_ listener: @escaping (Auth, FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        let handle = UUID().uuidString
        authStateListeners.append({ user in
            listener(Auth.auth(), user)
        })
        return handle
    }
    
    func notifyAuthStateListeners() {
        for listener in authStateListeners {
            listener(self.currentUser)
        }
    }
}

class MockUser: FirebaseAuth.User {
    let uid: String
    let email: String?
    
    init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
    
    func createProfileChangeRequest() -> UserProfileChangeRequest {
        return MockUserProfileChangeRequest()
    }
}

class MockUserProfileChangeRequest: UserProfileChangeRequest {
    var displayName: String?
    
    func commitChanges() async throws {
        // Simulates successful profile update
    }
}

class MockAuthDataResult: AuthDataResult {
    let user: FirebaseAuth.User
    
    init(user: FirebaseAuth.User) {
        self.user = user
    }
}

class MockFirestore {
    var documents = [String: Any]()
    
    func collection(_ collectionPath: String) -> MockCollectionReference {
        return MockCollectionReference(firestore: self, path: collectionPath)
    }
    
    func setupUserDocument(userId: String, data: [String: Any]) {
        documents["users/\(userId)"] = data
    }
    
    func getDocument(collection: String, documentId: String) -> [String: Any]? {
        return documents["\(collection)/\(documentId)"] as? [String: Any]
    }
}

class MockCollectionReference {
    let firestore: MockFirestore
    let path: String
    
    init(firestore: MockFirestore, path: String) {
        self.firestore = firestore
        self.path = path
    }
    
    func document(_ documentPath: String) -> MockDocumentReference {
        return MockDocumentReference(firestore: firestore, path: "\(path)/\(documentPath)")
    }
}

class MockDocumentReference {
    let firestore: MockFirestore
    let path: String
    
    init(firestore: MockFirestore, path: String) {
        self.firestore = firestore
        self.path = path
    }
    
    func setData(_ data: [String: Any]) async throws {
        firestore.documents[path] = data
    }
    
    func updateData(_ data: [String: Any]) async throws {
        if var existingData = firestore.documents[path] as? [String: Any] {
            for (key, value) in data {
                existingData[key] = value
            }
            firestore.documents[path] = existingData
        } else {
            firestore.documents[path] = data
        }
    }
    
    func getDocument() async throws -> MockDocumentSnapshot {
        return MockDocumentSnapshot(data: firestore.documents[path] as? [String: Any])
    }
}

class MockDocumentSnapshot {
    let data: [String: Any]?
    
    init(data: [String: Any]?) {
        self.data = data
    }
    
    func data() -> [String: Any]? {
        return data
    }
    
    var exists: Bool {
        return data != nil
    }
}

// Extend UserManager for testability
extension UserManager {
    convenience init(auth: MockFirebaseAuth, firestore: MockFirestore? = nil) {
        self.init()
        // This would normally inject the mock dependencies
        // For real implementation, you'd need to modify the UserManager class
    }
}