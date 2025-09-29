//
//  LoadingButton.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import SwiftUI

// MARK: - Loading Button

struct LoadingButton: View {
    let title: String
    let state: LoadingButtonState
    let action: () -> Void
    
    // Customization options
    var backgroundColor: Color = .green
    var foregroundColor: Color = .white
    var cornerRadius: CGFloat = 12
    var height: CGFloat = 50
    var font: Font = .headline
    var hapticFeedback: Bool = true
    
    @State private var showSuccess = false
    
    var body: some View {
        Button(action: {
            if !state.isDisabled {
                if hapticFeedback {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                action()
            }
        }) {
            HStack(spacing: 8) {
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else if state == .success && showSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(foregroundColor)
                        .transition(.scale.combined(with: .opacity))
                } else if state == .error {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(foregroundColor)
                }
                
                if !showSuccess || state != .success {
                    Text(buttonTitle)
                        .font(font)
                        .fontWeight(.semibold)
                        .foregroundColor(foregroundColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(buttonBackgroundColor)
            .cornerRadius(cornerRadius)
            .opacity(state.isDisabled ? 0.7 : 1.0)
            .scaleEffect(state.isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: state)
        }
        .disabled(state.isDisabled)
        .onChange(of: state) { _, newState in
            if newState == .success {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showSuccess = true
                }
                
                // Reset success state after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSuccess = false
                    }
                }
            } else {
                showSuccess = false
            }
        }
    }
    
    private var buttonTitle: String {
        switch state {
        case .idle:
            return title
        case .loading:
            return "Loading..."
        case .success:
            return showSuccess ? "Success!" : title
        case .error:
            return "Try Again"
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch state {
        case .idle, .loading:
            return backgroundColor
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

// MARK: - Loading Button Modifiers

extension LoadingButton {
    func backgroundColor(_ color: Color) -> LoadingButton {
        var button = self
        button.backgroundColor = color
        return button
    }
    
    func foregroundColor(_ color: Color) -> LoadingButton {
        var button = self
        button.foregroundColor = color
        return button
    }
    
    func cornerRadius(_ radius: CGFloat) -> LoadingButton {
        var button = self
        button.cornerRadius = radius
        return button
    }
    
    func height(_ height: CGFloat) -> LoadingButton {
        var button = self
        button.height = height
        return button
    }
    
    func font(_ font: Font) -> LoadingButton {
        var button = self
        button.font = font
        return button
    }
    
    func hapticFeedback(_ enabled: Bool) -> LoadingButton {
        var button = self
        button.hapticFeedback = enabled
        return button
    }
}

// MARK: - Compact Loading Button

struct CompactLoadingButton: View {
    let title: String
    let state: LoadingButtonState
    let action: () -> Void
    
    var backgroundColor: Color = .green
    var foregroundColor: Color = .white
    
    var body: some View {
        Button(action: {
            if !state.isDisabled {
                action()
            }
        }) {
            HStack(spacing: 6) {
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.7)
                } else if state == .success {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(foregroundColor)
                } else if state == .error {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(foregroundColor)
                }
                
                Text(compactButtonTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(foregroundColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(compactButtonBackgroundColor)
            .cornerRadius(20)
            .opacity(state.isDisabled ? 0.7 : 1.0)
        }
        .disabled(state.isDisabled)
        .animation(.easeInOut(duration: 0.2), value: state)
    }
    
    private var compactButtonTitle: String {
        switch state {
        case .idle:
            return title
        case .loading:
            return "Loading"
        case .success:
            return "Done"
        case .error:
            return "Retry"
        }
    }
    
    private var compactButtonBackgroundColor: Color {
        switch state {
        case .idle, .loading:
            return backgroundColor
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

// MARK: - Icon Loading Button

struct IconLoadingButton: View {
    let icon: String
    let state: LoadingButtonState
    let action: () -> Void
    
    var backgroundColor: Color = .green
    var foregroundColor: Color = .white
    var size: CGFloat = 44
    
    var body: some View {
        Button(action: {
            if !state.isDisabled {
                action()
            }
        }) {
            ZStack {
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundColor(foregroundColor)
                }
            }
            .frame(width: size, height: size)
            .background(iconButtonBackgroundColor)
            .clipShape(Circle())
            .opacity(state.isDisabled ? 0.7 : 1.0)
            .scaleEffect(state.isLoading ? 0.95 : 1.0)
        }
        .disabled(state.isDisabled)
        .animation(.easeInOut(duration: 0.2), value: state)
    }
    
    private var iconName: String {
        switch state {
        case .idle, .loading:
            return icon
        case .success:
            return "checkmark"
        case .error:
            return "exclamationmark"
        }
    }
    
    private var iconButtonBackgroundColor: Color {
        switch state {
        case .idle, .loading:
            return backgroundColor
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

// MARK: - Loading State Button Wrapper

struct LoadingStateButton<T: Equatable>: View {
    let title: String
    let loadingState: LoadingState<T>
    let action: () -> Void
    let onRetry: (() -> Void)?
    
    var backgroundColor: Color = .green
    
    var body: some View {
        LoadingButton(
            title: title,
            state: buttonState,
            action: {
                if loadingState.hasError && onRetry != nil {
                    onRetry?()
                } else {
                    action()
                }
            }
        )
        .backgroundColor(backgroundColor)
    }
    
    private var buttonState: LoadingButtonState {
        switch loadingState {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .loaded:
            return .success
        case .error:
            return .error
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Loading Button States")
            .font(.title2)
            .fontWeight(.bold)
        
        VStack(spacing: 16) {
            LoadingButton(title: "Sign In", state: .idle) {
                print("Sign In tapped")
            }
            
            LoadingButton(title: "Loading", state: .loading) {
                print("Loading tapped")
            }
            
            LoadingButton(title: "Success", state: .success) {
                print("Success tapped")
            }
            
            LoadingButton(title: "Error", state: .error) {
                print("Error tapped")
            }
        }
        
        Text("Compact Buttons")
            .font(.headline)
        
        HStack(spacing: 12) {
            CompactLoadingButton(title: "Save", state: .idle) {
                print("Save tapped")
            }
            
            CompactLoadingButton(title: "Loading", state: .loading) {
                print("Loading tapped")
            }
            
            CompactLoadingButton(title: "Done", state: .success) {
                print("Done tapped")
            }
        }
        
        Text("Icon Buttons")
            .font(.headline)
        
        HStack(spacing: 12) {
            IconLoadingButton(icon: "plus", state: .idle) {
                print("Add tapped")
            }
            
            IconLoadingButton(icon: "heart", state: .loading) {
                print("Heart tapped")
            }
            
            IconLoadingButton(icon: "star", state: .success) {
                print("Star tapped")
            }
        }
    }
    .padding()
}