//
//  ErrorHandlingDemoView.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import SwiftUI

// MARK: - Error Handling Demo View

struct ErrorHandlingDemoView: View {
    @StateObject private var errorHandler = ErrorHandlingMiddleware.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Error Handling System Demo")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("This demo shows how the new error handling system works with different types of errors.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        // Network Error Demo
                        DemoButton(
                            title: "Network Error",
                            subtitle: "Simulate network unavailable",
                            color: .red
                        ) {
                            simulateNetworkError()
                        }
                        
                        // Authentication Error Demo
                        DemoButton(
                            title: "Authentication Error",
                            subtitle: "Simulate auth failure",
                            color: .orange
                        ) {
                            simulateAuthError()
                        }
                        
                        // Validation Error Demo
                        DemoButton(
                            title: "Validation Error",
                            subtitle: "Simulate input validation",
                            color: .blue
                        ) {
                            simulateValidationError()
                        }
                        
                        // Warning Demo
                        DemoButton(
                            title: "Warning",
                            subtitle: "Simulate slow connection",
                            color: .yellow
                        ) {
                            simulateWarning()
                        }
                        
                        // Clear Errors
                        DemoButton(
                            title: "Clear Error History",
                            subtitle: "Reset all errors",
                            color: .green
                        ) {
                            errorHandler.clearErrorHistory()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Error History Section
                    if !errorHandler.errorHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Error History")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(errorHandler.errorHistory.prefix(5)) { entry in
                                ErrorHistoryRow(entry: entry)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 100)
            }
            .navigationTitle("Error Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .errorOverlay() // This applies the error overlay to the entire view
    }
    
    // MARK: - Error Simulation Methods
    
    private func simulateNetworkError() {
        let context = ErrorContext(
            feature: .marketplace,
            userAction: "load_products",
            networkStatus: .disconnected
        )
        
        let error = AgriSenseError.networkUnavailable
        let _ = errorHandler.handle(error, context: context)
    }
    
    private func simulateAuthError() {
        let context = ErrorContext(
            feature: .authentication,
            userAction: "sign_in",
            additionalInfo: ["email": "user@example.com"]
        )
        
        let error = AgriSenseError.authenticationFailed
        let _ = errorHandler.handle(error, context: context)
    }
    
    private func simulateValidationError() {
        let context = ErrorContext(
            feature: .profile,
            userAction: "update_profile"
        )
        
        let error = AgriSenseError.invalidInput("Email address")
        let _ = errorHandler.handle(error, context: context)
    }
    
    private func simulateWarning() {
        let context = ErrorContext(
            feature: .dashboard,
            userAction: "load_weather",
            networkStatus: .slow
        )
        
        let error = AgriSenseError.operationTimeout
        let _ = errorHandler.handle(error, context: context)
    }
}

// MARK: - Demo Button Component

struct DemoButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(color)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Error History Row

struct ErrorHistoryRow: View {
    let entry: ErrorLogEntry
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.agriSenseError.severity.icon)
                .foregroundColor(entry.agriSenseError.severity.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.agriSenseError.errorDescription ?? "Unknown error")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    ErrorHandlingDemoView()
        .environmentObject(LocalizationManager.shared)
}