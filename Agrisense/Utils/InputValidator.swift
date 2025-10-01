//
//  InputValidator.swift
//  Agrisense
//
//  Created by Security Audit on 01/10/25.
//

import Foundation

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case emptyField(String)
    case fieldTooShort(String, minLength: Int)
    case fieldTooLong(String, maxLength: Int)
    case invalidFormat(String)
    case invalidCharacters(String)
    case weakPassword
    case invalidEmail
    case invalidPhoneNumber
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) is required"
        case .fieldTooShort(let field, let minLength):
            return "\(field) must be at least \(minLength) characters"
        case .fieldTooLong(let field, let maxLength):
            return "\(field) must not exceed \(maxLength) characters"
        case .invalidFormat(let field):
            return "\(field) format is invalid"
        case .invalidCharacters(let field):
            return "\(field) contains invalid characters"
        case .weakPassword:
            return "Password must be at least 10 characters and contain uppercase, lowercase, number, and special character"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPhoneNumber:
            return "Please enter a valid phone number (10-15 digits)"
        }
    }
}

// MARK: - Input Validator

class InputValidator {
    
    // MARK: - Email Validation
    
    static func validateEmail(_ email: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            throw ValidationError.emptyField("Email")
        }
        
        // RFC 5322 compliant email regex (simplified)
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            throw ValidationError.invalidEmail
        }
        
        // Additional validation
        let components = trimmedEmail.split(separator: "@")
        guard components.count == 2,
              !components[0].isEmpty,
              !components[1].isEmpty,
              components[1].contains(".") else {
            throw ValidationError.invalidEmail
        }
    }
    
    // MARK: - Password Validation
    
    static func validatePassword(_ password: String) throws {
        guard !password.isEmpty else {
            throw ValidationError.emptyField("Password")
        }
        
        // Minimum length check
        guard password.count >= 10 else {
            throw ValidationError.fieldTooShort("Password", minLength: 10)
        }
        
        // Maximum length check (prevent DoS)
        guard password.count <= 128 else {
            throw ValidationError.fieldTooLong("Password", maxLength: 128)
        }
        
        // Complexity requirements
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        let complexityCount = [hasUppercase, hasLowercase, hasNumber, hasSpecialChar].filter { $0 }.count
        
        guard complexityCount >= 3 else {
            throw ValidationError.weakPassword
        }
        
        // Check against common weak passwords
        let lowercasePassword = password.lowercased()
        let commonPasswords = [
            "password", "12345678", "123456789", "1234567890",
            "qwerty", "abc123", "password1", "password123",
            "welcome", "monkey", "dragon"
        ]
        
        for common in commonPasswords {
            if lowercasePassword.contains(common) {
                throw ValidationError.weakPassword
            }
        }
    }
    
    // MARK: - Text Field Validation
    
    static func validateTextField(
        _ text: String,
        fieldName: String,
        minLength: Int = 1,
        maxLength: Int,
        allowedCharacters: CharacterSet? = nil,
        disallowControlCharacters: Bool = true
    ) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyField(fieldName)
        }
        
        guard trimmed.count >= minLength else {
            throw ValidationError.fieldTooShort(fieldName, minLength: minLength)
        }
        
        guard trimmed.count <= maxLength else {
            throw ValidationError.fieldTooLong(fieldName, maxLength: maxLength)
        }
        
        // Check for control characters (except newlines and tabs)
        if disallowControlCharacters {
            let disallowed = CharacterSet.controlCharacters.subtracting(.whitespacesAndNewlines)
            if trimmed.rangeOfCharacter(from: disallowed) != nil {
                throw ValidationError.invalidCharacters(fieldName)
            }
        }
        
        // Check against allowed character set if provided
        if let allowedChars = allowedCharacters {
            let textCharSet = CharacterSet(charactersIn: trimmed)
            if !allowedChars.isSuperset(of: textCharSet) {
                throw ValidationError.invalidCharacters(fieldName)
            }
        }
    }
    
    // MARK: - Phone Number Validation
    
    static func validatePhoneNumber(_ phoneNumber: String, required: Bool = false) throws {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            if required {
                throw ValidationError.emptyField("Phone number")
            }
            return // Optional and empty is valid
        }
        
        // Remove common separators and spaces
        let cleaned = trimmed.replacingOccurrences(
            of: "[^0-9+]",
            with: "",
            options: .regularExpression
        )
        
        // Check for valid patterns
        // International: +[1-9][0-9]{1,14}
        // Domestic: [0-9]{10,15}
        let internationalPattern = "^\\+[1-9][0-9]{1,14}$"
        let domesticPattern = "^[0-9]{10,15}$"
        
        let internationalPredicate = NSPredicate(format: "SELF MATCHES %@", internationalPattern)
        let domesticPredicate = NSPredicate(format: "SELF MATCHES %@", domesticPattern)
        
        guard internationalPredicate.evaluate(with: cleaned) ||
              domesticPredicate.evaluate(with: cleaned) else {
            throw ValidationError.invalidPhoneNumber
        }
    }
    
    // MARK: - Name Validation
    
    static func validateName(_ name: String, fieldName: String = "Name") throws {
        try validateTextField(
            name,
            fieldName: fieldName,
            minLength: 2,
            maxLength: 100
        )
        
        // Additional check: must contain at least one letter
        let hasLetter = name.rangeOfCharacter(from: .letters) != nil
        guard hasLetter else {
            throw ValidationError.invalidFormat(fieldName)
        }
    }
    
    // MARK: - Content Validation (Posts, Comments, etc.)
    
    static func validatePostTitle(_ title: String) throws {
        try validateTextField(
            title,
            fieldName: "Title",
            minLength: 3,
            maxLength: 200,
            disallowControlCharacters: true
        )
    }
    
    static func validatePostContent(_ content: String) throws {
        try validateTextField(
            content,
            fieldName: "Content",
            minLength: 10,
            maxLength: 5000,
            disallowControlCharacters: false // Allow newlines in content
        )
        
        // Check for excessive newlines (spam detection)
        let newlineCount = content.filter { $0.isNewline }.count
        guard newlineCount < (content.count / 2) else {
            throw ValidationError.invalidFormat("Content")
        }
    }
    
    static func validateProductName(_ name: String) throws {
        try validateTextField(
            name,
            fieldName: "Product name",
            minLength: 3,
            maxLength: 100,
            disallowControlCharacters: true
        )
    }
    
    static func validateProductDescription(_ description: String) throws {
        try validateTextField(
            description,
            fieldName: "Description",
            minLength: 10,
            maxLength: 1000,
            disallowControlCharacters: false
        )
    }
    
    // MARK: - Numeric Validation
    
    static func validatePrice(_ price: Double) throws {
        guard price > 0 else {
            throw ValidationError.invalidFormat("Price")
        }
        
        guard price < 1_000_000_000 else { // 1 billion max
            throw ValidationError.invalidFormat("Price")
        }
        
        // Check for reasonable decimal places (max 2)
        let rounded = (price * 100).rounded() / 100
        guard abs(price - rounded) < 0.001 else {
            throw ValidationError.invalidFormat("Price")
        }
    }
    
    static func validateStock(_ stock: Int) throws {
        guard stock >= 0 else {
            throw ValidationError.invalidFormat("Stock")
        }
        
        guard stock <= 1_000_000 else { // Reasonable max
            throw ValidationError.invalidFormat("Stock")
        }
    }
    
    // MARK: - Crop Validation
    
    static func validateCropName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Length check
        guard trimmed.count >= 2 && trimmed.count <= 100 else {
            return false
        }
        
        // Allow letters, numbers, spaces, and hyphens
        let allowedPattern = "^[a-zA-Z0-9\\s\\-]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", allowedPattern)
        
        return predicate.evaluate(with: trimmed)
    }
    
    // MARK: - Helper Methods
    
    static func sanitizeText(_ text: String) -> String {
        // Remove control characters but keep newlines and tabs
        let allowed = CharacterSet.controlCharacters
            .subtracting(.whitespacesAndNewlines)
            .inverted
        
        return text.components(separatedBy: allowed.inverted)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        let index = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<index])
    }
}
