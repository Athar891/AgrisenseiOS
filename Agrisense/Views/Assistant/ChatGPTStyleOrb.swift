//
//  ChatGPTStyleOrb.swift
//  Agrisense
//
//  Created by GitHub Copilot on 06/10/25.
//  ChatGPT-style orb animation with state responsiveness
//

import SwiftUI

/// A ChatGPT-style orb animation that responds to AI assistant state changes
struct ChatGPTStyleOrb: View {
    let currentState: LiveAIState
    let audioLevel: CGFloat
    let isListening: Bool
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -1
    
    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(glowGradient)
                .frame(width: 200, height: 200)
                .blur(radius: 30)
                .opacity(glowOpacity)
                .scaleEffect(pulseScale)
            
            // Main orb with gradient
            Circle()
                .fill(orbGradient)
                .frame(width: 120, height: 120)
                .overlay(
                    // Shimmer effect
                    Circle()
                        .fill(shimmerGradient)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .rotationEffect(.degrees(45))
                                .offset(x: shimmerOffset * 300)
                        )
                )
                .scaleEffect(scale)
            
            // Audio visualization rings (when responding)
            if currentState == .responding {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            audioRingColor,
                            lineWidth: 2
                        )
                        .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                        .opacity(audioRingOpacity(for: index))
                        .scaleEffect(audioRingScale(for: index))
                }
            }
            
            // Listening indicator particles
            if isListening {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(particleColor)
                        .frame(width: 6, height: 6)
                        .offset(particleOffset(for: index))
                        .opacity(particleOpacity(for: index))
                }
            }
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            startAnimations()
        }
        .onChange(of: currentState) { _, newState in
            updateAnimationsForState(newState)
        }
        .onChange(of: audioLevel) { _, _ in
            updateAudioVisualization()
        }
    }
    
    // MARK: - Animation Properties
    
    private var orbGradient: LinearGradient {
        let colors: [Color] = {
            switch currentState {
            case .standby:
                return [.blue.opacity(0.6), .cyan.opacity(0.4)]
            case .listening:
                return [.green.opacity(0.7), .mint.opacity(0.5)]
            case .thinking:
                return [.purple.opacity(0.7), .pink.opacity(0.5)]
            case .responding:
                return [.orange.opacity(0.8), .yellow.opacity(0.6)]
            case .paused:
                return [.gray.opacity(0.5), .gray.opacity(0.3)]
            }
        }()
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var glowGradient: RadialGradient {
        let color: Color = {
            switch currentState {
            case .standby:
                return .blue
            case .listening:
                return .green
            case .thinking:
                return .purple
            case .responding:
                return .orange
            case .paused:
                return .gray
            }
        }()
        
        return RadialGradient(
            gradient: Gradient(colors: [color.opacity(0.4), .clear]),
            center: .center,
            startRadius: 50,
            endRadius: 100
        )
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.white.opacity(0.3), .white.opacity(0.1)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var glowOpacity: Double {
        switch currentState {
        case .standby:
            return 0.3
        case .listening:
            return 0.5
        case .thinking:
            return 0.6
        case .responding:
            return 0.7 + Double(audioLevel * 0.3)
        case .paused:
            return 0.2
        }
    }
    
    private var audioRingColor: Color {
        Color.orange.opacity(0.6)
    }
    
    private func audioRingOpacity(for index: Int) -> Double {
        let baseOpacity = 0.6 - (Double(index) * 0.2)
        return baseOpacity * Double(audioLevel)
    }
    
    private func audioRingScale(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.1
        return 1.0 + (audioLevel * 0.3 * CGFloat(1.0 - delay))
    }
    
    private var particleColor: Color {
        Color.green.opacity(0.8)
    }
    
    private func particleOffset(for index: Int) -> CGSize {
        let angle = (Double(index) * 60.0) * .pi / 180.0
        let radius: CGFloat = 80 + (sin(rotation * .pi / 180.0) * 10)
        return CGSize(
            width: CGFloat(cos(angle)) * radius,
            height: CGFloat(sin(angle)) * radius
        )
    }
    
    private func particleOpacity(for index: Int) -> Double {
        let phase = (rotation + Double(index * 60)) / 360.0
        return 0.3 + (sin(phase * .pi * 2) * 0.7)
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Continuous rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
        
        // Shimmer animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            shimmerOffset = 1
        }
        
        // Initial scale animation
        updateAnimationsForState(currentState)
    }
    
    private func updateAnimationsForState(_ state: LiveAIState) {
        let targetScale: CGFloat
        let animationDuration: Double
        
        switch state {
        case .standby:
            targetScale = 1.0
            animationDuration = 1.0
        case .listening:
            targetScale = 1.05
            animationDuration = 0.5
        case .thinking:
            targetScale = 0.95
            animationDuration = 0.8
        case .responding:
            targetScale = 1.0
            animationDuration = 0.3
        case .paused:
            targetScale = 0.9
            animationDuration = 0.5
        }
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            scale = targetScale
        }
    }
    
    private func updateAudioVisualization() {
        // Add subtle bounce based on audio level
        if currentState == .responding && audioLevel > 0.1 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0 + (audioLevel * 0.15)
            }
        }
    }
}

// MARK: - Preview

struct ChatGPTStyleOrb_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            ChatGPTStyleOrb(
                currentState: .standby,
                audioLevel: 0.0,
                isListening: false
            )
            .frame(height: 250)
            
            ChatGPTStyleOrb(
                currentState: .listening,
                audioLevel: 0.0,
                isListening: true
            )
            .frame(height: 250)
            
            ChatGPTStyleOrb(
                currentState: .responding,
                audioLevel: 0.5,
                isListening: false
            )
            .frame(height: 250)
        }
        .padding()
        .background(Color.black)
    }
}
