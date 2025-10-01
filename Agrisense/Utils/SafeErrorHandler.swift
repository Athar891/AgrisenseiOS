//
//  SafeErrorHandler.swift
//  Agrisense
//
//  Created by Security Audit on 01/10/25.
//

import Foundation
import SwiftUI

// MARK: - Safe Error Handler

/// Comprehensive error handling with sanitization and logging
class SafeErrorHandler {
    static let shared = SafeErrorHandler()
    
    private init() {}
    
    // MARK: - Error Categories
    
    enum ErrorCategory {
        case network
        case authentication
        case validation
        case storage
        case rateLimiting
        case imageProcessing
        case general
        
        var userFacingPrefix: String {
            switch self {
            case .network:
                return "Network Error"
            case .authentication:
                return "Authentication Error"
            case .validation:
                return "Validation Error"
            case .storage:
                return "Storage Error"
            case .rateLimiting:
                return "Rate Limit"
            case .imageProcessing:
                return "Image Error"
            case .general:
                return "Error"
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// Handle error with sanitization and appropriate user message
    func handle(
        _ error: Error,
        category: ErrorCategory = .general,
        context: String? = nil
    ) -> String {
        // Log full error in debug mode
        #if DEBUG
        if let context = context {
            print("[\(category.userFacingPrefix)] Context: \(context)")
        }
        print("[\(category.userFacingPrefix)] Error: \(error)")
        print("[\(category.userFacingPrefix)] Error Details: \(error.localizedDescription)")
        if let nsError = error as NSError? {
            print("[\(category.userFacingPrefix)] Domain: \(nsError.domain)")
            print("[\(category.userFacingPrefix)] Code: \(nsError.code)")
            print("[\(category.userFacingPrefix)] UserInfo: \(nsError.userInfo)")
        }
        #endif
        
        // Return sanitized user-facing message
        return sanitizeError(error, category: category)
    }
    
    // MARK: - Error Sanitization
    
    private func sanitizeError(_ error: Error, category: ErrorCategory) -> String {
        let nsError = error as NSError
        
        // Handle specific error domains
        switch nsError.domain {
        case NSURLErrorDomain:
            return handleNetworkError(nsError)
            
        case "RateLimit":
            return handleRateLimitError(nsError)
            
        case "Validation":
            return handleValidationError(nsError)
            
        case "ImageValidation":
            return handleImageValidationError(nsError)
            
        case "CloudinaryError":
            return "Failed to upload image. Please try again."
            
        case "ImageProcessingError":
            return "Failed to process image. Please try again."
            
        case SecureStorageError.saveFailed.localizedDescription:
            return "Failed to save data securely."
            
        case SecureStorageError.loadFailed.localizedDescription:
            return "Failed to load data."
            
        default:
            return handleGeneralError(nsError, category: category)
        }
    }
    
    // MARK: - Specific Error Handlers
    
    private func handleNetworkError(_ error: NSError) -> String {
        switch error.code {
        case NSURLErrorNotConnectedToInternet:
            return "No internet connection. Please check your network and try again."
            
        case NSURLErrorTimedOut:
            return "Request timed out. Please try again."
            
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return "Cannot connect to server. Please try again later."
            
        case NSURLErrorNetworkConnectionLost:
            return "Network connection lost. Please try again."
            
        case NSURLErrorBadServerResponse:
            return "Server error. Please try again later."
            
        case NSURLErrorUserCancelledAuthentication:
            return "Authentication cancelled."
            
        case NSURLErrorServerCertificateUntrusted:
            return "Connection security error. Please check your network."
            
        default:
            return "Network error occurred. Please try again."
        }
    }
    
    private func handleRateLimitError(_ error: NSError) -> String {
        // Rate limit errors already have user-friendly messages
        return error.localizedDescription
    }
    
    private func handleValidationError(_ error: NSError) -> String {
        // Validation errors already have user-friendly messages
        return error.localizedDescription
    }
    
    private func handleImageValidationError(_ error: NSError) -> String {
        // Image validation errors already have user-friendly messages
        return error.localizedDescription
    }
    
    private func handleGeneralError(_ error: NSError, category: ErrorCategory) -> String {
        // Check if error already has a user-friendly message
        let description = error.localizedDescription
        
        // If it looks like a technical error, return generic message
        if description.contains("Error Domain") ||
           description.contains("Code=") ||
           description.contains("nil") ||
           description.contains("NSError") {
            return "An error occurred. Please try again."
        }
        
        // Otherwise, return the error description (it's already user-friendly)
        return description
    }
    
    // MARK: - Alert Helper
    
    /// Create an alert for displaying errors to users
    func createErrorAlert(
        _ error: Error,
        category: ErrorCategory = .general,
        context: String? = nil,
        retryAction: (() -> Void)? = nil
    ) -> Alert {
        let message = handle(error, category: category, context: context)
        
        if let retryAction = retryAction {
            return Alert(
                title: Text(category.userFacingPrefix),
                message: Text(message),
                primaryButton: .default(Text("Retry"), action: retryAction),
                secondaryButton: .cancel()
            )
        } else {
            return Alert(
                title: Text(category.userFacingPrefix),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Logging
    
    /// Log error to external service (e.g., Firebase Crashlytics)
    /// TODO: Implement actual crash reporting integration
    func logError(
        _ error: Error,
        category: ErrorCategory,
        context: String?,
        additionalInfo: [String: Any] = [:]
    ) {
        #if DEBUG
        print("[SafeErrorHandler] Logging error to crash reporting service...")
        print("[SafeErrorHandler] Category: \(category)")
        if let context = context {
            print("[SafeErrorHandler] Context: \(context)")
        }
        print("[SafeErrorHandler] Additional Info: \(additionalInfo)")
        #endif
        
        // TODO: Integrate with Firebase Crashlytics or similar service
        // Example:
        // Crashlytics.crashlytics().record(error: error)
        // Crashlytics.crashlytics().setCustomValue(category.rawValue, forKey: "error_category")
    }
}

// MARK: - Error Handling Extensions

extension Error {
    /// Get sanitized user-facing error message
    var userFacingMessage: String {
        SafeErrorHandler.shared.handle(self)
    }
    
    /// Get sanitized error message with category
    func userFacingMessage(category: SafeErrorHandler.ErrorCategory) -> String {
        SafeErrorHandler.shared.handle(self, category: category)
    }
}

// MARK: - View Modifier for Error Handling

struct ErrorHandling: ViewModifier {
    @Binding var error: Error?
    let category: SafeErrorHandler.ErrorCategory
    let context: String?
    let retryAction: (() -> Void)?
    
    init(
        error: Binding<Error?>,
        category: SafeErrorHandler.ErrorCategory = .general,
        context: String? = nil,
        retryAction: (() -> Void)? = nil
    ) {
        self._error = error
        self.category = category
        self.context = context
        self.retryAction = retryAction
    }
    
    func body(content: Content) -> some View {
        content
            .alert(item: Binding(
                get: { error.map { ErrorWrapper(error: $0) } },
                set: { _ in error = nil }
            )) { errorWrapper in
                SafeErrorHandler.shared.createErrorAlert(
                    errorWrapper.error,
                    category: category,
                    context: context,
                    retryAction: retryAction
                )
            }
    }
}

// Helper for making Error identifiable
private struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: Error
}

extension View {
    /// Apply error handling to a view
    func handleError(
        _ error: Binding<Error?>,
        category: SafeErrorHandler.ErrorCategory = .general,
        context: String? = nil,
        retryAction: (() -> Void)? = nil
    ) -> some View {
        self.modifier(ErrorHandling(
            error: error,
            category: category,
            context: context,
            retryAction: retryAction
        ))
    }
}

// MARK: - Usage Examples (Comment out in production)

/*
 
 HOW TO USE SAFE ERROR HANDLER:
 
 1. In ViewModels or Managers:
    ```swift
    do {
        try await someOperation()
    } catch {
        let message = SafeErrorHandler.shared.handle(
            error,
            category: .network,
            context: "Fetching user data"
        )
        self.errorMessage = message
    }
    ```
 
 2. In SwiftUI Views:
    ```swift
    struct MyView: View {
        @State private var error: Error?
        
        var body: some View {
            VStack {
                // Your content
            }
            .handleError($error, category: .network) {
                // Optional retry action
                fetchData()
            }
        }
    }
    ```
 
 3. Simple error message:
    ```swift
    let message = error.userFacingMessage
    ```
 
 4. Error message with category:
    ```swift
    let message = error.userFacingMessage(category: .authentication)
    ```
 
 */
