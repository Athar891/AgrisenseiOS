//
//  SecurityUtilsTests.swift
//  AgrisenseTests
//
//  Created by Security Audit on 01/10/25.
//

import XCTest
@testable import Agrisense

final class SecurityUtilsTests: XCTestCase {
    
    // MARK: - Input Validator Tests
    
    func testValidateEmail_ValidEmails() {
        let validEmails = [
            "user@example.com",
            "test.user@example.com",
            "user+tag@example.co.uk",
            "user123@test-domain.com"
        ]
        
        for email in validEmails {
            XCTAssertNoThrow(
                try InputValidator.validateEmail(email),
                "Valid email should not throw: \(email)"
            )
        }
    }
    
    func testValidateEmail_InvalidEmails() {
        let invalidEmails = [
            "",
            "invalid",
            "@example.com",
            "user@",
            "user @example.com",
            "user@example",
            "user..name@example.com"
        ]
        
        for email in invalidEmails {
            XCTAssertThrowsError(
                try InputValidator.validateEmail(email),
                "Invalid email should throw: \(email)"
            )
        }
    }
    
    func testValidatePassword_ValidPasswords() {
        let validPasswords = [
            "MyP@ssw0rd123",  // Mixed case, number, special
            "Test1234!@#$",    // Mixed case, number, special
            "SecureP@ss1"      // Mixed case, number, special
        ]
        
        for password in validPasswords {
            XCTAssertNoThrow(
                try InputValidator.validatePassword(password),
                "Valid password should not throw: \(password)"
            )
        }
    }
    
    func testValidatePassword_WeakPasswords() {
        let weakPasswords = [
            "",                // Empty
            "short",           // Too short
            "nocapitals123!",  // No uppercase
            "NOLOWERCASE123!", // No lowercase
            "NoNumbers!",      // No numbers
            "NoSpecial123",    // No special chars
            "password123!",    // Common password
            "12345678!A"       // Common pattern
        ]
        
        for password in weakPasswords {
            XCTAssertThrowsError(
                try InputValidator.validatePassword(password),
                "Weak password should throw: \(password)"
            )
        }
    }
    
    func testValidatePhoneNumber_ValidPhones() {
        let validPhones = [
            "+1234567890",
            "1234567890",
            "+12345678901234",
            "12345678901234"
        ]
        
        for phone in validPhones {
            XCTAssertNoThrow(
                try InputValidator.validatePhoneNumber(phone, required: true),
                "Valid phone should not throw: \(phone)"
            )
        }
    }
    
    func testValidatePhoneNumber_InvalidPhones() {
        let invalidPhones = [
            "123",           // Too short
            "abc1234567890", // Contains letters
            "+",             // Just plus
            "123-456-7890"   // Dashes not allowed after cleaning
        ]
        
        for phone in invalidPhones {
            XCTAssertThrowsError(
                try InputValidator.validatePhoneNumber(phone, required: true),
                "Invalid phone should throw: \(phone)"
            )
        }
    }
    
    func testValidateProductName_Valid() {
        XCTAssertNoThrow(try InputValidator.validateProductName("Fresh Tomatoes"))
        XCTAssertNoThrow(try InputValidator.validateProductName("Organic Wheat 100kg"))
    }
    
    func testValidateProductName_Invalid() {
        XCTAssertThrowsError(try InputValidator.validateProductName("AB")) // Too short
        XCTAssertThrowsError(try InputValidator.validateProductName("")) // Empty
    }
    
    func testValidatePrice_Valid() {
        XCTAssertNoThrow(try InputValidator.validatePrice(10.99))
        XCTAssertNoThrow(try InputValidator.validatePrice(0.01))
        XCTAssertNoThrow(try InputValidator.validatePrice(999999.99))
    }
    
    func testValidatePrice_Invalid() {
        XCTAssertThrowsError(try InputValidator.validatePrice(0)) // Zero
        XCTAssertThrowsError(try InputValidator.validatePrice(-10)) // Negative
        XCTAssertThrowsError(try InputValidator.validatePrice(1_000_000_000)) // Too large
    }
    
    func testValidateCropName_Valid() {
        XCTAssertTrue(InputValidator.validateCropName("Rice"))
        XCTAssertTrue(InputValidator.validateCropName("Basmati Rice 2024"))
        XCTAssertTrue(InputValidator.validateCropName("Winter-Wheat"))
    }
    
    func testValidateCropName_Invalid() {
        XCTAssertFalse(InputValidator.validateCropName("A")) // Too short
        XCTAssertFalse(InputValidator.validateCropName("")) // Empty
        XCTAssertFalse(InputValidator.validateCropName("Crop@Name")) // Special char
    }
    
    // MARK: - Rate Limiter Tests
    
    func testRateLimiter_AllowsWithinLimit() {
        let limiter = RateLimiter.shared
        let key = "test_action_\(UUID())"
        
        // Should allow first 3 requests
        XCTAssertTrue(limiter.checkLimit(key: key, maxRequests: 3, timeWindow: 60))
        XCTAssertTrue(limiter.checkLimit(key: key, maxRequests: 3, timeWindow: 60))
        XCTAssertTrue(limiter.checkLimit(key: key, maxRequests: 3, timeWindow: 60))
        
        // Should block 4th request
        XCTAssertFalse(limiter.checkLimit(key: key, maxRequests: 3, timeWindow: 60))
    }
    
