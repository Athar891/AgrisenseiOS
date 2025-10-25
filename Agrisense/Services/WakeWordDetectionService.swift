//
//  WakeWordDetectionService.swift
//  Agrisense
//
//  Created by GitHub Copilot on 05/10/25.
//  Wake word detection for "Krishi AI" voice activation
//

import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - Wake Word Detection Service

@MainActor
class WakeWordDetectionService: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var wakeWordDetected = false
    @Published var hasPermission = false
    @Published var errorMessage: String?
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isStarting = false
    
    // Wake word configuration
    private let wakeWords = ["krishi ai", "krishi a i", "krishy ai", "krishi"]
    private let confidenceThreshold: Float = 0.6
    private var lastDetectionTime = Date.distantPast
    private let detectionCooldown: TimeInterval = 3.0 // Prevent rapid re-triggers
    
    // Callback when wake word is detected
    var onWakeWordDetected: (() -> Void)?
    
    override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    private func setupSpeechRecognizer() {
        // Use device locale for speech recognition
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
    }
    
    func requestPermissions() async {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        // Request microphone permission
        let audioStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        
        await MainActor.run {
            hasPermission = speechStatus == .authorized && audioStatus
            if !hasPermission {
                errorMessage = "Microphone and speech recognition permissions are required for wake word detection."
            }
        }
    }
    
    func startListening() async {
        guard hasPermission else {
            await requestPermissions()
            return
        }
        
        guard !isListening && !isStarting else { return }
        
        isStarting = true
        defer { isStarting = false }
        
        do {
            try await setupAudioSession()
            
            isListening = true
            wakeWordDetected = false
            errorMessage = nil
            
            try await startWakeWordRecognition()
            
            print("🎤 Wake word detection started - listening for 'Krishi AI'")
        } catch {
            isListening = false
            errorMessage = "Failed to start wake word detection: \(error.localizedDescription)"
            recognitionTask?.cancel()
            recognitionTask = nil
            recognitionRequest = nil
            
            if audioEngine.isRunning {
                audioEngine.inputNode.removeTap(onBus: 0)
                audioEngine.stop()
            }
        }
    }
    
    func stopListening() {
        guard isListening else { return }
        
        // Stop recognition first
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // Then clean up audio engine with proper sequencing
        if audioEngine.isRunning {
            // Remove tap before stopping engine
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            
            // Stop engine
            audioEngine.stop()
            
            // Reset audio engine to prevent pipe errors
            audioEngine.reset()
        }
        
        isListening = false
        wakeWordDetected = false
        
        // Release audio session
        AudioSessionManager.shared.releaseAudioSession(service: .wakeWordDetection)
        
        print("🎤 Wake word detection stopped")
    }
    
    private func setupAudioSession() async throws {
        try AudioSessionManager.shared.configureForRecording(service: .wakeWordDetection)
    }
    
    private func startWakeWordRecognition() async throws {
        // Cancel any previous recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw WakeWordError.recognitionUnavailable
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false // Use server for better accuracy
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            throw WakeWordError.audioEngineError
        }
        
        // Remove any existing tap
        inputNode.removeTap(onBus: 0)
        
        // Use nonisolated context for audio engine tap to prevent concurrency warnings
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak recognitionRequest] buffer, _ in
            // Validate buffer has valid data and size
            let bufferList = buffer.audioBufferList.pointee
            guard bufferList.mNumberBuffers > 0,
                  let audioBuffer = bufferList.mBuffers.mData,
                  bufferList.mBuffers.mDataByteSize > 0,
                  buffer.frameLength > 0 else {
                return
            }
            recognitionRequest?.append(buffer)
        }
        
        // Prepare and start audio engine with proper sequencing
        audioEngine.prepare()
        
        // Wait a brief moment for audio engine to fully prepare
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        
        // Allow audio buffers to stabilize
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let result = result {
                    let transcription = result.bestTranscription.formattedString.lowercased()
                    
                    // Check for wake word with cooldown
                    if self.containsWakeWord(transcription) && 
                       Date().timeIntervalSince(self.lastDetectionTime) > self.detectionCooldown {
                        
                        print("✅ Wake word detected: \(transcription)")
                        self.wakeWordDetected = true
                        self.lastDetectionTime = Date()
                        
                        // Trigger callback
                        self.onWakeWordDetected?()
                        
                        // Reset after a short delay to continue listening
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        self.wakeWordDetected = false
                    }
                }
                
                if let error = error {
                    // Filter out expected errors (cancellation, normal operation)
                    let nsError = error as NSError
                    let isCancellationError = nsError.code == 216 || // Speech recognition cancelled
                                             nsError.code == 203 || // Recognition unavailable
                                             error.localizedDescription.contains("cancel")
                    
                    if !isCancellationError && nsError.domain != "kAFAssistantErrorDomain" {
                        print("⚠️ Wake word recognition error: \(error.localizedDescription)")
                    }
                    
                    // Restart recognition on error (except permission errors)
                    if self.isListening && !self.isStarting {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
                        if self.isListening {
                            self.stopListening()
                            await self.startListening()
                        }
                    }
                }
            }
        }
    }
    
    private func containsWakeWord(_ text: String) -> Bool {
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for exact matches and variations
        for wakeWord in wakeWords {
            if normalizedText.contains(wakeWord) {
                return true
            }
        }
        
        // Check for close matches with Levenshtein distance
        return wakeWords.contains { wakeWord in
            levenshteinDistance(normalizedText, wakeWord) <= 2
        }
    }
    
    // Simple Levenshtein distance calculation for fuzzy matching
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let empty = [Int](repeating: 0, count: str2.count)
        var last = [Int](0...str2.count)
        
        for (i, char1) in str1.enumerated() {
            var cur = [i + 1] + empty
            for (j, char2) in str2.enumerated() {
                cur[j + 1] = char1 == char2 ? last[j] : min(last[j], last[j + 1], cur[j]) + 1
            }
            last = cur
        }
        return last.last ?? 0
    }
    
    deinit {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        recognitionRequest?.endAudio()
    }
}

// MARK: - Speech Recognizer Delegate

extension WakeWordDetectionService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available && isListening {
                errorMessage = "Speech recognition became unavailable"
            }
        }
    }
}

// MARK: - Wake Word Error Types

enum WakeWordError: LocalizedError {
    case recognitionUnavailable
    case audioEngineError
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .recognitionUnavailable:
            return "Speech recognition is not available"
        case .audioEngineError:
            return "Audio engine error"
        case .permissionDenied:
            return "Microphone permission denied"
        }
    }
}
