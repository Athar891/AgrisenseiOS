//
//  RateLimiter.swift
//  Agrisense
//
//  Created by Security Audit on 01/10/25.
//

import Foundation

// MARK: - Rate Limiter

/// Thread-safe rate limiter to prevent abuse and brute force attacks
class RateLimiter {
    static let shared = RateLimiter()
    
    private var timestamps: [String: [Date]] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    /// Check if action is allowed within rate limit
    /// - Parameters:
    ///   - key: Unique identifier for the action (e.g., "login_user@example.com")
    ///   - maxRequests: Maximum number of requests allowed
    ///   - timeWindow: Time window in seconds
    /// - Returns: True if action is allowed, false if rate limit exceeded
    func checkLimit(key: String, maxRequests: Int, timeWindow: TimeInterval) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        let windowStart = now.addingTimeInterval(-timeWindow)
        
        // Clean up old timestamps outside the window
        timestamps[key] = timestamps[key]?.filter { $0 > windowStart } ?? []
        
        // Check if limit is exceeded
        guard let count = timestamps[key]?.count, count < maxRequests else {
            return false
        }
        
        // Add new timestamp
        timestamps[key, default: []].append(now)
        return true
    }
    
    /// Reset rate limit for a specific key
    func reset(key: String) {
        lock.lock()
        defer { lock.unlock() }
        timestamps.removeValue(forKey: key)
    }
    
    /// Clear all rate limit data
    func clearAll() {
        lock.lock()
        defer { lock.unlock() }
        timestamps.removeAll()
    }
    
    /// Get remaining attempts for a key
    func remainingAttempts(key: String, maxRequests: Int, timeWindow: TimeInterval) -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        let windowStart = now.addingTimeInterval(-timeWindow)
        
        // Clean up old timestamps
        timestamps[key] = timestamps[key]?.filter { $0 > windowStart } ?? []
        
        let currentCount = timestamps[key]?.count ?? 0
        return max(0, maxRequests - currentCount)
    }
    
    /// Get time until rate limit resets
    func timeUntilReset(key: String, timeWindow: TimeInterval) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let oldestTimestamp = timestamps[key]?.first else {
            return nil
        }
        
        let resetTime = oldestTimestamp.addingTimeInterval(timeWindow)
        let timeRemaining = resetTime.timeIntervalSince(Date())
        
        return max(0, timeRemaining)
    }
}

// MARK: - Rate Limit Configuration

enum RateLimitConfig {
    // Authentication limits
    static let loginMaxAttempts = 5
    static let loginTimeWindow: TimeInterval = 900 // 15 minutes
    
    static let signupMaxAttempts = 3
    static let signupTimeWindow: TimeInterval = 3600 // 1 hour
    
    // Content creation limits
    static let postCreationMaxAttempts = 10
    static let postCreationTimeWindow: TimeInterval = 3600 // 1 hour
    
    static let productCreationMaxAttempts = 5
    static let productCreationTimeWindow: TimeInterval = 3600 // 1 hour
    
    static let commentMaxAttempts = 20
    static let commentTimeWindow: TimeInterval = 3600 // 1 hour
    
    // Upload limits
    static let imageUploadMaxAttempts = 20
    static let imageUploadTimeWindow: TimeInterval = 3600 // 1 hour
    
    // Profile update limits
    static let profileUpdateMaxAttempts = 10
    static let profileUpdateTimeWindow: TimeInterval = 3600 // 1 hour
}

// MARK: - Rate Limit Error

enum RateLimitError: LocalizedError {
    case exceeded(retryAfter: TimeInterval)
    
    var errorDescription: String? {
        switch self {
        case .exceeded(let retryAfter):
            if retryAfter < 60 {
                return "Too many attempts. Please try again in \(Int(retryAfter)) seconds"
            } else {
                let minutes = Int(retryAfter / 60)
                return "Too many attempts. Please try again in \(minutes) minute\(minutes == 1 ? "" : "s")"
            }
        }
    }
}
