//
//  EnhancedTTSService.swift
//  Agrisense
//
//  Created by AI Assistant on 03/10/25.
//  Text-to-Speech service with interruption handling and audio level monitoring

import Foundation
import AVFoundation
import Combine

@MainActor
class EnhancedTTSService: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var currentAudioLevel: CGFloat = 0.0
    @Published var currentText: String = ""
    
    private let synthesizer = AVSpeechSynthesizer()
    private var audioLevelTimer: Timer?
    private var shouldStop = false
    private var currentUtterance: AVSpeechUtterance?
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }
    
    func speak(_ text: String, language: String = "en-US", rate: Float = 0.52) {
        // Stop any ongoing speech
        stopSpeaking()
        
        currentText = text
        shouldStop = false
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        currentUtterance = utterance
        synthesizer.speak(utterance)
        
        isSpeaking = true
        startAudioLevelMonitoring()
    }
    
    func stopSpeaking() {
        shouldStop = true
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        stopAudioLevelMonitoring()
        isSpeaking = false
        currentAudioLevel = 0.0
        currentUtterance = nil
    }
    
    func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            stopAudioLevelMonitoring()
        }
    }
    
    func resumeSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            startAudioLevelMonitoring()
        }
    }
    
    // MARK: - Audio Level Monitoring
    
    private func startAudioLevelMonitoring() {
        stopAudioLevelMonitoring()
        
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.synthesizer.isSpeaking {
                    // Simulate audio level based on speech state
                    // In a real implementation, this would read from the audio output
                    let randomLevel = CGFloat.random(in: 0.3...0.9)
                    self.currentAudioLevel = randomLevel
                } else {
                    self.currentAudioLevel = 0.0
                }
            }
        }
    }
    
    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        currentAudioLevel = 0.0
    }
    
    deinit {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension EnhancedTTSService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if !shouldStop {
                isSpeaking = false
                currentAudioLevel = 0.0
                stopAudioLevelMonitoring()
                currentUtterance = nil
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            currentAudioLevel = 0.0
            stopAudioLevelMonitoring()
            currentUtterance = nil
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            stopAudioLevelMonitoring()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            startAudioLevelMonitoring()
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // Can be used to track which word is currently being spoken
        // Useful for visual feedback
    }
}
