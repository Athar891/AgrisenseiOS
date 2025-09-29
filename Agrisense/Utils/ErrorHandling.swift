//
//  ErrorHandling.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import Foundation
import SwiftUI

// MARK: - AgriSenseError Enum

enum AgriSenseError: LocalizedError, Equatable {
    case networkUnavailable
    case authenticationFailed
    case dataCorrupted
    case insufficientPermissions
    case serverError(Int)
    case validationError(String)
    case syncConflict(String)
    case imageProcessingError
    case locationPermissionDenied
    case cameraPermissionDenied
    case storageError
    case invalidInput(String)
    case operationTimeout
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return LocalizationManager.shared.localizedString(for: "error_network_unavailable")
        case .authenticationFailed:
            return LocalizationManager.shared.localizedString(for: "error_auth_failed")
        case .dataCorrupted:
            return LocalizationManager.shared.localizedString(for: "error_data_corrupted")
        case .insufficientPermissions:
            return LocalizationManager.shared.localizedString(for: "error_insufficient_permissions")
        case .serverError(let code):
            return String(format: LocalizationManager.shared.localizedString(for: "error_server_error"), code)
        case .validationError(let message):
            return message
        case .syncConflict(let details):
            return String(format: LocalizationManager.shared.localizedString(for: "error_sync_conflict"), details)
        case .imageProcessingError:
            return LocalizationManager.shared.localizedString(for: "error_image_processing")
        case .locationPermissionDenied:
            return LocalizationManager.shared.localizedString(for: "error_location_permission")
        case .cameraPermissionDenied:
            return LocalizationManager.shared.localizedString(for: "error_camera_permission")
        case .storageError:
            return LocalizationManager.shared.localizedString(for: "error_storage")
        case .invalidInput(let field):
            return String(format: LocalizationManager.shared.localizedString(for: "error_invalid_input"), field)
        case .operationTimeout:
            return LocalizationManager.shared.localizedString(for: "error_operation_timeout")
        case .unknown(let message):
            return String(format: LocalizationManager.shared.localizedString(for: "error_unknown"), message)
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return LocalizationManager.shared.localizedString(for: "error_check_connection")
        case .authenticationFailed:
            return LocalizationManager.shared.localizedString(for: "error_try_sign_in_again")
        case .dataCorrupted:
            return LocalizationManager.shared.localizedString(for: "error_restart_app")
        case .insufficientPermissions:
            return LocalizationManager.shared.localizedString(for: "error_contact_support")
        case .serverError:
            return LocalizationManager.shared.localizedString(for: "error_try_again_later")
        case .validationError:
            return LocalizationManager.shared.localizedString(for: "error_check_input")
        case .syncConflict:
            return LocalizationManager.shared.localizedString(for: "error_resolve_conflict")
        case .imageProcessingError:
            return LocalizationManager.shared.localizedString(for: "error_try_different_image")
        case .locationPermissionDenied:
            return LocalizationManager.shared.localizedString(for: "error_enable_location_settings")
        case .cameraPermissionDenied:
            return LocalizationManager.shared.localizedString(for: "error_enable_camera_settings")
        case .storageError:
            return LocalizationManager.shared.localizedString(for: "error_free_up_space")
        case .invalidInput:
            return LocalizationManager.shared.localizedString(for: "error_check_input")
        case .operationTimeout:
            return LocalizationManager.shared.localizedString(for: "error_try_again")
        case .unknown:
            return LocalizationManager.shared.localizedString(for: "error_try_again")
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkUnavailable, .operationTimeout:
            return .warning
        case .authenticationFailed, .insufficientPermissions, .serverError:
            return .error
        case .dataCorrupted, .syncConflict:
            return .critical
        case .validationError, .invalidInput, .imageProcessingError:
            return .info
        case .locationPermissionDenied, .cameraPermissionDenied:
            return .warning
        case .storageError:
            return .error
        case .unknown:
            return .error
        }
    }
    
    // Equatable conformance
    static func == (lhs: AgriSenseError, rhs: AgriSenseError) -> Bool {
        switch (lhs, rhs) {
        case (.networkUnavailable, .networkUnavailable),
             (.authenticationFailed, .authenticationFailed),
             (.dataCorrupted, .dataCorrupted),
             (.insufficientPermissions, .insufficientPermissions),
             (.imageProcessingError, .imageProcessingError),
             (.locationPermissionDenied, .locationPermissionDenied),
             (.cameraPermissionDenied, .cameraPermissionDenied),
             (.storageError, .storageError),
             (.operationTimeout, .operationTimeout):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.validationError(let lhsMessage), .validationError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.syncConflict(let lhsDetails), .syncConflict(let rhsDetails)):
            return lhsDetails == rhsDetails
        case (.invalidInput(let lhsField), .invalidInput(let rhsField)):
            return lhsField == rhsField
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Supporting Types

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
    
    var color: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }
}

