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
// This service provides continuous listening with interrupt capability:
// 1. Voice transcription is always active when session is running (except during TTS playback)
// 2. User can interrupt AI responses at any time by speaking
// 3. After AI finishes responding, it immediately returns to listening state
// 4. Auto-processing detects when user stops speaking and processes input automatically
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
    let wakeWordService = WakeWordDetectionService()  // Wake word detection for "Please"
    private let webSearchService = WebSearchService()  // Web search for links and information
    private var lastUserInput: String = ""
    private var hasPerformedGreeting = false
    
    // Conversation Memory (Short-term context awareness)
    private var conversationHistory: [ConversationTurn] = []
    private let maxHistoryTurns = 5  // Keep last 5 exchanges for context
    
    private let screenRecordingService = ScreenRecordingService()
    private var transcriptionMonitorTask: Task<Void, Never>?
    private var autoProcessTask: Task<Void, Never>?
    private var responseTimeoutTask: Task<Void, Never>?
    private var standbyTimeoutTask: Task<Void, Never>?
    private var questionWaitTimeoutTask: Task<Void, Never>?  // Timeout for waiting for user question after wake word
    private let responseTimeout: TimeInterval = 15.0 // Increased to 15 seconds for reliable API responses
    private let standbyTimeout: TimeInterval = 10.0 // Return to standby after 10 seconds of no speech
    private let questionWaitTimeout: TimeInterval = 5.0 // Time to wait for user question after wake word
    
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

    private func cancelBackgroundTasks() {
        transcriptionMonitorTask?.cancel()
        transcriptionMonitorTask = nil
        autoProcessTask?.cancel()
        autoProcessTask = nil
        responseTimeoutTask?.cancel()
        responseTimeoutTask = nil
        standbyTimeoutTask?.cancel()
        standbyTimeoutTask = nil
        questionWaitTimeoutTask?.cancel()
        questionWaitTimeoutTask = nil
    }
    
    private func setupWakeWordDetection() {
        print("[LiveAI] Setting up wake word detection callback")
        // Setup wake word callback
        wakeWordService.onWakeWordDetected = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                print("🎤 'Please' detected - activating assistant")
                
                // IMPORTANT: Pause wake word detection temporarily to let voice transcription capture the user's question
                print("[LiveAI] Pausing wake word to capture user question...")
                self.wakeWordService.stopListening()
                
                // If not active, start the session (but wake word is already running)
                if !self.isActive {
                    print("▶️ Starting session from wake word")
                    self.startLiveSession(fromWakeWord: true)
                    return
                }
                
                // If paused, resume
                if self.isPaused {
                    print("▶️ Resuming from wake word")
                    self.resumeSession()
                    
                    // Clear any transcription (wake word phrase)
                    self.voiceService.transcriptionText = ""
                    self.lastUserInput = ""
                    
                    // Acknowledge
                    self.lastResponse = "Yes, I'm here. How can I help?"
                    await self.speakResponse("Yes, I'm here. How can I help?", quick: true)
                    
                    // Clear again after TTS and prepare for question
                    self.voiceService.transcriptionText = ""
                    self.lastUserInput = ""
                    print("[LiveAI] Ready to capture user question...")
                    
                    // Restart auto-processing for the new question
                    self.autoProcessTask?.cancel()
                    self.startAutoProcessing()
                    print("[LiveAI] Wake word detection will resume after AI responds")
                    
                    // DON'T restart wake word yet - let user ask their question
                    return
                }
                
                // If already active and not speaking, wait for user's question
                if !self.ttsService.isSpeaking && !self.isProcessing {
                    print("👂 Wake word detected - waiting for user's question")
                    
                    // Cancel any active standby timeout since user is interacting
                    self.cancelStandbyTimeout()
                    
                    // Store the current transcription before processing
                    let currentTranscription = self.voiceService.transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("[LiveAI] Current transcription at wake word: '\(currentTranscription)'")
                    
                    // Remove the wake word "please" from the beginning of the transcription
                    // This preserves the user's actual question if they said "please tell me about..."
                    var questionText = currentTranscription.lowercased()
                    let wakeWordsToRemove = ["please", "pleas", "plez", "plz"]
                    for wakeWord in wakeWordsToRemove {
                        if questionText.hasPrefix(wakeWord) {
                            questionText = String(questionText.dropFirst(wakeWord.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                            break
                        }
                    }
                    
                    // If there's remaining text after removing wake word, keep it as the question start
                    if !questionText.isEmpty {
                        // Restore original case by finding the portion after wake word
                        if let range = currentTranscription.range(of: questionText, options: .caseInsensitive) {
                            let preservedQuestion = String(currentTranscription[range.lowerBound...])
                            self.voiceService.transcriptionText = preservedQuestion
                            print("[LiveAI] Preserved question text: '\(preservedQuestion)'")
                        } else {
                            self.voiceService.transcriptionText = questionText
                            print("[LiveAI] Using processed question text: '\(questionText)'")
                        }
                    } else {
                        // Only clear if there's nothing but the wake word
                        self.voiceService.transcriptionText = ""
                        print("[LiveAI] Cleared wake word, waiting for question")
                    }
                    self.lastUserInput = ""
                    
                    // Set state to listening immediately (no acknowledgment - just listen)
                    self.currentState = .listening
                    print("[LiveAI] State set to listening - waiting for user question")
                    
                    // Ensure voice transcription is actively running
                    if !self.voiceService.isRecording {
                        print("[LiveAI] Voice transcription not active - restarting")
                        await self.voiceService.startRecording()
                        self.isListening = true
                    } else {
                        print("[LiveAI] Voice transcription already active")
                    }
                    
                    // Start the question wait timeout - if no question in 5 seconds, return to standby
                    self.startQuestionWaitTimeout()
                    
                    // Restart auto-processing to ensure it's actively monitoring for user input
                    self.autoProcessTask?.cancel()
                    self.startAutoProcessing()
                    print("[LiveAI] Auto-processing restarted - listening for user question")
                    
                    // DON'T restart wake word yet - let user ask their question
                    // Wake word will restart after AI responds and returns to standby
                } else {
                    print("⏭️ Wake word detected but already busy (speaking: \(self.ttsService.isSpeaking), processing: \(self.isProcessing))")
                    // Don't restart wake word if busy - will restart after current task completes
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
        print("📝 Continuous listening enabled - user can interrupt at any time")
        
        // Start wake word detection ONLY if not already running from wake word trigger
        if !fromWakeWord {
            Task {
                if !wakeWordService.isListening {
                    print("🎤 Starting wake word detection for 'Please'...")
                    await wakeWordService.requestPermissions()
                    await wakeWordService.startListening()
                    print("✅ Wake word detection active and listening")
                } else {
                    print("⚠️ Wake word detection already running")
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
            var lastTranscriptionTime = Date()
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1s
                
                let currentTranscription = voiceService.transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Detect when user starts speaking (transcription changes)
                let transcriptionChanged = !currentTranscription.isEmpty && currentTranscription != lastTranscription
                
                if transcriptionChanged {
                    lastTranscriptionTime = Date()
                    
                    // Filter out wake word phrases to prevent false state changes
                    let isWakeWordPhrase = currentTranscription.lowercased().contains("hey ai") || 
                                          currentTranscription.lowercased().contains("hay ai") ||
                                          currentTranscription.lowercased() == "hi" ||
                                          currentTranscription.lowercased() == "yes"
                    
                    // Note: TTS interruption is no longer handled here since we pause transcription during TTS
                    // Just handle state transitions for when user starts speaking
                    
                    // If AI is in standby, switch to listening state
                    if currentState == .standby && !isWakeWordPhrase && !ttsService.isSpeaking {
                        currentState = .listening
                        print("🎤 User started speaking")
                    }
                    // If AI is thinking, let user interrupt
                    else if currentState == .thinking && currentTranscription.count >= 5 && !isWakeWordPhrase {
                        print("🎤 User interrupted during thinking phase")
                        isProcessing = false
                        responseTimeoutTask?.cancel()
                        responseTimeoutTask = nil
                        currentState = .listening
                    }
                    
                    if isWakeWordPhrase {
                        print("🔇 Ignoring wake word phrase in monitoring: '\(currentTranscription)'")
                    }
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
        
        // Clear conversation history
        clearConversationHistory()
        
        // Cancel monitoring tasks
        cancelBackgroundTasks()
        
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
            let silenceThreshold: TimeInterval = 1.2 // Reduced to 1.2 seconds for faster response
            
            print("[AutoProcess] Task started - monitoring for user input")
            
            while !Task.isCancelled && isActive {
                try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1s
                
                let currentTranscription = voiceService.transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // User started speaking or continued speaking
                if !currentTranscription.isEmpty && currentTranscription != lastTranscription {
                    silenceStartTime = nil
                    lastTranscription = currentTranscription
                    print("[AutoProcess] New transcription detected: '\(currentTranscription.prefix(50))...' (\(currentTranscription.count) chars)")
                    
                    // Cancel standby timeout since user is speaking
                    cancelStandbyTimeout()
                    
                    // Cancel question wait timeout since user is speaking
                    cancelQuestionWaitTimeout()
                    
                    // If user starts speaking while AI is talking, they're interrupting
                    if ttsService.isSpeaking {
                        print("🎤 User is speaking while AI talks - interrupting")
                        // The transcription monitor will handle stopping TTS
                        // Just update visual state
                        currentState = .listening
                    }
                    // Visual feedback - switch to listening state (or stay in listening)
                    else if currentState == .standby || currentState == .responding {
                        currentState = .listening
                        print("[AutoProcess] State changed to listening (user speaking)")
                    }
                    // If already in listening state, just log the update
                    else if currentState == .listening {
                        print("[AutoProcess] User continues speaking (already in listening state)")
                    }
                }
                // User stopped speaking (transcription hasn't changed)
                else if !currentTranscription.isEmpty && currentTranscription == lastTranscription {
                    if silenceStartTime == nil {
                        silenceStartTime = Date()
                        print("[AutoProcess] Silence started - waiting \(silenceThreshold)s before processing")
                        print("[AutoProcess] Current text: '\(currentTranscription.prefix(50))...'")
                    } else if let startTime = silenceStartTime {
                        let silenceDuration = Date().timeIntervalSince(startTime)
                        
                        if silenceDuration >= silenceThreshold && !isProcessing {
                            print("[AutoProcess] Silence threshold reached (\(String(format: "%.1f", silenceDuration))s)")
                            print("[AutoProcess] TTS speaking: \(ttsService.isSpeaking), Text length: \(currentTranscription.count)")
                            print("[AutoProcess] Current state: \(currentState)")
                            
                            // If TTS is currently speaking, wait for it to finish
                            if ttsService.isSpeaking {
                                print("[AutoProcess] Waiting for TTS to finish before processing...")
                                // Keep the silence timer active - will check again in next iteration
                            } else {
                                // TTS is not speaking AND user has been silent for threshold
                                // This is a genuine question ready to process
                                print("🎯 Silence threshold reached with TTS idle - processing user input")
                                print("🎯 About to call processUserInput() with: '\(currentTranscription)'")
                                await processUserInput()
                                silenceStartTime = nil
                                lastTranscription = ""  // Reset to prevent re-processing
                                // Brief pause to ensure voice service has cleared
                                try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms
                            }
                        } else if silenceDuration >= 0.5 {
                            // Progress log every 0.5s
                            if Int(silenceDuration * 10) % 5 == 0 {
                                print("[AutoProcess] Silence: \(String(format: "%.1f", silenceDuration))s / \(silenceThreshold)s")
                            }
                        }
                    }
                }
                // Reset if transcription was cleared externally
                else if currentTranscription.isEmpty && !lastTranscription.isEmpty {
                    lastTranscription = ""
                    silenceStartTime = nil
                    // Return to standby if not processing
                    if currentState == .listening && !isProcessing && !ttsService.isSpeaking {
                        currentState = .standby
                        // Start standby timeout when returning to standby
                        startStandbyTimeout()
                    }
                }
                // If in standby with no transcription for extended period, ensure timeout is running
                else if currentTranscription.isEmpty && currentState == .standby && !isProcessing && !ttsService.isSpeaking {
                    // Standby timeout should already be running, but verify
                    if standbyTimeoutTask == nil {
                        startStandbyTimeout()
                    }
                }
            }
        }
    }
    
    // Auto-greeting functionality as specified
    func performAutoGreeting() async {
        guard !hasPerformedGreeting && isActive else {
            print("⚠️ Auto-greeting skipped: hasPerformedGreeting=\(hasPerformedGreeting), isActive=\(isActive)")
            return
        }
        
        print("👋 Performing auto-greeting...")
        hasPerformedGreeting = true
        currentState = .responding
        
        // First greeting: "Hi, I'm Krishi AI"
        lastResponse = "Hi, I'm Krishi AI"
        await speakResponse("Hi, I'm Krishi AI")
        
        // Wait 1.5 seconds then follow up
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Second greeting: "how can I help you today"
        lastResponse = "How can I help you today?"
        await speakResponse("How can I help you today?")
        
        // Return to listening state and start standby timeout
        currentState = .standby
        startStandbyTimeout()
        print("✅ Auto-greeting completed, ready for user input")
    }
    
    // Screen sharing functionality
    func requestScreenShare() async {
        guard !isScreenSharing else { return }
        
        do {
            try await screenRecordingService.startRecording()
            isScreenSharing = true
            screenShareError = nil
            lastResponse = "I can now see your screen. What would you like help with?"
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
        print("🔍 processUserInput called")
        print("   - isActive: \(isActive)")
        print("   - isPaused: \(isPaused)")
        print("   - isProcessing: \(isProcessing)")
        print("   - transcriptionText: '\(voiceService.transcriptionText)'")
        
        guard isActive && !isPaused && !isProcessing else {
            print("❌ Guard failed: isActive=\(isActive), isPaused=\(isPaused), isProcessing=\(isProcessing)")
            return
        }
        guard !voiceService.transcriptionText.isEmpty else {
            print("❌ Guard failed: empty transcription")
            return
        }
        
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
            print("🛑 Stopping ongoing TTS")
            ttsService.stopSpeaking()
        }
        
        // Clear transcription IMMEDIATELY to prevent re-processing
        voiceService.transcriptionText = ""
        
        lastUserInput = userInput
        currentState = .thinking
        isProcessing = true
        
        print("💬 Processing user input: \(userInput)")
        print("🧠 State changed to: thinking")
        
        // Detect if user needs web search (links, products, schemes, research)
        let needsWebSearch = detectWebSearchIntent(in: userInput)
        var webSearchResults: [WebSearchResult] = []
        
        if needsWebSearch {
            print("🔍 Web search detected - fetching relevant links")
            webSearchResults = await performContextualWebSearch(for: userInput)
        }
        
        // Create context for AI (with web search results if available)
        let context = buildLiveAIContext(voiceInput: userInput, webResults: webSearchResults)
        
        do {
            currentState = .responding
            print("🎭 State changed to: responding")
            
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
            
            print("📡 Sending message to Gemini AI...")
            
            // Send to AI for processing with streaming support (voice-optimized)
            let aiContext = AIContext()
            let response = try await geminiService.sendMessageWithStreaming(context, context: aiContext, forVoice: true)
            
            print("✅ Received AI response!")
            
            // Cancel timeout IMMEDIATELY after receiving response
            responseTimeoutTask?.cancel()
            responseTimeoutTask = nil
            
            // Mark processing as complete BEFORE speaking to prevent timeout race condition
            isProcessing = false
            
            // Update the response
            lastResponse = response.content
            
            print("✅ AI Response: \(response.content)")
            
            // Save to conversation history for context awareness
            addToConversationHistory(userInput: userInput, aiResponse: response.content)
            
            // Speak the response (with interruption support)
            print("🗣️ Starting to speak response...")
            await speakResponse(response.content)
            
            // Return to standby state and ensure voice recording is active for continuous listening
            currentState = .standby
            print("🎭 State changed to: standby")
            
            // Start 10-second standby timeout for next user input
            startStandbyTimeout()
            print("⏱️ Started 10-second timeout for next user question")
            
            // NOW restart wake word detection - AI is back in standby and ready for next command
            if !wakeWordService.isListening {
                print("[LiveAI] Restarting wake word detection (now in standby mode)...")
                await wakeWordService.startListening()
            }
            
            // Verify voice recording is still active for continuous listening
            if !voiceService.isRecording {
                print("⚠️ Voice recording stopped unexpectedly - restarting for continuous listening")
                await voiceService.startRecording()
                isListening = true
            }
            
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
            
            // Start 10-second standby timeout after error
            startStandbyTimeout()
            
            // Restart wake word detection after error (now in standby)
            if !wakeWordService.isListening {
                print("[LiveAI] Restarting wake word detection after error (standby mode)...")
                await wakeWordService.startListening()
            }
            
            // Ensure voice recording is active for continuous listening even after errors
            if !voiceService.isRecording {
                print("⚠️ Voice recording stopped after error - restarting for continuous listening")
                await voiceService.startRecording()
                isListening = true
            }
            
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
    
    // MARK: - Web Search Integration
    
    /// Detect if user's query requires web search
    private func detectWebSearchIntent(in query: String) -> Bool {
        let lowercaseQuery = query.lowercased()
        
        let searchKeywords = [
            "buy", "purchase", "where to find", "where can i get", "link", "website",
            "government scheme", "subsidy", "yojana", "pmkisan", "loan",
            "research", "article", "study", "paper", "guide",
            "price", "market", "selling", "shop", "store",
            "information about", "details of", "more about"
        ]
        
        return searchKeywords.contains { lowercaseQuery.contains($0) }
    }
    
    /// Perform contextual web search based on query intent
    private func performContextualWebSearch(for query: String) async -> [WebSearchResult] {
        let lowercaseQuery = query.lowercased()
        
        // Detect specific search types
        if lowercaseQuery.contains("buy") || lowercaseQuery.contains("purchase") || lowercaseQuery.contains("shop") {
            // Product search
            let productKeywords = extractProductKeywords(from: query)
            return await webSearchService.searchProducts(productName: productKeywords)
        }
        else if lowercaseQuery.contains("government") || lowercaseQuery.contains("scheme") || 
                lowercaseQuery.contains("subsidy") || lowercaseQuery.contains("yojana") || 
                lowercaseQuery.contains("loan") {
            // Government schemes search
            return await webSearchService.searchGovernmentSchemes(topic: query)
        }
        else if lowercaseQuery.contains("research") || lowercaseQuery.contains("article") || 
                lowercaseQuery.contains("study") || lowercaseQuery.contains("guide") {
            // Research/educational content search
            return await webSearchService.searchResearch(topic: query)
        }
        else {
            // General agricultural search
            return await webSearchService.search(query: "\(query) agriculture farming india")
        }
    }
    
    /// Extract product keywords from natural language query
    private func extractProductKeywords(from query: String) -> String {
        // Remove common filler words
        var keywords = query.lowercased()
        let fillerWords = ["where can i", "how do i", "i want to", "i need to", "can you help me", 
                          "buy", "purchase", "find", "get", "looking for"]
        
        for filler in fillerWords {
            keywords = keywords.replacingOccurrences(of: filler, with: "")
        }
        
        return keywords.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func buildLiveAIContext(voiceInput: String, webResults: [WebSearchResult] = []) -> String {
        var context = "You are Krishi AI, an expert agricultural assistant with deep knowledge of farming practices, crop management, soil health, weather patterns, pest control, government schemes, and modern agricultural technologies.\n\n"
        
        // Add conversation history for context awareness
        if !conversationHistory.isEmpty {
            context += "Recent conversation context:\n"
            for (index, turn) in conversationHistory.enumerated() {
                context += "[\(index + 1)] User: \(turn.userInput)\n"
                context += "    AI: \(turn.aiResponse)\n"
            }
            context += "\n"
        }
        
        // Add web search results if available
        if !webResults.isEmpty {
            context += "Web search results for additional context:\n"
            for (index, result) in webResults.enumerated() {
                context += "[\(index + 1)] \(result.title)\n"
                context += "    URL: \(result.url)\n"
                context += "    Summary: \(result.snippet)\n"
            }
            context += "\nYou can reference these links in your response when relevant. Mention them naturally like 'You can find more information at [source]' or 'For purchasing, check [link]'\n\n"
        }
        
        context += "Current user question: '\(voiceInput)'\n\n"
        context += "CRITICAL RESPONSE FORMATTING RULES:\n"
        context += "1. Length: Keep responses between 50-80 words for natural speech\n"
        context += "2. Absolutely NO emojis, asterisks, bullet points, or special characters\n"
        context += "3. Write in flowing paragraphs with complete sentences\n"
        context += "4. Use only basic punctuation: periods, commas, question marks\n"
        context += "5. Avoid redundant phrases like 'Here's a breakdown' or 'In summary'\n"
        context += "6. Start with the most important information first\n"
        context += "7. Use conversational, natural language as if speaking to someone\n"
        context += "8. Add proper spacing between ideas for readability\n"
        context += "9. If conversation history exists, use it to provide contextual answers\n"
        context += "10. When mentioning links, integrate them naturally in the text\n"
        
        return context
    }
    
    /// Add conversation turn to history for context awareness
    private func addToConversationHistory(userInput: String, aiResponse: String) {
        let turn = ConversationTurn(userInput: userInput, aiResponse: aiResponse)
        conversationHistory.append(turn)
        
        // Keep only the last N turns to prevent context overflow
        if conversationHistory.count > maxHistoryTurns {
            conversationHistory.removeFirst()
        }
        
        print("💬 Conversation history updated: \(conversationHistory.count) turns stored")
    }
    
    /// Clear conversation history when session ends
    private func clearConversationHistory() {
        conversationHistory.removeAll()
        print("🗑️ Conversation history cleared")
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
        
        // Remove markdown bold/italic formatting
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "__", with: "")
        cleaned = cleaned.replacingOccurrences(of: "*", with: "")
        cleaned = cleaned.replacingOccurrences(of: "_", with: "")
        
        // Remove markdown headers
        cleaned = cleaned.replacingOccurrences(of: "###", with: "")
        cleaned = cleaned.replacingOccurrences(of: "##", with: "")
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")
        
        // Replace bullet points and special markers with natural pauses
        cleaned = cleaned.replacingOccurrences(of: "•", with: "")
        cleaned = cleaned.replacingOccurrences(of: "◦", with: "")
        cleaned = cleaned.replacingOccurrences(of: "▪", with: "")
        cleaned = cleaned.replacingOccurrences(of: "○", with: "")
        cleaned = cleaned.replacingOccurrences(of: "●", with: "")
        
        // Replace special dashes and arrows
        cleaned = cleaned.replacingOccurrences(of: "→", with: "to")
        cleaned = cleaned.replacingOccurrences(of: "–", with: "-")
        cleaned = cleaned.replacingOccurrences(of: "—", with: "-")
        cleaned = cleaned.replacingOccurrences(of: "=>", with: "")
        
        // Remove redundant phrases that AI sometimes adds
        let redundantPhrases = [
            "Here's a breakdown:",
            "Here is a breakdown:",
            "In summary,",
            "To summarize,",
            "Let me break this down:",
            "Here's what you need to know:",
            "Let's go through it:",
            "Here are the details:",
            "Let me explain:"
        ]
        
        for phrase in redundantPhrases {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }
        
        // Clean up excessive punctuation
        cleaned = cleaned.replacingOccurrences(of: "!!!", with: ".")
        cleaned = cleaned.replacingOccurrences(of: "!!", with: ".")
        cleaned = cleaned.replacingOccurrences(of: "???", with: "?")
        cleaned = cleaned.replacingOccurrences(of: "??", with: "?")
        cleaned = cleaned.replacingOccurrences(of: "...", with: ".")
        cleaned = cleaned.replacingOccurrences(of: "…", with: ".")
        
        // Remove section dividers
        cleaned = cleaned.replacingOccurrences(of: "---", with: "")
        cleaned = cleaned.replacingOccurrences(of: "___", with: "")
        cleaned = cleaned.replacingOccurrences(of: "***", with: "")
        
        // Clean up line breaks and convert to natural sentence flow
        // Replace multiple newlines with a single space for continuous speech
        cleaned = cleaned.replacingOccurrences(of: "\n\n", with: ". ")
        cleaned = cleaned.replacingOccurrences(of: "\n", with: " ")
        
        // Remove multiple spaces
        cleaned = cleaned.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        
        // Fix spacing around punctuation
        cleaned = cleaned.replacingOccurrences(of: " .", with: ".")
        cleaned = cleaned.replacingOccurrences(of: " ,", with: ",")
        cleaned = cleaned.replacingOccurrences(of: " :", with: ":")
        cleaned = cleaned.replacingOccurrences(of: " ;", with: ";")
        
        // Ensure proper spacing after punctuation
        cleaned = cleaned.replacingOccurrences(of: "\\.([A-Z])", with: ". $1", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: ",([A-Za-z])", with: ", $1", options: .regularExpression)
        
        // Trim whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    private func startStandbyTimeout() {
        // Cancel any existing timeout
        standbyTimeoutTask?.cancel()
        
        // Start new timeout
        standbyTimeoutTask = Task { @MainActor in
            print("⏱️ Starting 10-second standby timeout...")
            try? await Task.sleep(nanoseconds: UInt64(standbyTimeout * 1_000_000_000))
            
            guard !Task.isCancelled else {
                print("⏱️ Standby timeout cancelled")
                return
            }
            
            // Check if user hasn't spoken and we're still in standby
            if voiceService.transcriptionText.isEmpty && currentState == .standby && !isProcessing {
                print("⏱️ 10 seconds elapsed with no speech detected - maintaining standby mode")
                // Already in standby, just ensure listening is properly set
                isListening = voiceService.isRecording
                
                // Could optionally provide audio feedback here
                // await speakResponse("Still here if you need me", quick: true)
            }
        }
    }
    
    private func cancelStandbyTimeout() {
        standbyTimeoutTask?.cancel()
        standbyTimeoutTask = nil
        print("⏱️ Standby timeout cancelled - user activity detected")
    }
    
    /// Start timeout for waiting for user question after wake word detection
    /// If user doesn't speak within the timeout, return to standby mode
    private func startQuestionWaitTimeout() {
        // Cancel any existing timeout
        questionWaitTimeoutTask?.cancel()
        
        // Start new timeout
        questionWaitTimeoutTask = Task { @MainActor in
            print("⏱️ Starting \(questionWaitTimeout)-second question wait timeout...")
            try? await Task.sleep(nanoseconds: UInt64(questionWaitTimeout * 1_000_000_000))
            
            guard !Task.isCancelled else {
                print("⏱️ Question wait timeout cancelled (user started speaking)")
                return
            }
            
            // Check if user hasn't spoken anything
            if voiceService.transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               currentState == .listening && !isProcessing && !ttsService.isSpeaking {
                print("⏱️ No question detected after wake word - returning to standby mode")
                
                // Return to standby state
                currentState = .standby
                
                // Restart wake word detection
                if !wakeWordService.isListening {
                    print("[LiveAI] Restarting wake word detection (no question received)...")
                    await wakeWordService.startListening()
                }
                
                // Start standby timeout
                startStandbyTimeout()
            }
        }
    }
    
    /// Cancel the question wait timeout (when user starts speaking)
    private func cancelQuestionWaitTimeout() {
        questionWaitTimeoutTask?.cancel()
        questionWaitTimeoutTask = nil
        print("⏱️ Question wait timeout cancelled - user is speaking")
    }
    
    private func speakResponse(_ text: String, quick: Bool = false) async {
        // Clean text for natural speech (remove emojis, etc.)
        let cleanedText = cleanTextForSpeech(text)
        
        print("🔊 Speaking response: \(cleanedText.prefix(50))...")
        
        // Always update subtitle (will be shown if subtitlesEnabled)
        currentSubtitle = cleanedText
        
        // **PAUSE voice transcription during TTS to prevent self-echo**
        // This is critical - the mic picks up TTS audio and creates feedback loop
        let wasRecording = voiceService.isRecording
        if wasRecording {
            await voiceService.stopRecording()
            print("🔇 Voice transcription paused during TTS")
        }
        
        // Clear any accumulated transcription to prevent stale text from being processed
        let previousTranscription = voiceService.transcriptionText
        voiceService.transcriptionText = ""
        
        // Small delay to let audio session transition smoothly
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Use enhanced TTS service with cleaned text for natural speech
        let rate: Float = quick ? 0.55 : 0.52
        ttsService.speak(cleanedText, language: "en-US", rate: rate)
        
        print("🎙️ TTS started, will resume listening after completion...")
        
        // Wait for TTS to finish completely
        while ttsService.isSpeaking && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 100_000_000) // Check every 0.1s
        }
        
        print("✅ TTS finished, resuming voice transcription")
        
        // Resume voice transcription after TTS completes
        // Give audio session time to reconfigure for recording
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        if wasRecording && isActive && !isPaused {
            await voiceService.startRecording()
            isListening = true
            print("🎤 Voice transcription resumed after TTS")
        }
        
        // Clear any residual echo that might have been picked up
        voiceService.transcriptionText = ""
        
        // Clear subtitle after a delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        if currentSubtitle == cleanedText {
            currentSubtitle = ""
        }
        
        print("✅ Ready for next user input (continuous listening active)")
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

// MARK: - Conversation Memory Models
struct ConversationTurn {
    let userInput: String
    let aiResponse: String
    let timestamp: Date
    let topic: String?  // Optional topic extraction for better context
    
    init(userInput: String, aiResponse: String, topic: String? = nil) {
        self.userInput = userInput
        self.aiResponse = aiResponse
        self.timestamp = Date()
        self.topic = topic
    }
}