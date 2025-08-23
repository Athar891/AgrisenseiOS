//
//  SignupView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var selectedRole: UserType

    init(role: UserType = .farmer) {
        _selectedRole = State(initialValue: role)
    }
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var showingPassword = false
    @State private var showingConfirmPassword = false
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSignIn = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text(LocalizationManager.shared.localizedString(for: "create_account"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(LocalizationManager.shared.localizedString(for: "join_community"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Role Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text(LocalizationManager.shared.localizedString(for: "i_am_a"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            RoleCard(
                                role: .farmer,
                                isSelected: selectedRole == .farmer,
                                action: { selectedRole = .farmer }
                            )
                            
                            RoleCard(
                                role: .seller,
                                isSelected: selectedRole == .seller,
                                action: { selectedRole = .seller }
                            )
                        }
                    }
                    
                    // Signup Form
                    VStack(spacing: 20) {
                        // Full Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationManager.shared.localizedString(for: "full_name"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField(LocalizationManager.shared.localizedString(for: "enter_full_name_placeholder"), text: $fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
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
                        
                        // Phone Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationManager.shared.localizedString(for: "phone_number_label"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField(LocalizationManager.shared.localizedString(for: "enter_phone_placeholder"), text: $phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
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
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizationManager.shared.localizedString(for: "confirm_password"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                if showingConfirmPassword {
                                    TextField(LocalizationManager.shared.localizedString(for: "confirm_password_placeholder"), text: $confirmPassword)
                                } else {
                                    SecureField(LocalizationManager.shared.localizedString(for: "confirm_password_placeholder"), text: $confirmPassword)
                                }
                                
                                Button(action: { showingConfirmPassword.toggle() }) {
                                    Image(systemName: showingConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // Sign Up Button
                    Button(action: signUpWithEmail) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "envelope.fill")
                            }
                            
                            Text(LocalizationManager.shared.localizedString(for: "sign_up_with_email"))
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
                    
                    // Social Sign Up Buttons
                    VStack(spacing: 12) {
                        // Google Sign Up
                        Button(action: signUpWithGoogle) {
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
                        
                        // Apple Sign Up
                        Button(action: signUpWithApple) {
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
                    
                    // Login Link
                    HStack {
                        Text(LocalizationManager.shared.localizedString(for: "already_have_account"))
                            .foregroundColor(.secondary)
                        
                        Button(LocalizationManager.shared.localizedString(for: "sign_in")) {
                            showingSignIn = true
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.localizedString(for: "cancel")) {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .alert("Sign Up", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView()
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        !phoneNumber.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        email.contains("@")
    }
    
    private func signUpWithEmail() {
        isLoading = true
        Task {
            do {
                try await userManager.signUp(email: email, password: password, fullName: fullName, userType: selectedRole)
                // The auth state listener in UserManager will handle the rest.
                dismiss()
            } catch {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
            isLoading = false
        }
    }
    
    private func signUpWithGoogle() {
        isLoading = true
        
        // Simulate Google sign up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            // Create user with Google data
            let user = User(
                id: UUID().uuidString,
                name: "Google User",
                email: "user@gmail.com",
                userType: selectedRole,
                phoneNumber: "+1234567890"
            )
            
            userManager.currentUser = user

            userManager.isAuthenticated = true
            
            dismiss()
        }
    }
    
    private func signUpWithApple() {
        isLoading = true
        
        // Simulate Apple sign up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            // Create user with Apple data
            let user = User(
                id: UUID().uuidString,
                name: "Apple User",
                email: "user@icloud.com",
                userType: selectedRole,
                phoneNumber: "+1234567890"
            )
            
            userManager.currentUser = user

            userManager.isAuthenticated = true
            
            dismiss()
        }
    }
}

struct RoleCard: View {
    let role: UserType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: role == .farmer ? "leaf.fill" : "cart.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .green)
                
                Text(role == .farmer ? "Farmer" : "Seller")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(role == .farmer ? "Grow & Manage" : "Buy & Sell")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SignupView(role: .farmer)
        .environmentObject(UserManager())
}
