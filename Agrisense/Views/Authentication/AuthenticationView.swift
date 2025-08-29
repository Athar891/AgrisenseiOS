//
//  AuthenticationView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showingOnboarding = false
    @State private var showingRoleSelection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background gradient for dark/light mode
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.15),
                        Color(.systemBackground),
                        Color.green.opacity(0.08),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // App Logo and Title
                    VStack(spacing: 24) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.green)
                            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 12) {
                            Text(localizationManager.localizedString(for: "app_name"))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(localizationManager.localizedString(for: "app_tagline"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 20) {
                        Button(action: {
                            showingRoleSelection = true
                        }) {
                            Text(localizationManager.localizedString(for: "get_started"))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        Button(action: {
                            showingOnboarding = true
                        }) {
                            Text(localizationManager.localizedString(for: "learn_more"))
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                        .frame(height: 60)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
                .environmentObject(userManager)
        }
        .sheet(isPresented: $showingRoleSelection) {
            RoleSelectionView()
                .environmentObject(userManager)
        }
    }
}



#Preview {
    AuthenticationView()
        .environmentObject(UserManager())
}
