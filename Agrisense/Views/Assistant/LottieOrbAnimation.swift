//
//  LottieOrbAnimation.swift
//  Agrisense
//
//  Created by AI Assistant on 04/10/25.
//  Lottie-based orb animation with state responsiveness
//

import SwiftUI
import Lottie

struct LottieOrbAnimation: View {
    let currentState: LiveAIState
    let audioLevel: CGFloat
    let isListening: Bool
    
    @State private var isLoading = true
    @State private var hasError = false
    
    var body: some View {
        ZStack {
            // Always use fallback animation - no Lottie dependency
            // This avoids the "assetNotFound" error and simplifies the view
            FallbackCircleAnimation(
                currentState: currentState,
                audioLevel: audioLevel
            )
        }
        .onAppear {
            // Mark as loaded immediately since we're using fallback
            isLoading = false
        }
    }
    
    // MARK: - Animation Properties
    
    private var animationSpeed: CGFloat {
        switch currentState {
        case .standby:
            return 0.8
        case .listening:
            return 1.2
        case .thinking:
            return 1.0
        case .responding:
            return 1.0 + (audioLevel * 0.5)
        case .paused:
            return 0.3
        }
    }
    
    private var stateOpacity: Double {
        currentState == .paused ? 0.5 : 1.0
    }
    
    private var dynamicScale: CGFloat {
        let baseScale: CGFloat
        
        switch currentState {
        case .standby:
            baseScale = 0.95
        case .listening:
            baseScale = 1.0
        case .thinking:
            baseScale = 0.98
        case .responding:
            baseScale = 1.0
        case .paused:
            baseScale = 0.9
        }
        
        // Add audio level to scale when responding
        if currentState == .responding && audioLevel > 0.1 {
            return baseScale + (audioLevel * 0.15)
        }
        
        return baseScale
    }
    
    // MARK: - Load Lottie from URL
    
    private func loadLottieFromURL() {
        let urlString = "https://lottie.host/580be90c-0df5-43a7-be84-93c6ba1ccd42/fwjOcVmSCy.lottie"
        
        guard let url = URL(string: urlString) else {
            hasError = true
            isLoading = false
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Try to parse the Lottie animation
                if let animation = try? JSONDecoder().decode(LottieAnimation.self, from: data) {
                    await MainActor.run {
                        // Successfully loaded
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        hasError = true
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    hasError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Fallback Circle Animation

struct FallbackCircleAnimation: View {
    let currentState: LiveAIState
    let audioLevel: CGFloat
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Outer glow/shadow
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 260, height: 260)
                .blur(radius: 20)
                .scaleEffect(pulseScale)
            
            // Main white circle
            Circle()
                .fill(Color.white)
                .frame(width: 180, height: 180)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                .shadow(color: .white.opacity(0.8), radius: 10, x: 0, y: -5)
                .scaleEffect(dynamicScale)
            
            // Inner gradient overlay
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(rotationAngle))
                .scaleEffect(dynamicScale)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var dynamicScale: CGFloat {
        let baseScale: CGFloat
        
        switch currentState {
        case .standby:
            baseScale = 0.95
        case .listening:
            baseScale = 1.0
        case .thinking:
            baseScale = 0.98
        case .responding:
            baseScale = 1.0
        case .paused:
            baseScale = 0.9
        }
        
        if currentState == .responding && audioLevel > 0.1 {
            return baseScale + (audioLevel * 0.15)
        }
        
        return baseScale
    }
    
    private func startAnimations() {
        // Gentle pulse
        withAnimation(
            Animation.easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.1
        }
        
        // Slow rotation
        withAnimation(
            Animation.linear(duration: 20)
                .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
}

// MARK: - Lottie View Wrapper

struct LottieView: UIViewRepresentable {
    let animation: LottieAnimation?
    var loopMode: LottieLoopMode = .loop
    var animationSpeed: CGFloat = 1.0
    var isPlaying: Bool = true
    
    init(animation: LottieAnimation?, loopMode: LottieLoopMode = .loop) {
        self.animation = animation
        self.loopMode = loopMode
    }
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.animation = animation
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        
        if isPlaying {
            animationView.play()
        }
        
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        uiView.animation = animation
        uiView.loopMode = loopMode
        uiView.animationSpeed = animationSpeed
        
        if isPlaying && !uiView.isAnimationPlaying {
            uiView.play()
        } else if !isPlaying && uiView.isAnimationPlaying {
            uiView.pause()
        }
    }
    
    func playing(loopMode: LottieLoopMode = .loop) -> Self {
        var view = self
        view.loopMode = loopMode
        view.isPlaying = true
        return view
    }
    
    func animationSpeed(_ speed: CGFloat) -> Self {
        var view = self
        view.animationSpeed = speed
        return view
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            LottieOrbAnimation(
                currentState: .listening,
                audioLevel: 0.3,
                isListening: true
            )
            
            Text("Lottie Orb Animation")
                .foregroundColor(.white)
                .font(.headline)
        }
    }
}
