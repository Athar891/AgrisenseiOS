//
//  SignInView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI
import GoogleSignIn
import FirebaseAuth

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var email = ""
    @State private var password = ""
    @State private var showingPassword = false
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSignup = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text(LocalizationManager.shared.localizedString(for: "welcome_back"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(LocalizationManager.shared.localizedString(for: "sign_in_to_your_account"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Sign In Form
                    VStack(spacing: 20) {
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationManager.shared.localizedString(for: "email_address_label"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField(LocalizationManager.shared.localizedString(for: "enter_email_placeholder"), text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationManager.shared.localizedString(for: "password_label"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                if showingPassword {
                                    TextField(LocalizationManager.shared.localizedString(for: "enter_password_placeholder"), text: $password)
                                } else {
                                    SecureField(LocalizationManager.shared.localizedString(for: "enter_password_placeholder"), text: $password)
                                }
                                
                                Button(action: { showingPassword.toggle() }) {
                                    Image(systemName: showingPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            
                            Button(LocalizationManager.shared.localizedString(for: "forgot_password")) {
                                // Handle forgot password
                                alertMessage = "Password reset link sent to your email"
                                showingAlert = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.green)
                        }
                    }
                    
                    // Sign In Button
                    Button(action: { Task { await signInWithEmail() } }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "envelope.fill")
                            }
                            
                            Text(LocalizationManager.shared.localizedString(for: "sign_in_with_email"))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(25)
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        
                        Text(LocalizationManager.shared.localizedString(for: "or"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    
                    // Social Sign In Buttons
                    VStack(spacing: 12) {
                        // Google Sign In
                        Button(action: signInWithGoogle) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.white)
                                
                                Text(LocalizationManager.shared.localizedString(for: "continue_with_google"))
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(25)
                        }
                        .disabled(isLoading)
                        
                        // Apple Sign In
                        Button(action: signInWithApple) {
                            HStack {
                                Image(systemName: "applelogo")
                                    .foregroundColor(.white)
                                
                                Text(LocalizationManager.shared.localizedString(for: "continue_with_apple"))
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .cornerRadius(25)
                        }
                        .disabled(isLoading)
                    }
                    
                    // Sign Up Link
                    HStack {
                        Text(LocalizationManager.shared.localizedString(for: "dont_have_account"))
                            .foregroundColor(.secondary)
                        
                        Button(LocalizationManager.shared.localizedString(for: "sign_up")) {
                            showingSignup = true
                        }
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(LocalizationManager.shared.localizedString(for: "cancel")) {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .alert("Sign In", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingSignup) {
            SignupView()
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private func signInWithEmail() async {
        isLoading = true
        do {
            try await userManager.signIn(email: email, password: password)
            // On success, the auth state listener will dismiss the view.
        } catch {
            alertMessage = error.localizedDescription
            showingAlert = true
            isLoading = false
        }
    }
    
    private func signInWithGoogle() {
        print("🔵 Google Sign-In button tapped")
        
        // Check if Google Sign-In is configured
        guard GIDSignIn.sharedInstance.configuration != nil else {
            print("❌ Google Sign-In not configured")
            alertMessage = "Google Sign-In is not properly configured. Please contact support."
            showingAlert = true
            return
        }
        
        // Validate bundle ID matches GoogleService-Info.plist
        let currentBundleId = Bundle.main.bundleIdentifier ?? ""
        print("🔍 Current Bundle ID: \(currentBundleId)")
        
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let configuredBundleId = plist["BUNDLE_ID"] as? String {
            print("🔍 Configured Bundle ID: \(configuredBundleId)")
            if currentBundleId != configuredBundleId {
                print("⚠️ Bundle ID mismatch - this may cause sign-in issues")
            }
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            print("❌ Failed to get active window scene")
            alertMessage = "Failed to initialize sign in. Please try again."
            showingAlert = true
            return
        }
        
        guard let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("❌ Failed to get root view controller")
            alertMessage = "Cannot find root view controller"
            showingAlert = true
            return
        }
        
        // Get the topmost view controller
        let presentingViewController = getTopViewController(from: rootViewController)
        print("🎯 Using presenting view controller: \(type(of: presentingViewController))")
        
        print("🔄 Starting Google Sign-In flow...")
        isLoading = true
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                print("🔵 Google Sign-In completion handler called")
                
                if let error = error {
                    print("❌ Google Sign-In error: \(error.localizedDescription)")
                    print("❌ Error code: \((error as NSError).code)")
                    print("❌ Error domain: \((error as NSError).domain)")
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        // Check if this is actually a user cancellation or a technical issue
                        let nsError = error as NSError
                        if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                            // This is likely a technical issue, not user cancellation
                            self.alertMessage = "Sign-in was interrupted. This might be due to a configuration issue. Please try again or contact support if the problem persists."
                        } else if error.localizedDescription.contains("canceled") {
                            // Actual user cancellation
                            self.alertMessage = "Sign-in was canceled. Please try again when ready."
                        } else {
                            // Other errors
                            self.alertMessage = "Google Sign-In failed: \(error.localizedDescription)"
                        }
                        
                        self.showingAlert = true
                    }
                    return
                }
                
                guard let user = result?.user else {
                    print("❌ No user returned from Google Sign-In")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertMessage = "Failed to get user info from Google"
                        self.showingAlert = true
                    }
                    return
                }
                
                guard let idToken = user.idToken?.tokenString else {
                    print("❌ No ID token from Google")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertMessage = "Failed to get authentication token from Google"
                        self.showingAlert = true
                    }
                    return
                }
                
                print("✅ Google Sign-In successful, creating Firebase credential...")
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )
                
                // Sign in with Firebase
                self.signInWithFirebase(credential: credential, user: user)
            }
    }
    
    private func signInWithFirebase(credential: AuthCredential, user: GIDGoogleUser) {
        print("🔄 Starting Firebase authentication...")
        
        Task {
            do {
                print("🔑 Attempting to sign in with Firebase...")
                let result = try await Auth.auth().signIn(with: credential)
                print("✅ Firebase authentication successful")
                
                let fullName = user.profile?.name ?? ""
                let email = user.profile?.email ?? ""
                
                print("👤 User Info - Name: \(fullName), Email: \(email)")
                
                // Update the user's display name if it doesn't exist
                if let currentUser = Auth.auth().currentUser {
                    print("🔍 Current user UID: \(currentUser.uid)")
                    
                    if currentUser.displayName == nil || currentUser.displayName?.isEmpty == true {
                        print("🔄 Updating user display name to: \(fullName)")
                        let changeRequest = currentUser.createProfileChangeRequest()
                        changeRequest.displayName = fullName
                        try await changeRequest.commitChanges()
                        print("✅ Successfully updated user display name")
                    }
                    
                    // Update user manager on main thread
                    await MainActor.run {
                        print("🔄 Updating UserManager with user data...")
                        self.userManager.currentUser = User(
                            id: result.user.uid,
                            name: fullName,
                            email: email,
                            userType: .farmer, // Default to farmer, can be updated later
                            phoneNumber: ""
                        )
                        self.userManager.isAuthenticated = true
                        self.isLoading = false
                        print("✅ UserManager updated successfully")
                    }
                } else {
                    print("❌ No current user after authentication")
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user after authentication"])
                }
                
            } catch {
                print("❌ Firebase authentication error: \(error.localizedDescription)")
                await MainActor.run {
                    self.alertMessage = "Authentication failed: \(error.localizedDescription)"
                    self.showingAlert = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func signInWithApple() {
        alertMessage = "Apple Sign-In is not implemented yet."
        showingAlert = true
    }
    
    // Helper method to get the topmost view controller
    private func getTopViewController(from rootViewController: UIViewController) -> UIViewController {
        var topViewController = rootViewController
        
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        if let navigationController = topViewController as? UINavigationController {
            return navigationController.visibleViewController ?? navigationController
        }
        
        if let tabBarController = topViewController as? UITabBarController {
            return tabBarController.selectedViewController ?? tabBarController
        }
        
        return topViewController
    }
}

#Preview {
    SignInView()
        .environmentObject(UserManager())
}

// MARK: - Google Sign-In
// Implementation is in the main SignInView struct

