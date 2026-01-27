//
//  KeyboardManager.swift
//  Agrisense
//
//  Created by GitHub Copilot
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Keyboard Management Utilities

/// Utility for managing keyboard behavior and avoiding snapshotting warnings
enum KeyboardManager {
    
    /// Dismisses the keyboard safely without causing snapshot warnings
    /// Call this before any UI operations that might trigger snapshots
    static func dismissKeyboard() {
        #if canImport(UIKit)
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                          to: nil, 
                                          from: nil, 
                                          for: nil)
        }
        #endif
    }
    
    /// Dismisses keyboard and waits for completion before executing action
    /// Use this to avoid snapshotting warnings when keyboard is being dismissed
    static func dismissKeyboardAndWait(completion: @escaping () -> Void) {
        #if canImport(UIKit)
        dismissKeyboard()
        // Wait a short time for keyboard animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion()
        }
        #else
        completion()
        #endif
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Adds a tap gesture to dismiss the keyboard
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            KeyboardManager.dismissKeyboard()
        }
    }
    
    /// Toolbar with keyboard dismiss button
    func keyboardDismissToolbar() -> some View {
        #if os(iOS)
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    KeyboardManager.dismissKeyboard()
                }
            }
        }
        #else
        self
        #endif
    }
}
