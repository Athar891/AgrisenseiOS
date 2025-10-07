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
class LiveAIService: ObservableObject, @preconcurrency ScreenRecordingDelegate {
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
    let wakeWordService = WakeWordDetectionService()  // Wake word detection for "Hey Krishi"
    private var lastUserInput: String = ""
    private var hasPerformedGreeting = false
    private let screenRecordingService = ScreenRecordingService()
    private var transcriptionMonitorTask: Task<Void, Never>?
    private var autoProcessTask: Task<Void, Never>?
    private var responseTimeoutTask: Task<Void, Never>?
    private let responseTimeout: TimeInterval = 15.0 // Increased to 15 seconds for reliable API responses
    
    // Rate limit tracking
    private var lastRateLimitTime: Date?
    private var rateLimitRetryCount: Int = 0
    private let maxRetryCount: Int = 3
    
    init(geminiApiKey: String) {
        self.geminiService = GeminiAIService(apiKey: geminiApiKey)
        screenRecordingService.setDelegate(self)
        setupTranscriptionMonitoring()
        setupWakeWordDetection()
    }
    
    private func setupWakeWordDetection() {
        // Setup wake word callback
        wakeWordService.onWakeWordDetected = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🎤 'Hey Krishi' detected - activating assistant")
                
                // If not active, start the session (but wake word is already running)
                if !self.isActive {
                    self.startLiveSession(fromWakeWord: true)
                    return
                }
                
                // If paused, resume
                if self.isPaused {
                    self.resumeSession()
                    return
                }
                
                // If already active and not speaking, just acknowledge
                if !self.ttsService.isSpeaking && !self.isProcessing {
                    self.lastResponse = "Yes? I'm listening..."
                    await self.speakResponse("Yes?", quick: true)
                    self.currentState = .listening
                }
            }
        }
    }
    
    func startLiveSession(fromWakeWord: Bool = false) {
        guard !isActive else { 
            print("⚠️ Session already active, ignoring duplicate start")
            return 
        }
        
        isActive = true
        isPaused = false
        currentState = .standby
        
        print("🚀 Starting Live AI Session (fromWakeWord: \(fromWakeWord))")
        
        // Start wake word detection ONLY if not already running from wake word trigger
        if !fromWakeWord {
            Task {
                if !wakeWordService.isListening {
                    await wakeWordService.startListening()
                    print("✅ Wake word detection started")
                } else {
                    print("ℹ️ Wake word detection already running")
                }
            }
        } else {
            print("ℹ️ Wake word already running (triggered by wake word)")
        }
        
        // Start voice transcription for continuous listening
        Task {
            if !voiceService.isRecording {
                await voiceService.startRecording()
                isListening = true
                print("✅ Voice transcription started")
            } else {
                print("ℹ️ Voice transcription already running")
                isListening = true
            }
        }
        
        // Start audio level monitoring
        startAudioLevelMonitoring()
        
        // Start auto-processing of user speech
        startAutoProcessing()
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
        guard isPaused else {
            print("⚠️ Session not paused, ignoring resume")
            return
        }
        
        print("▶️ Resuming Live AI Session")
        isPaused = false
        currentState = .standby
        
        Task {
            if !voiceService.isRecording {
                await voiceService.startRecording()
                isListening = true
                print("✅ Voice transcription resumed")
            } else {
                print("ℹ️ Voice transcription already running")
                isListening = true
            }
        }
    }
    
    func endSession() {
        guard isActive else {
            print("⚠️ Session not active, ignoring end request")
            return
        }
        
        print("🛑 Ending Live AI Session")
        
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
        autoProcessTask?.cancel()
        autoProcessTask = nil
        responseTimeoutTask?.cancel()
        responseTimeoutTask = nil
        
        // Stop TTS first
        ttsService.stopSpeaking()
        
        // Then stop other services with proper sequencing
        Task {
            // Stop voice transcription first
            if voiceService.isRecording {
                await voiceService.stopRecording()
                print("✅ Voice transcription stopped")
            }
            
            // Small delay before stopping wake word to prevent audio session conflicts
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // Stop wake word detection
            if wakeWordService.isListening {
                wakeWordService.stopListening()
                print("✅ Wake word detection stopped")
            }
            
            // Stop screen recording
            stopScreenRecording()
            
            print("✅ Session ended cleanly")
        }
        
        lastResponse = ""
    }
    
    // Auto-processing: Detect when user stops speaking and process immediately
    private func startAutoProcessing() {
        autoProcessTask = Task { @MainActor in
            var lastTranscription = ""
            var silenceStartTime: Date?
            let silenceThreshold: TimeInterval = 1.5 // Process after 1.5 seconds of silence
            
            while !Task.isCancelled && isActive {
                try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1s
                
                let currentTranscription = voiceService.transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // User started speaking
                if !currentTranscription.isEmpty && currentTranscription != lastTranscription {
                    silenceStartTime = nil
                    lastTranscription = currentTranscription
                }
                // User stopped speaking (transcription hasn't changed)
                else if !currentTranscription.isEmpty && currentTranscription == lastTranscription {
                    if silenceStartTime == nil {
                        silenceStartTime = Date()
                    } else if let startTime = silenceStartTime,
                              Date().timeIntervalSince(startTime) >= silenceThreshold,
                              !isProcessing {
                        // User has stopped speaking - process the input
                        await processUserInput()
                        silenceStartTime = nil
                        lastTranscription = ""  // Reset to prevent re-processing
                        // Wait a bit to ensure voice service has cleared
                        try? await Task.sleep(nanoseconds: 500_000_000)  // 500ms
                    }
                }
                // Reset if transcription was cleared externally
                else if currentTranscription.isEmpty && !lastTranscription.isEmpty {
                    lastTranscription = ""
                    silenceStartTime = nil
                }
            }
        }
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
            Task {
                await screenRecordingService.stopRecording()
                await MainActor.run {
                    isScreenSharing = false
                }
            }
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
        
        // Check if we're in rate limit backoff period
        if let rateLimitTime = lastRateLimitTime {
            let backoffSeconds = min(pow(2.0, Double(rateLimitRetryCount)), 30.0)
            let timeSinceRateLimit = Date().timeIntervalSince(rateLimitTime)
            
            if timeSinceRateLimit < backoffSeconds {
                let remainingTime = Int(backoffSeconds - timeSinceRateLimit)
                print("⏳ Still in backoff period. Wait \(remainingTime)s more.")
                voiceService.transcriptionText = "" // Clear to prevent reprocessing
                return
            }
        }
        
        let userInput = voiceService.transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userInput.isEmpty && userInput != lastUserInput else { 
            print("⏭️ Skipping duplicate input: \(userInput)")
            return 
        }
        
        // Stop any ongoing TTS immediately when user speaks
        if ttsService.isSpeaking {
            ttsService.stopSpeaking()
        }
        
        // Clear transcription IMMEDIATELY to prevent re-processing
        voiceService.transcriptionText = ""
        
        lastUserInput = userInput
        currentState = .thinking
        isProcessing = true
        
        print("💬 Processing user input: \(userInput)")
        
        // Update subtitle with user's query if enabled
        if subtitlesEnabled {
            currentSubtitle = "You: \(userInput)"
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        // Create context for AI
        let context = buildLiveAIContext(voiceInput: userInput)
        
        do {
            currentState = .responding
            
            // Start timeout task
            responseTimeoutTask?.cancel()
            responseTimeoutTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(responseTimeout * 1_000_000_000))
                if isProcessing {
                    print("⚠️ Response timeout - retrying")
                    lastResponse = "Hmm… let me try that again."
                    await speakResponse("Hmm… let me try that again.", quick: true)
                    isProcessing = false
                    currentState = .standby
                }
            }
            
            // Send to AI for processing with streaming support (voice-optimized)
            let aiContext = AIContext()
            let response = try await geminiService.sendMessageWithStreaming(context, context: aiContext, forVoice: true)
            
            // Cancel timeout IMMEDIATELY after receiving response
            responseTimeoutTask?.cancel()
            responseTimeoutTask = nil
            
            // Mark processing as complete BEFORE speaking to prevent timeout race condition
            isProcessing = false
            
            // Update the response
            lastResponse = response.content
            
            print("✅ AI Response: \(response.content)")
            
            // Speak the response (with interruption support)
            await speakResponse(response.content)
            
            // Return to standby state
            currentState = .standby
            
        } catch {
            responseTimeoutTask?.cancel()
            responseTimeoutTask = nil
            isProcessing = false
            
            print("❌ Live AI Error: \(error)")
            print("❌ Error details: \(String(describing: error))")
            
            // Provide more specific error message based on error type
            if let aiError = error as? AIError {
                switch aiError {
                case .timeout:
                    lastResponse = "The request took too long. Please try again."
                case .rateLimitExceeded:
                    // Track rate limit with exponential backoff
                    lastRateLimitTime = Date()
                    rateLimitRetryCount += 1
                    
                    let backoffSeconds = min(pow(2.0, Double(rateLimitRetryCount)), 30.0) // Max 30 seconds
                    lastResponse = "I need a moment to catch up. Please wait \(Int(backoffSeconds)) seconds."
                    
                    print("⏳ Rate limit hit. Backoff: \(backoffSeconds)s (attempt \(rateLimitRetryCount)/\(maxRetryCount))")
                    
                    // Pause auto-processing during backoff
                    autoProcessTask?.cancel()
                    
                case .invalidAPIKey:
                    lastResponse = "There's a configuration issue. Please check settings."
                case .serviceUnavailable:
                    lastResponse = "The AI service is temporarily unavailable."
                default:
                    lastResponse = "I'm having trouble processing that. Could you try again?"
                }
            } else {
                lastResponse = "I'm having trouble processing that. Could you try again?"
            }
            
            await speakResponse(lastResponse, quick: true)
            currentState = .standby
            
            // Resume auto-processing after backoff (for rate limits)
            if let rateLimitTime = lastRateLimitTime {
                let backoffSeconds = min(pow(2.0, Double(rateLimitRetryCount)), 30.0)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
                    
                    // Reset retry count if enough time has passed
                    if let lastTime = self.lastRateLimitTime,
                       Date().timeIntervalSince(lastTime) >= 60.0 {
                        self.rateLimitRetryCount = 0
                        print("✅ Rate limit cooldown complete - resetting retry count")
                    }
                    
                    // Resume auto-processing
                    self.startAutoProcessing()
                    print("▶️ Resuming auto-processing after backoff")
                }
            }
        }
    }
    
    private func buildLiveAIContext(voiceInput: String) -> String {
        var context = "You are Krishi AI, an agricultural assistant. The user asked: '\(voiceInput)'. "
        context += "Provide helpful, concise agricultural advice. Keep responses under 100 words for voice interaction. "
        context += "IMPORTANT: Do not use emojis or special characters in your response as it will be spoken aloud. Use plain text only."
        
        return context
    }
    
    /// Clean text for natural speech by removing emojis, bullet points, and excessive punctuation
    private func cleanTextForSpeech(_ text: String) -> String {
        var cleaned = text
        
        // Remove emojis (Unicode ranges)
        let emojiRanges: [ClosedRange<UnicodeScalar>] = [
            "\u{1F300}"..."\u{1F9FF}",  // Emoticons, symbols, pictographs
            "\u{2600}"..."\u{26FF}",    // Miscellaneous symbols
            "\u{2700}"..."\u{27BF}",    // Dingbats
            "\u{FE00}"..."\u{FE0F}",    // Variation selectors
            "\u{1F900}"..."\u{1F9FF}",  // Supplemental symbols
            "\u{1F1E0}"..."\u{1F1FF}"   // Flags
        ]
        
        cleaned.unicodeScalars.removeAll { scalar in
            emojiRanges.contains { $0.contains(scalar) }
        }
        
        // Replace bullet points and special markers with natural pause
        cleaned = cleaned.replacingOccurrences(of: "•", with: ",")
        cleaned = cleaned.replacingOccurrences(of: "◦", with: ",")
        cleaned = cleaned.replacingOccurrences(of: "▪", with: ",")
        cleaned = cleaned.replacingOccurrences(of: "→", with: "to")
        cleaned = cleaned.replacingOccurrences(of: "–", with: "-")
        cleaned = cleaned.replacingOccurrences(of: "—", with: "-")
        
        // Clean up excessive punctuation
        cleaned = cleaned.replacingOccurrences(of: "!!!", with: ".")
        cleaned = cleaned.replacingOccurrences(of: "!!", with: ".")
        cleaned = cleaned.replacingOccurrences(of: "???", with: "?")
        cleaned = cleaned.replacingOccurrences(of: "??", with: "?")
        cleaned = cleaned.replacingOccurrences(of: "...", with: ".")
        cleaned = cleaned.replacingOccurrences(of: "…", with: ".")
        
        // Remove multiple spaces
        cleaned = cleaned.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    private func speakResponse(_ text: String, quick: Bool = false) async {
        // Clean text for natural speech (remove emojis, etc.)
        let cleanedText = cleanTextForSpeech(text)
        
        // Update subtitle with original text (emojis ok for visual)
        if subtitlesEnabled {
            currentSubtitle = text
        }
        
        // **PAUSE voice transcription to prevent feedback loop**
        voiceService.pauseRecording()
        
        // Use enhanced TTS service with cleaned text for natural speech
        let rate: Float = quick ? 0.55 : 0.52
        ttsService.speak(cleanedText, language: "en-US", rate: rate)
        
        // Wait for TTS to finish
        while ttsService.isSpeaking && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // **RESUME voice transcription after TTS completes**
        await voiceService.resumeRecording()
        
        // Clear any transcription that accumulated during TTS
        voiceService.transcriptionText = ""
        
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
            currentState = .responding
            let prompt = "You are Krishi AI. Analyze this agricultural image and provide brief, helpful advice or insights about what you see. Keep response under 100 words for voice interaction."
            
            // Use Gemini's vision capabilities
            let aiContext = AIContext()
            let response = try await geminiService.sendMessageWithImage(prompt, image: image, context: aiContext)
            lastResponse = response.content
            await speakResponse(response.content)
            
            currentState = .standby
            
        } catch {
            print("❌ Image processing error: \(error)")
            lastResponse = "I'm having trouble analyzing this image. Please try again."
            currentState = .standby
        }
        
        isProcessing = false
    }
    
    // Process live camera frames for real-time analysis
    func processCameraFrame(_ image: UIImage, userContext: String) async {
        guard isActive && !isProcessing else { return }
        
        currentState = .thinking
        isProcessing = true
        
        do {
            let prompt = "You are Krishi AI assistant viewing through the user's camera. \(userContext). Briefly describe what you see and provide relevant agricultural insights. Keep response under 80 words."
            
            let aiContext = AIContext()
            let response = try await geminiService.sendMessageWithImage(prompt, image: image, context: aiContext)
            
            lastResponse = response.content
            currentSubtitle = response.content
            await speakResponse(response.content)
            
            currentState = .standby
            
        } catch {
            print("❌ Camera frame analysis error: \(error)")
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