struct ErrorContext {
    let feature: AppFeature
    let userAction: String
    let networkStatus: ErrorNetworkStatus
    let additionalInfo: [String: Any]
    
    init(feature: AppFeature, userAction: String, networkStatus: ErrorNetworkStatus = .unknown, additionalInfo: [String: Any] = [:]) {
        self.feature = feature
        self.userAction = userAction
        self.networkStatus = networkStatus
        self.additionalInfo = additionalInfo
    }
}

enum AppFeature: String, CaseIterable {
    case authentication = "authentication"
    case dashboard = "dashboard"
    case marketplace = "marketplace"
    case community = "community"
    case assistant = "assistant"
    case profile = "profile"
    case crops = "crops"
    case weather = "weather"
    case notifications = "notifications"
    case sync = "sync"
}

enum ErrorNetworkStatus {
    case connected
    case disconnected
    case slow
    case unknown
}

struct ErrorResponse {
    let userMessage: String
    let retryAction: (() -> Void)?
    let severity: ErrorSeverity
    let canDismiss: Bool
    let showInUI: Bool
    
    init(userMessage: String, retryAction: (() -> Void)? = nil, severity: ErrorSeverity, canDismiss: Bool = true, showInUI: Bool = true) {
        self.userMessage = userMessage
        self.retryAction = retryAction
        self.severity = severity
        self.canDismiss = canDismiss
        self.showInUI = showInUI
    }
}

// MARK: - Error Manager Protocol

protocol ErrorManager {
    func handle(_ error: Error, context: ErrorContext) -> ErrorResponse
    func logError(_ error: Error, additionalInfo: [String: Any])
    func showUserFriendlyMessage(for error: Error) -> String
}

// MARK: - Error Handling Middleware

@MainActor
class ErrorHandlingMiddleware: ObservableObject, ErrorManager {
    static let shared = ErrorHandlingMiddleware()
    
    @Published var currentError: ErrorResponse?
    @Published var errorHistory: [ErrorLogEntry] = []
    
    private let maxErrorHistory = 50
    
    private init() {}
    
    nonisolated func handle(_ error: Error, context: ErrorContext) -> ErrorResponse {
        // Convert to AgriSenseError if needed
        let agriSenseError = convertToAgriSenseError(error)
        
        // Log error for debugging
        logError(agriSenseError, additionalInfo: context.additionalInfo)
        
        // Create user-facing response
        let userMessage = getUserFriendlyMessage(for: agriSenseError, context: context)
        let retryAction = getRetryAction(for: agriSenseError, context: context)
        
        let response = ErrorResponse(
            userMessage: userMessage,
            retryAction: retryAction,
            severity: agriSenseError.severity,
            canDismiss: agriSenseError.severity != .critical,
            showInUI: shouldShowInUI(agriSenseError, context: context)
        )
        
        // Update current error for UI display on main actor
        if response.showInUI {
            Task { @MainActor in
                currentError = response
            }
        }
        
        return response
    }
    
