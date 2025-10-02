//
//  SplashScreenView.swift
//  Agrisense
//
//  Created by GitHub Copilot
//

import SwiftUI

struct SplashScreenView: View {
    @State private var animationProgress: CGFloat = 0
    @State private var gradientOffset: CGFloat = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var hueRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.1),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // "Agrisense" title with gradient animation
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            Color.green,
                            Color.blue,
                            Color.green.opacity(0.8),
                            Color.blue.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(
                        Text("Agrisense")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                    )
                    .hueRotation(Angle(degrees: hueRotation))
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // Subtitle
                Text("Your Agricultural Assistant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .opacity(opacity)
            }
        }
        .onAppear {
            // Animate entrance
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Start gradient animation with hue rotation
            withAnimation(
                Animation
                    .linear(duration: 3.0)
                    .repeatForever(autoreverses: false)
            ) {
                hueRotation = 360
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
