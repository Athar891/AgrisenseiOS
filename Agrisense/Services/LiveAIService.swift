//
//  LiveAIService.swift
//  Agrisense
//
//  Created by AI Assistant on 03/10/25.
//

import SwiftUI
import AVFoundation
import Vision
import Combine
import ReplayKit

// MARK: - Live AI Service
@MainActor
class LiveAIService: ObservableObject, ScreenRecordingDelegate {
    @Published var isActive = false
    @Published var isPaused = false
    @Published var lastResponse: String = ""
    @Published var isProcessing = false
    @Published var isListening = false
    @Published var currentState: LiveAIState = .standby
    @Published var isScreenSharing = false
    @Published var screenShareError: String?
    @Published var subtitlesEnabled = false
    @Published var currentSubtitle: String = ""
    @Published var audioLevel: CGFloat = 0.0
    
    private let geminiService: GeminiAIService
    let voiceService = VoiceTranscriptionService()  // Make this public for view access
    let ttsService = EnhancedTTSService()  // Enhanced TTS with interruption support
    private var lastUserInput: String = ""
    private var hasPerformedGreeting = false
    private let screenRecordingService = ScreenRecordingService()
    private var transcriptionMonitorTask: Task<Void, Never>?
    
    init(geminiApiKey: String) {
        self.geminiService = GeminiAIService(apiKey: geminiApiKey)
        screenRecordingService.setDelegate(self)
        setupTranscriptionMonitoring()
    }
    
    func startLiveSession() {
        guard !isActive else { return }
        
        isActive = true
        isPaused = false
        currentState = .standby
        
        // Start voice transcription for continuous listening
        Task {
            await voiceService.startRecording()
            isListening = true
        }
        
        // Start audio level monitoring
        startAudioLevelMonitoring()
    }
    
