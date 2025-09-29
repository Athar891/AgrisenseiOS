//
//  RetryMechanism.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import Foundation
import SwiftUI

// MARK: - Retry Configuration

struct RetryConfiguration {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double
    let jitterRange: ClosedRange<Double>
    
    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 30.0,
        backoffMultiplier: 2.0,
        jitterRange: 0.8...1.2
    )
    
    static let aggressive = RetryConfiguration(
        maxAttempts: 5,
        baseDelay: 0.5,
        maxDelay: 60.0,
        backoffMultiplier: 2.5,
        jitterRange: 0.7...1.3
    )
    
    static let conservative = RetryConfiguration(
        maxAttempts: 2,
        baseDelay: 2.0,
        maxDelay: 15.0,
        backoffMultiplier: 1.5,
        jitterRange: 0.9...1.1
    )
}

// MARK: - Retry Result

enum RetryResult<T> {
    case success(T)
    case failure(Error, attemptCount: Int)
    case cancelled
    
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
    
    var error: Error? {
        if case .failure(let error, _) = self {
            return error
        }
        return nil
    }
}

// MARK: - Retry Manager

@MainActor
class RetryManager: ObservableObject {
    static let shared = RetryManager()
    
    @Published var activeRetries: [String: RetryOperation] = [:]
    private let networkMonitor = NetworkMonitor.shared
    
    private init() {}
    
    // MARK: - Retry with Exponential Backoff
    
    func retry<T>(
        operation: @escaping () async throws -> T,
        configuration: RetryConfiguration = .default,
        operationId: String? = nil,
        shouldRetry: @escaping (Error, Int) -> Bool = { _, _ in true }
    ) async -> RetryResult<T> {
        
        let id = operationId ?? UUID().uuidString
        let retryOp = RetryOperation(id: id, configuration: configuration)
        activeRetries[id] = retryOp
        
        defer {
            activeRetries.removeValue(forKey: id)
        }
        
        var lastError: Error?
        
        for attempt in 1...configuration.maxAttempts {
            // Check if operation was cancelled
            if retryOp.isCancelled {
                return .cancelled
            }
            
            // Update retry operation state
            retryOp.currentAttempt = attempt
            retryOp.lastAttemptTime = Date()
            
            do {
                let result = try await operation()
                retryOp.isCompleted = true
                return .success(result)
            } catch {
                lastError = error
                retryOp.lastError = error
                
                // Don't retry on the last attempt
                if attempt == configuration.maxAttempts {
                    break
                }
                
                // Check if we should retry this error
                if !shouldRetry(error, attempt) {
                    break
                }
                
                // Wait before next attempt with exponential backoff
                let delay = calculateDelay(
                    attempt: attempt,
                    configuration: configuration
                )
                
                retryOp.nextRetryTime = Date().addingTimeInterval(delay)
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        retryOp.isCompleted = true
        return .failure(lastError ?? AgriSenseError.unknown("Retry failed"), attemptCount: configuration.maxAttempts)
    }
    
    // MARK: - Network-Aware Retry
    
    func retryWhenOnline<T>(
        operation: @escaping () async throws -> T,
        configuration: RetryConfiguration = .default,
        operationId: String? = nil
    ) async -> RetryResult<T> {
        
        // If we're offline, wait for connection
        if !networkMonitor.status.isConnected {
            await waitForConnection()
        }
        
        return await retry(
            operation: operation,
            configuration: configuration,
            operationId: operationId,
            shouldRetry: { error, attempt in
                // Always retry network errors
                if let agriSenseError = error as? AgriSenseError {
                    switch agriSenseError {
                    case .networkUnavailable, .operationTimeout:
                        return true
                    case .serverError(let code):
                        // Retry on server errors that might be temporary
                        return code >= 500
                    default:
                        return false
                    }
                }
                
                // Retry URLSession network errors
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                        return true
                    default:
                        return false
                    }
                }
                
                return false
            }
        )
    }
    
    // MARK: - Batch Retry
    