    nonisolated func logError(_ error: Error, additionalInfo: [String: Any] = [:]) {
        let entry = ErrorLogEntry(
            error: error,
            timestamp: Date(),
            additionalInfo: additionalInfo
        )
        
        // Update error history on main actor
        Task { @MainActor in
            errorHistory.insert(entry, at: 0)
            
            // Keep only recent errors
            if errorHistory.count > maxErrorHistory {
                errorHistory = Array(errorHistory.prefix(maxErrorHistory))
            }
        }
        
        // Log to console in debug mode
        #if DEBUG
        print("🚨 AgriSense Error: \(error.localizedDescription)")
        if !additionalInfo.isEmpty {
            print("📋 Additional Info: \(additionalInfo)")
        }
        #endif
        
        // TODO: Send to analytics service when implemented
        // AnalyticsService.shared.logError(error, context: additionalInfo)
    }
    
    nonisolated func showUserFriendlyMessage(for error: Error) -> String {
        let agriSenseError = convertToAgriSenseError(error)
        return agriSenseError.errorDescription ?? "An unexpected error occurred"
    }
    
    func dismissCurrentError() {
        currentError = nil
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    // MARK: - Private Methods
    
    nonisolated private func convertToAgriSenseError(_ error: Error) -> AgriSenseError {
        if let agriSenseError = error as? AgriSenseError {
            return agriSenseError
        }
        
        // Convert common system errors to AgriSenseError
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSURLErrorDomain:
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkUnavailable
            case NSURLErrorTimedOut:
                return .operationTimeout
            default:
                return .unknown(nsError.localizedDescription)
            }
        case "FIRAuthErrorDomain":
            return .authenticationFailed
        case "FIRFirestoreErrorDomain":
            if nsError.code == 7 { // Permission denied
                return .insufficientPermissions
            }
            return .serverError(nsError.code)
        default:
            return .unknown(nsError.localizedDescription)
        }
    }
    
    nonisolated private func getUserFriendlyMessage(for error: AgriSenseError, context: ErrorContext) -> String {
        var message = error.errorDescription ?? "An error occurred"
        
        // Add context-specific information
        switch context.feature {
        case .authentication:
            if case .networkUnavailable = error {
                message = "Unable to sign in. Please check your internet connection."
            }
        case .marketplace:
            if case .networkUnavailable = error {
                message = "Unable to load products. Please check your internet connection."
            }
        case .crops:
            if case .networkUnavailable = error {
                message = "Unable to sync crop data. Changes will be saved locally."
            }
        default:
            break
        }
        
        return message
    }
    
    nonisolated private func getRetryAction(for error: AgriSenseError, context: ErrorContext) -> (() -> Void)? {
        switch error {
        case .networkUnavailable, .operationTimeout, .serverError:
            return {
                // Retry action would be provided by the calling context
                // This is a placeholder that could trigger a retry mechanism
                print("Retrying operation for \(context.feature.rawValue)")
            }
        default:
            return nil
        }
    }
    
    nonisolated private func shouldShowInUI(_ error: AgriSenseError, context: ErrorContext) -> Bool {
        switch error.severity {
        case .critical, .error:
            return true
        case .warning:
            return context.networkStatus == .disconnected
        case .info:
            return false
        }
    }
}

// MARK: - Error Log Entry

struct ErrorLogEntry: Identifiable {
    let id = UUID()
    let error: Error
    let timestamp: Date
    let additionalInfo: [String: Any]
    
    var agriSenseError: AgriSenseError {
        if let agriSenseError = error as? AgriSenseError {
            return agriSenseError
        }
        return .unknown(error.localizedDescription)
    }
}

// MARK: - Error Extension for Common Conversions

extension Error {
    var asAgriSenseError: AgriSenseError {
        if let agriSenseError = self as? AgriSenseError {
            return agriSenseError
        }
        return .unknown(self.localizedDescription)
    }
}