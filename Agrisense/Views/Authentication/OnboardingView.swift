//
//  OnboardingView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var currentPage = 0
    @State private var showRoleSheet = false
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to AgriSense",
            subtitle: "Your comprehensive agriculture companion",
            description: "Connect with the farming community, manage your crops, and access the marketplace all in one place.",
            icon: "leaf.circle.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Smart Dashboard",
            subtitle: "Monitor your farm at a glance",
            description: "Track crop health, weather conditions, and market prices with our intelligent dashboard.",
            icon: "chart.bar.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "Marketplace",
            subtitle: "Buy and sell with confidence",
            description: "Connect directly with buyers and sellers. Get fair prices and build lasting relationships.",
            icon: "cart.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Community",
            subtitle: "Learn from fellow farmers",
            description: "Share experiences, ask questions, and stay updated with the latest farming techniques.",
            icon: "person.3.fill",
            color: .purple
        ),
        OnboardingPage(
            title: "AI Assistant",
            subtitle: "Get expert advice anytime",
            description: "Our AI assistant helps you make informed decisions about crops, weather, and market trends.",
            icon: "brain.head.profile",
            color: .indigo
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background that works in both light and dark mode
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Page Content
                    TabView(selection: $currentPage) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            OnboardingPageView(page: onboardingPages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Bottom Controls
                    VStack(spacing: 20) {
                        // Page Indicators
                        HStack(spacing: 8) {
                            ForEach(0..<onboardingPages.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPage ? Color.green : Color(.systemGray3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut, value: currentPage)
                            }
                        }
                        
                        // Navigation Buttons
                        HStack {
                            if currentPage > 0 {
                                Button("Back") {
                                    withAnimation {
                                        currentPage -= 1
                                    }
                                }
                                .foregroundColor(.green)
                                .font(.headline)
                            }
                            
                            Spacer()
                            
                            Button(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next") {
                                if currentPage == onboardingPages.count - 1 {
                                    showRoleSheet = true // Show role selection/sign-in/sign-up
                                } else {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                }
                            }
                            .foregroundColor(.white)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(width: 120, height: 44)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(22)
                            .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showRoleSheet) {
            RoleSelectionView()
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundColor(page.color)
                .padding(.bottom, 20)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(page.color)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
}
