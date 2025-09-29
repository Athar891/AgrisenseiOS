//
//  LoadingStateManager.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import Foundation
import SwiftUI

// MARK: - Loading State Enum

enum LoadingState<T>: Equatable where T: Equatable {
    case idle
    case loading
    case loaded(T)
    case error(AgriSenseError)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var isLoaded: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }
    
    var hasError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
    
    var data: T? {
        if case .loaded(let data) = self {
            return data
        }
        return nil
    }
    
    var error: AgriSenseError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
    
    // Equatable conformance
    static func == (lhs: LoadingState<T>, rhs: LoadingState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.loaded(let lhsData), .loaded(let rhsData)):
            return lhsData == rhsData
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

// MARK: - Loading State Manager

@MainActor
class LoadingStateManager: ObservableObject {
    static let shared = LoadingStateManager()
    
    @Published private var states: [String: Any] = [:]
    
    private init() {}
    
    func setState<T: Equatable>(_ state: LoadingState<T>, for key: String) {
        states[key] = state
        objectWillChange.send()
    }
    
    func getState<T: Equatable>(for key: String) -> LoadingState<T>? {
        return states[key] as? LoadingState<T>
    }
    
    func setLoading(for key: String) {
        setState(LoadingState<String>.loading, for: key)
    }
    
    func setLoaded<T: Equatable>(_ data: T, for key: String) {
        setState(LoadingState<T>.loaded(data), for: key)
    }
    
    func setError(_ error: AgriSenseError, for key: String) {
        setState(LoadingState<String>.error(error), for: key)
    }
    
    func setIdle(for key: String) {
        setState(LoadingState<String>.idle, for: key)
    }
    
    func isLoading(for key: String) -> Bool {
        if let state = states[key] as? LoadingState<String> {
            return state.isLoading
        }
        return false
    }
    
    func hasError(for key: String) -> Bool {
        if let state = states[key] as? LoadingState<String> {
            return state.hasError
        }
        return false
    }
    
    func clearState(for key: String) {
        states.removeValue(forKey: key)
        objectWillChange.send()
    }
    
    func clearAllStates() {
        states.removeAll()
        objectWillChange.send()
    }
}

// MARK: - Loading State Keys

struct LoadingStateKeys {
    // Authentication
    static let signIn = "auth.sign_in"
    static let signUp = "auth.sign_up"
    static let signOut = "auth.sign_out"
    
    // Profile
    static let profileUpdate = "profile.update"
    static let profileImageUpload = "profile.image_upload"
    static let loadUserData = "profile.load_user_data"
    
    // Dashboard
    static let loadWeather = "dashboard.load_weather"
    static let loadCrops = "dashboard.load_crops"
    static let loadMarketPrices = "dashboard.load_market_prices"
    
    // Marketplace
    static let loadProducts = "marketplace.load_products"
    static let addProduct = "marketplace.add_product"
    static let updateProduct = "marketplace.update_product"
    static let deleteProduct = "marketplace.delete_product"
    
    // Community
    static let loadPosts = "community.load_posts"
    static let createPost = "community.create_post"
    static let loadEvents = "community.load_events"
    static let loadExperts = "community.load_experts"
    
    // Crops
    static let addCrop = "crops.add_crop"
    static let updateCrop = "crops.update_crop"
    static let deleteCrop = "crops.delete_crop"
    
    // Cart
    static let addToCart = "cart.add_to_cart"
    static let updateCart = "cart.update_cart"
    static let checkout = "cart.checkout"
}

// MARK: - Loading Button State

enum LoadingButtonState {
    case idle
    case loading
    case success
    case error
    
    var isLoading: Bool {
        return self == .loading
    }
    
    var isDisabled: Bool {
        return self == .loading
    }
}

// MARK: - Loading State View Modifier

struct LoadingStateViewModifier<T: Equatable>: ViewModifier {
    let loadingState: LoadingState<T>
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(loadingState.isLoading ? 0.3 : 1.0)
                .disabled(loadingState.isLoading)
            
            if loadingState.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
            }
            
            if loadingState.hasError, let error = loadingState.error {
                VStack(spacing: 12) {
                    Image(systemName: error.severity.icon)
                        .font(.title)
                        .foregroundColor(error.severity.color)
                    
                    Text(error.errorDescription ?? "An error occurred")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    if let onRetry = onRetry {
                        Button("Retry") {
                            onRetry()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 4)
            }
        }
    }
}

extension View {
    func loadingState<T: Equatable>(_ state: LoadingState<T>, onRetry: (() -> Void)? = nil) -> some View {
        self.modifier(LoadingStateViewModifier(loadingState: state, onRetry: onRetry))
    }
}