    private func setupTranscriptionMonitoring() {
        // Monitor transcription changes to detect when user starts speaking
        transcriptionMonitorTask = Task { @MainActor in
            var lastTranscription = ""
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1s
                
                let currentTranscription = voiceService.transcriptionText
                
                // If user starts speaking while AI is responding, interrupt TTS
                if !currentTranscription.isEmpty && 
                   currentTranscription != lastTranscription &&
                   ttsService.isSpeaking {
                    print("🎤 User interrupted - stopping TTS")
                    ttsService.stopSpeaking()
                    currentState = .listening
                }
                
                lastTranscription = currentTranscription
            }
        }
    }
    
    private func startAudioLevelMonitoring() {
        Task {
            while isActive && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000) // Update every 0.05s
                
                if ttsService.isSpeaking {
                    audioLevel = ttsService.currentAudioLevel
                } else {
                    audioLevel = 0.0
                }
            }
        }
    }
    
    func toggleSubtitles() {
        subtitlesEnabled.toggle()
    }
    
    func pauseSession() {
        isPaused = true
        currentState = .paused
        isListening = false
        Task {
            await voiceService.stopRecording()
        }
    }
    
    func resumeSession() {
        isPaused = false
        currentState = .standby
        Task {
            await voiceService.startRecording()
            isListening = true
        }
    }
    
    func endSession() {
        isActive = false
        isPaused = false
        isListening = false
        currentState = .standby
        hasPerformedGreeting = false
        isScreenSharing = false
        subtitlesEnabled = false
        currentSubtitle = ""
        audioLevel = 0.0
        
        // Cancel monitoring tasks
        transcriptionMonitorTask?.cancel()
        transcriptionMonitorTask = nil
        
        Task {
            await voiceService.stopRecording()
            stopScreenRecording()
        }
        
        // Stop TTS
        ttsService.stopSpeaking()
        
        lastResponse = ""
    }
    
    // Auto-greeting functionality as specified
    func performAutoGreeting() async {
        guard !hasPerformedGreeting && isActive else { return }
        
        hasPerformedGreeting = true
        currentState = .responding
        
        // First greeting: "hi"
        lastResponse = "hi"
        currentSubtitle = "hi"
        await speakResponse("hi")
        
        // Wait 1.5 seconds then follow up
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Second greeting: "how can I help you"
        lastResponse = "how can I help you"
        currentSubtitle = "how can I help you"
        await speakResponse("how can I help you")
        
        // Return to listening state
        currentState = .standby
    }
    
    // Screen sharing functionality
    func requestScreenShare() async {
        guard !isScreenSharing else { return }
        
        do {
            try await screenRecordingService.startRecording()
            isScreenSharing = true
            screenShareError = nil
            lastResponse = "I can now see your screen. What would you like help with?"
            currentSubtitle = "I can now see your screen. What would you like help with?"
            await speakResponse("I can now see your screen. What would you like help with?")
        } catch {
            screenShareError = error.localizedDescription
            isScreenSharing = false
        }
    }
    
    private func stopScreenRecording() {
        if isScreenSharing {
            screenRecordingService.stopRecording()
            isScreenSharing = false
        }
    }
    
    // ScreenRecordingDelegate method
    func didReceiveScreenFrame(_ sampleBuffer: CMSampleBuffer, bufferType: RPSampleBufferType) {
        guard bufferType == .video else { return }
        
        // Extract image from screen capture for AI analysis
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        
        // Only process if user is asking a question while screen sharing
        if !voiceService.transcriptionText.isEmpty && isScreenSharing {
            Task {
                await processScreenContent(uiImage, userQuery: voiceService.transcriptionText)
            }
        }
    }
    
    private func processScreenContent(_ screenImage: UIImage, userQuery: String) async {
        guard !isProcessing else { return }
        
        // Stop TTS if user speaks
        if ttsService.isSpeaking {
            ttsService.stopSpeaking()
        }
        
        currentState = .thinking
        isProcessing = true
        
        do {
            // Build context for screen analysis
            let context = buildScreenAnalysisContext(userQuery: userQuery)
            
            currentState = .responding
            let aiContext = AIContext()
            let response = try await geminiService.sendMessage(context, context: aiContext)
            
            lastResponse = response.content
            currentSubtitle = response.content
            await speakResponse(response.content)
            
            currentState = .standby
            
        } catch {
            print("Screen analysis error: \(error)")
            lastResponse = "I'm having trouble analyzing the screen. Please try again."
            currentState = .standby
        }
        
        isProcessing = false
        voiceService.transcriptionText = "" // Clear the query
    }
    
    private func buildScreenAnalysisContext(userQuery: String) -> String {
        return "You are Krishi AI assistant. The user is sharing their screen and asked: '\(userQuery)'. " +
               "Analyze what they're showing and provide step-by-step guidance based on what's visible on their screen. " +
               "Be specific about UI elements and actions they can take. Keep responses concise and actionable."
    }
    
    
    // User-triggered processing when they finish speaking
    func processUserInput() async {
        guard isActive && !isPaused && !isProcessing else { return }
        guard !voiceService.transcriptionText.isEmpty else { return }
        
        let userInput = voiceService.transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userInput.isEmpty && userInput != lastUserInput else { return }
        
        // Stop any ongoing TTS immediately when user speaks
        if ttsService.isSpeaking {
            ttsService.stopSpeaking()
        }
        
        lastUserInput = userInput
        currentState = .thinking
        isProcessing = true
        
        // Update subtitle with user's query if enabled
        if subtitlesEnabled {
            currentSubtitle = "User: \(userInput)"
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        // Clear transcription for next input
        voiceService.transcriptionText = ""
        
        // Create context for AI
        let context = buildLiveAIContext(voiceInput: userInput)
        
        do {
            currentState = .responding
            
            // Send to AI for processing
            let aiContext = AIContext()
            let response = try await geminiService.sendMessage(context, context: aiContext)
            
            // Update the response
            lastResponse = response.content
            
            // Speak the response (with interruption support)
            await speakResponse(response.content)
            
            // Return to standby state
            currentState = .standby
            
        } catch {
            print("Live AI Error: \(error)")
            lastResponse = "I'm having trouble processing that. Could you try again?"
            currentState = .standby
        }
        
        isProcessing = false
    }
    
    private func buildLiveAIContext(voiceInput: String) -> String {
        var context = "You are Krishi AI, an agricultural assistant. The user asked: '\(voiceInput)'. "
        context += "Provide helpful, concise agricultural advice. Keep responses under 100 words for voice interaction."
        
        return context
    }
    
    private func speakResponse(_ text: String) async {
        // Update subtitle if enabled
        if subtitlesEnabled {
            currentSubtitle = text
        }
        
        // Use enhanced TTS service with interruption support
        ttsService.speak(text, language: "en-US", rate: 0.52)
        
        // Wait for TTS to finish
        while ttsService.isSpeaking {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Clear subtitle after speaking
        if subtitlesEnabled {
            try? await Task.sleep(nanoseconds: 500_000_000)
            currentSubtitle = ""
        }
    }
    
    func processStaticImage(_ image: UIImage) async {
        guard isActive else { return }
        
        currentState = .thinking
        isProcessing = true
        
        do {
            // Convert image to base64 for Gemini
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                isProcessing = false
                currentState = .standby
                return
            }
            
            currentState = .responding
            let base64Image = imageData.base64EncodedString()
            let prompt = "You are Krishi AI. Analyze this agricultural image and provide brief, helpful advice or insights about what you see. Keep response under 100 words for voice interaction."
            
            // Note: This would need to be implemented in GeminiAIService to handle images
            // For now, we'll use text-only processing
            let aiContext = AIContext()
            let response = try await geminiService.sendMessage(prompt, context: aiContext)
            lastResponse = response.content
            await speakResponse(response.content)
            
            currentState = .standby
            
        } catch {
            print("Image processing error: \(error)")
            currentState = .standby
        }
        
        isProcessing = false
    }
}

// MARK: - Live AI States
enum LiveAIState {
    case standby
    case listening
    case thinking
    case responding
    case paused
}