    func retryBatch<T>(
        operations: [(id: String, operation: () async throws -> T)],
        configuration: RetryConfiguration = .default,
        maxConcurrent: Int = 3
    ) async -> [String: RetryResult<T>] {
        
        var results: [String: RetryResult<T>] = [:]
        
        // Process operations in batches
        let batches = operations.chunked(into: maxConcurrent)
        
        for batch in batches {
            await withTaskGroup(of: (String, RetryResult<T>).self) { group in
                for (id, operation) in batch {
                    group.addTask {
                        let result = await self.retry(
                            operation: operation,
                            configuration: configuration,
                            operationId: id
                        )
                        return (id, result)
                    }
                }
                
                for await (id, result) in group {
                    results[id] = result
                }
            }
        }
        
        return results
    }
    
    // MARK: - Cancel Operations
    
    func cancelRetry(operationId: String) {
        activeRetries[operationId]?.isCancelled = true
    }
    
    func cancelAllRetries() {
        for operation in activeRetries.values {
            operation.isCancelled = true
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateDelay(attempt: Int, configuration: RetryConfiguration) -> TimeInterval {
        let exponentialDelay = configuration.baseDelay * pow(configuration.backoffMultiplier, Double(attempt - 1))
        let cappedDelay = min(exponentialDelay, configuration.maxDelay)
        
        // Add jitter to prevent thundering herd
        let jitter = Double.random(in: configuration.jitterRange)
        return cappedDelay * jitter
    }
    
    private func waitForConnection() async {
        while !networkMonitor.status.isConnected {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
    }
}

// MARK: - Retry Operation

class RetryOperation: ObservableObject, Identifiable {
    let id: String
    let configuration: RetryConfiguration
    let startTime: Date
    
    @Published var currentAttempt: Int = 0
    @Published var lastAttemptTime: Date?
    @Published var nextRetryTime: Date?
    @Published var lastError: Error?
    @Published var isCancelled: Bool = false
    @Published var isCompleted: Bool = false
    
    init(id: String, configuration: RetryConfiguration) {
        self.id = id
        self.configuration = configuration
        self.startTime = Date()
    }
    
    var progress: Double {
        return Double(currentAttempt) / Double(configuration.maxAttempts)
    }
    
    var timeElapsed: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    var timeUntilNextRetry: TimeInterval? {
        guard let nextRetryTime = nextRetryTime else { return nil }
        return max(0, nextRetryTime.timeIntervalSinceNow)
    }
}

// MARK: - Retry View Modifier

struct RetryViewModifier<T>: ViewModifier {
    let operation: () async throws -> T
    let configuration: RetryConfiguration
    let onSuccess: (T) -> Void
    let onFailure: (Error) -> Void
    
    @StateObject private var retryManager = RetryManager.shared
    @State private var isRetrying = false
    @State private var retryOperation: RetryOperation?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isRetrying, let operation = retryOperation {
                        RetryProgressOverlay(operation: operation) {
                            // Cancel retry
                            retryManager.cancelRetry(operationId: operation.id)
                            isRetrying = false
                            retryOperation = nil
                        }
                    }
                }
            )
    }
    
    func startRetry() {
        isRetrying = true
        
        Task {
            let result = await retryManager.retry(
                operation: operation,
                configuration: configuration
            )
            
            await MainActor.run {
                isRetrying = false
                retryOperation = nil
                
                switch result {
                case .success(let value):
                    onSuccess(value)
                case .failure(let error, _):
                    onFailure(error)
                case .cancelled:
                    break
                }
            }
        }
    }
}

// MARK: - Retry Progress Overlay

struct RetryProgressOverlay: View {
    @ObservedObject var operation: RetryOperation
    let onCancel: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: operation.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(width: 200)
            
            VStack(spacing: 8) {
                Text("Retrying...")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Attempt \(operation.currentAttempt) of \(operation.configuration.maxAttempts)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let timeUntilNext = operation.timeUntilNextRetry, timeUntilNext > 0 {
                    Text("Next attempt in \(Int(timeUntilNext))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - View Extension

extension View {
    func retryOnFailure<T>(
        operation: @escaping () async throws -> T,
        configuration: RetryConfiguration = .default,
        onSuccess: @escaping (T) -> Void,
        onFailure: @escaping (Error) -> Void
    ) -> some View {
        self.modifier(RetryViewModifier(
            operation: operation,
            configuration: configuration,
            onSuccess: onSuccess,
            onFailure: onFailure
        ))
    }
}