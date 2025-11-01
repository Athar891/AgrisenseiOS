//
//  VoiceTranscriptionService.swift
//  Agrisense
//
//  Created by Athar Reza on 30/09/25.
//

import Foundation
import Speech
import AVFoundation

// MARK: - Voice Transcription Service

@MainActor
class VoiceTranscriptionService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcriptionText = ""
    @Published var hasPermission = false
    @Published var errorMessage: String?
    @Published var isPaused = false
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    // Prevent concurrent start attempts
    private var isStarting = false
    
    override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    private func setupSpeechRecognizer() {
        // Use device locale for speech recognition
        speechRecognizer = SFSpeechRecognizer()
        speechRecognizer?.delegate = self
    }
    
    func requestPermissions() async {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        // Request microphone permission (iOS only)
        var audioStatus = false
        #if os(iOS)
        audioStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        #else
        // For macOS, assume audio permission is granted
        audioStatus = true
        #endif
        
        await MainActor.run {
            hasPermission = speechStatus == .authorized && audioStatus
            if !hasPermission {
                errorMessage = "Microphone and speech recognition permissions are required for voice input."
            }
        }
    }
    
    func startRecording() async {
        guard hasPermission else {
            await requestPermissions()
            return
        }

        // Prevent re-entrancy if a start is already in progress or recording is active
        guard !isRecording && !isStarting else { return }

        isStarting = true
        defer { isStarting = false }

        do {
            try await setupAudioSession()

            // Ensure we mark recording early to avoid double-start when user taps quickly.
            // If start fails, we'll reset this flag in the catch block.
            isRecording = true
            isTranscribing = true
            transcriptionText = ""
            errorMessage = nil

            try await startSpeechRecognition()
        } catch {
            // Reset state on failure
            isRecording = false
            isTranscribing = false
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            // Clean-up any partially configured resources
            recognitionTask?.cancel()
            recognitionTask = nil
            recognitionRequest = nil
            audioEngine.stop()
        }
    }
    
    /// Pause recording temporarily (for TTS playback) without full cleanup
    func pauseRecording() {
        guard isRecording && !isPaused else { return }
        
        isPaused = true
        
        // Pause audio engine but keep recognition task alive
        if audioEngine.isRunning {
            audioEngine.pause()
        }
        
        print("[VoiceTranscription] ⏸️ Paused (TTS playing)")
    }
    
    /// Resume recording after TTS completes
    func resumeRecording() async {
        guard isRecording && isPaused else { return }
        
        do {
            // Restart audio engine
            if !audioEngine.isRunning {
                try audioEngine.start()
                // Allow audio to stabilize
                try await Task.sleep(nanoseconds: 150_000_000) // 150ms for better stability
            }
            
            isPaused = false
            print("[VoiceTranscription] ▶️ Resumed - ready for continuous listening")
        } catch {
            print("[VoiceTranscription] ❌ Failed to resume: \(error)")
            // Try to restart recording completely if resume fails
            isPaused = false
            await restartRecording()
        }
    }
    
    /// Restart recording if pause/resume fails
    private func restartRecording() async {
        print("[VoiceTranscription] 🔄 Restarting recording for continuous listening")
        stopRecording()
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms delay
        await startRecording()
    }
    
    func stopRecording() {
        guard isRecording else { return }

        // End and cancel recognition first
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        // Stop audio engine with proper cleanup
        if audioEngine.isRunning {
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            audioEngine.reset()
        }

        isRecording = false
        isPaused = false
        
        // Release audio session
        #if os(iOS)
        AudioSessionManager.shared.releaseAudioSession(service: .voiceTranscription)
        #endif

        // Keep transcribing flag until final result; clear shortly after
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isTranscribing = false
        }
    }
    
    private func setupAudioSession() async throws {
        #if os(iOS)
        try AudioSessionManager.shared.configureForRecording(service: .voiceTranscription)
        #endif
        // macOS doesn't need audio session setup
    }
    
    private func startSpeechRecognition() async throws {
        // Cancel any previous recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.recognitionUnavailable
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Validate recording format before proceeding
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            throw VoiceError.audioEngineError
        }

        // Remove any existing tap before installing a new one to avoid multiple taps crash
        inputNode.removeTap(onBus: 0)

        // Use nonisolated context for audio engine tap to prevent concurrency warnings
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self, weak recognitionRequest] buffer, _ in
            // Don't process audio when paused (TTS is speaking)
            guard let self = self, !self.isPaused else { return }
            
            // Validate buffer has valid data, size, and frames
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
        
        // Allow audio buffers to stabilize before starting recognition
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcriptionText = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        self?.isTranscribing = false
                    }
                }
                
                if let error = error {
                    // Filter out expected errors (cancellation)
                    let nsError = error as NSError
                    let isCancellationError = nsError.code == 216 || // Speech recognition cancelled
                                             nsError.code == 203 || // Recognition unavailable
                                             error.localizedDescription.contains("cancel")
                    
                    if !isCancellationError {
                        self?.errorMessage = error.localizedDescription
                        // Stop and clean up on unexpected errors
                        self?.stopRecording()
                    }
                }
            }
        }
    }
    
    func resetTranscription() {
        transcriptionText = ""
        errorMessage = nil
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

extension VoiceTranscriptionService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle availability changes if needed
    }
}

// MARK: - Voice Error Types

enum VoiceError: LocalizedError {
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