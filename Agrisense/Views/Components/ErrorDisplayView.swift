//
//  ErrorDisplayView.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import SwiftUI

// MARK: - Error Display View

struct ErrorDisplayView: View {
    let errorResponse: ErrorResponse
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Error Icon
            Image(systemName: errorResponse.severity.icon)
                .font(.system(size: 48))
                .foregroundColor(errorResponse.severity.color)
            
            // Error Message
            VStack(spacing: 8) {
                Text(localizationManager.localizedString(for: "error_occurred"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(errorResponse.userMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if let retryAction = errorResponse.retryAction {
                    Button(action: {
                        retryAction()
                        onDismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(localizationManager.localizedString(for: "retry"))
                        }
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(errorResponse.severity.color)
                        .cornerRadius(12)
                    }
                }
                
                if errorResponse.canDismiss {
                    Button(action: onDismiss) {
                        Text(localizationManager.localizedString(for: "dismiss"))
                            .foregroundColor(errorResponse.severity.color)
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(errorResponse.severity.color.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 32)
    }
}

// MARK: - Error Banner View (for non-blocking errors)

struct ErrorBannerView: View {
    let errorResponse: ErrorResponse
    let onDismiss: () -> Void
    
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: errorResponse.severity.icon)
                    .foregroundColor(errorResponse.severity.color)
                
                Text(errorResponse.userMessage)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Spacer()
                
                if errorResponse.canDismiss {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isVisible = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(errorResponse.severity.color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(errorResponse.severity.color.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Error Overlay Modifier

struct ErrorOverlayModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandlingMiddleware
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if let currentError = errorHandler.currentError {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                if currentError.canDismiss {
                                    errorHandler.dismissCurrentError()
                                }
                            }
                        
                        ErrorDisplayView(
                            errorResponse: currentError,
                            onRetry: currentError.retryAction,
                            onDismiss: {
                                errorHandler.dismissCurrentError()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: errorHandler.currentError != nil)
            )
    }
}

// MARK: - View Extension

extension View {
    func errorOverlay() -> some View {
        self.modifier(ErrorOverlayModifier(errorHandler: ErrorHandlingMiddleware.shared))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ErrorDisplayView(
            errorResponse: ErrorResponse(
                userMessage: "Unable to connect to the server. Please check your internet connection.",
                retryAction: { print("Retry tapped") },
                severity: .error
            ),
            onRetry: { print("Retry") },
            onDismiss: { print("Dismiss") }
        )
        
        ErrorBannerView(
            errorResponse: ErrorResponse(
                userMessage: "Network connection is slow",
                severity: .warning
            ),
            onDismiss: { print("Banner dismissed") }
        )
    }
    .environmentObject(LocalizationManager.shared)
    .padding()
}