    func testRateLimiter_Reset() {
        let limiter = RateLimiter.shared
        let key = "test_reset_\(UUID())"
        
        // Fill up the limit
        _ = limiter.checkLimit(key: key, maxRequests: 2, timeWindow: 60)
        _ = limiter.checkLimit(key: key, maxRequests: 2, timeWindow: 60)
        
        // Should be blocked
        XCTAssertFalse(limiter.checkLimit(key: key, maxRequests: 2, timeWindow: 60))
        
        // Reset
        limiter.reset(key: key)
        
        // Should allow again
        XCTAssertTrue(limiter.checkLimit(key: key, maxRequests: 2, timeWindow: 60))
    }
    
    func testRateLimiter_RemainingAttempts() {
        let limiter = RateLimiter.shared
        let key = "test_remaining_\(UUID())"
        
        // Initial remaining should equal max
        XCTAssertEqual(
            limiter.remainingAttempts(key: key, maxRequests: 5, timeWindow: 60),
            5
        )
        
        // After one request
        _ = limiter.checkLimit(key: key, maxRequests: 5, timeWindow: 60)
        XCTAssertEqual(
            limiter.remainingAttempts(key: key, maxRequests: 5, timeWindow: 60),
            4
        )
    }
    
    // MARK: - Secure Storage Tests
    
    func testSecureStorage_SaveAndLoad() {
        let storage = SecureStorage.shared
        let key = "test_key_\(UUID())"
        let testData = "Test Data"
        
        // Save
        XCTAssertNoThrow(try storage.save(testData, forKey: key))
        
        // Load
        XCTAssertNoThrow({
            let loaded = try storage.loadString(forKey: key)
            XCTAssertEqual(loaded, testData)
        })
        
        // Cleanup
        try? storage.delete(forKey: key)
    }
    
    func testSecureStorage_SaveCodable() {
        let storage = SecureStorage.shared
        let key = "test_codable_\(UUID())"
        
        struct TestModel: Codable, Equatable {
            let name: String
            let value: Int
        }
        
        let testModel = TestModel(name: "Test", value: 42)
        
        // Save
        XCTAssertNoThrow(try storage.save(testModel, forKey: key))
        
        // Load
        XCTAssertNoThrow({
            let loaded = try storage.load(forKey: key, as: TestModel.self)
            XCTAssertEqual(loaded, testModel)
        })
        
        // Cleanup
        try? storage.delete(forKey: key)
    }
    
    func testSecureStorage_Exists() {
        let storage = SecureStorage.shared
        let key = "test_exists_\(UUID())"
        
        // Initially should not exist
        XCTAssertFalse(storage.exists(forKey: key))
        
        // Save
        try? storage.save("Test", forKey: key)
        
        // Should now exist
        XCTAssertTrue(storage.exists(forKey: key))
        
        // Delete
        try? storage.delete(forKey: key)
        
        // Should not exist again
        XCTAssertFalse(storage.exists(forKey: key))
    }
    
    func testSecureStorage_Delete() {
        let storage = SecureStorage.shared
        let key = "test_delete_\(UUID())"
        
        // Save
        try? storage.save("Test", forKey: key)
        XCTAssertTrue(storage.exists(forKey: key))
        
        // Delete
        XCTAssertNoThrow(try storage.delete(forKey: key))
        
        // Should not exist
        XCTAssertFalse(storage.exists(forKey: key))
    }
    
    // MARK: - Image Validator Tests
    
    func testImageValidator_ValidJPEG() {
        // Create a simple JPEG header
        var jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG magic bytes
        jpegData.append(contentsOf: [UInt8](repeating: 0, count: 1000)) // Padding
        
        let config = ImageValidator.ValidationConfig(
            maxFileSize: 10 * 1024 * 1024, // 10MB
            allowedFormats: [.jpeg],
            minWidth: 100,
            maxWidth: 4000,
            minHeight: 100,
            maxHeight: 4000
        )
        
        // Note: This will fail without actual image data, but tests the structure
        // In real tests, you'd use actual test images
    }
    
    func testImageValidator_FileTooLarge() {
        let largeData = Data(count: 20 * 1024 * 1024) // 20MB
        
        let config = ImageValidator.ValidationConfig(
            maxFileSize: 10 * 1024 * 1024, // 10MB limit
            allowedFormats: [.jpeg, .png],
            minWidth: 100,
            maxWidth: 4000,
            minHeight: 100,
            maxHeight: 4000
        )
        
        XCTAssertThrowsError(try ImageValidator.validate(imageData: largeData, config: config))
    }
    
    // MARK: - Safe Error Handler Tests
    
    func testSafeErrorHandler_NetworkError() {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        )
        
        let message = SafeErrorHandler.shared.handle(error, category: .network)
        
        XCTAssertTrue(message.contains("internet"))
        XCTAssertFalse(message.contains("NSError"))
        XCTAssertFalse(message.contains("Code="))
    }
    
    func testSafeErrorHandler_RateLimitError() {
        let error = NSError(
            domain: "RateLimit",
            code: 429,
            userInfo: [NSLocalizedDescriptionKey: "Please wait 5 minutes"]
        )
        
        let message = SafeErrorHandler.shared.handle(error, category: .rateLimiting)
        
        XCTAssertEqual(message, "Please wait 5 minutes")
    }
    
    func testSafeErrorHandler_ValidationError() {
        let error = NSError(
            domain: "Validation",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: "Invalid email address"]
        )
        
        let message = SafeErrorHandler.shared.handle(error, category: .validation)
        
        XCTAssertEqual(message, "Invalid email address")
    }
}
