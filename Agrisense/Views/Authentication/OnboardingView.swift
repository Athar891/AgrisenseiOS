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
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var currentPage = 0
    @State private var showRoleSheet = false
    
    // Build pages dynamically so they pick up localization updates
    private var onboardingPages: [OnboardingPage] {
        [
            OnboardingPage(
                titleKey: "onboarding_page1_title",
                subtitleKey: "onboarding_page1_subtitle",
                descriptionKey: "onboarding_page1_description",
                icon: "leaf.circle.fill",
                color: .green
            ),
            OnboardingPage(
                titleKey: "onboarding_page2_title",
                subtitleKey: "onboarding_page2_subtitle",
                descriptionKey: "onboarding_page2_description",
                icon: "chart.bar.fill",
                color: .blue
            ),
            OnboardingPage(
                titleKey: "onboarding_page3_title",
                subtitleKey: "onboarding_page3_subtitle",
                descriptionKey: "onboarding_page3_description",
                icon: "cart.fill",
                color: .orange
            ),
            OnboardingPage(
                titleKey: "onboarding_page4_title",
                subtitleKey: "onboarding_page4_subtitle",
                descriptionKey: "onboarding_page4_description",
                icon: "person.3.fill",
                color: .purple
            ),
            OnboardingPage(
                titleKey: "onboarding_page5_title",
                subtitleKey: "onboarding_page5_subtitle",
                descriptionKey: "onboarding_page5_description",
                icon: "brain.head.profile",
                color: .indigo
            )
        ]
    }
    
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
                                Button(localizationManager.localizedString(for: "back")) {
                                    withAnimation {
                                        currentPage -= 1
                                    }
                                }
                                .foregroundColor(.green)
                                .font(.headline)
                            }
                            
                            Spacer()
                            
                            Button(currentPage == onboardingPages.count - 1 ? localizationManager.localizedString(for: "get_started") : localizationManager.localizedString(for: "next")) {
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
                    Button(localizationManager.localizedString(for: "skip")) {
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
    // store localization keys instead of raw strings
    let titleKey: String
    let subtitleKey: String
    let descriptionKey: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @EnvironmentObject var localizationManager: LocalizationManager

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
                Text(localizationManager.localizedString(for: page.titleKey))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(localizationManager.localizedString(for: page.subtitleKey))
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(page.color)
                    .multilineTextAlignment(.center)

                Text(localizationManager.localizedString(for: page.descriptionKey))
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
