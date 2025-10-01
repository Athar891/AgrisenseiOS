//
//  SecureStorage.swift
//  Agrisense
//
//  Created by Security Audit on 01/10/25.
//

import Foundation
import Security

// MARK: - Secure Storage Errors

enum SecureStorageError: LocalizedError {
    case saveFailed
    case loadFailed
    case deleteFailed
    case itemNotFound
    case invalidData
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data securely"
        case .loadFailed:
            return "Failed to load secure data"
        case .deleteFailed:
            return "Failed to delete secure data"
        case .itemNotFound:
            return "Secure item not found"
        case .invalidData:
            return "Invalid data format"
        case .accessDenied:
            return "Access to secure storage denied"
        }
    }
}

// MARK: - Secure Storage

/// Thread-safe keychain wrapper for storing sensitive data
class SecureStorage {
    static let shared = SecureStorage()
    
    private let serviceName = "com.AgriSense.Agrisense"
    private let accessGroup: String? = nil // Set this for app group sharing
    
    private init() {}
    
    // MARK: - String Storage
    
    /// Save a string securely to keychain
    func save(_ string: String, forKey key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw SecureStorageError.invalidData
        }
        try save(data, forKey: key)
    }
    
    /// Load a string from keychain
    func loadString(forKey key: String) throws -> String {
        let data = try load(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecureStorageError.invalidData
        }
        return string
    }
    
    // MARK: - Data Storage
    
    /// Save data securely to keychain
    func save(_ data: Data, forKey key: String) throws {
        // Build query
        var query = buildBaseQuery(forKey: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            #if DEBUG
            print("SecureStorage: Save failed with status \(status)")
            #endif
            throw SecureStorageError.saveFailed
        }
    }
    
    /// Load data from keychain
    func load(forKey key: String) throws -> Data {
        var query = buildBaseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw SecureStorageError.itemNotFound
            }
            #if DEBUG
            print("SecureStorage: Load failed with status \(status)")
            #endif
            throw SecureStorageError.loadFailed
        }
        
        guard let data = result as? Data else {
            throw SecureStorageError.invalidData
        }
        
        return data
    }
    
    /// Delete item from keychain
    func delete(forKey key: String) throws {
        let query = buildBaseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            #if DEBUG
            print("SecureStorage: Delete failed with status \(status)")
            #endif
            throw SecureStorageError.deleteFailed
        }
    }
    
    /// Check if item exists in keychain
    func exists(forKey key: String) -> Bool {
        var query = buildBaseQuery(forKey: key)
        query[kSecReturnData as String] = false
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Clear all items from keychain for this service
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.deleteFailed
        }
    }
    
    // MARK: - Codable Support
    
    /// Save a Codable object securely
    func save<T: Codable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(object)
        try save(data, forKey: key)
    }
    
    /// Load a Codable object from keychain
    func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T {
        let data = try load(forKey: key)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
    
    // MARK: - Helper Methods
    
    private func buildBaseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
}

// MARK: - Convenience Keys

extension SecureStorage {
    enum Key {
        static let apiToken = "api_token"
        static let userSession = "user_session"
        static let refreshToken = "refresh_token"
        static let encryptionKey = "encryption_key"
        
        // Add more keys as needed
    }
}

// MARK: - Migration Helper

extension SecureStorage {
    
    /// Migrate data from UserDefaults to secure storage
    func migrateFromUserDefaults(key: String, userDefaultsKey: String? = nil) {
        let udKey = userDefaultsKey ?? key
        let userDefaults = UserDefaults.standard
        
        // Check if already migrated
        if exists(forKey: key) {
            // Clean up UserDefaults
            userDefaults.removeObject(forKey: udKey)
            return
        }
        
        // Migrate string
        if let stringValue = userDefaults.string(forKey: udKey) {
            try? save(stringValue, forKey: key)
            userDefaults.removeObject(forKey: udKey)
            return
        }
        
        // Migrate data
        if let dataValue = userDefaults.data(forKey: udKey) {
            try? save(dataValue, forKey: key)
            userDefaults.removeObject(forKey: udKey)
        }
    }
}
