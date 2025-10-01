//
//  VoiceTranscriptionService.swift
//  Agrisense
//
//  Created by Athar Reza on 30/09/25.
//

import Foundation
import Speech
#if canImport(AVFoundation)
import AVFoundation
#endif

// MARK: - Voice Transcription Service

@MainActor
class VoiceTranscriptionService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var transcriptionText = ""
    @Published var hasPermission = false
    @Published var errorMessage: String?
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
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
        
        guard !isRecording else { return }
        
        do {
            try await setupAudioSession()
            try startSpeechRecognition()
            isRecording = true
            isTranscribing = true
            transcriptionText = ""
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        
        // Keep transcribing flag until final result
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isTranscribing = false
        }
    }
    
    private func setupAudioSession() async throws {
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
        // macOS doesn't need audio session setup
    }
    
    private func startSpeechRecognition() throws {
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
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
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
                    self?.errorMessage = error.localizedDescription
                    self?.stopRecording()
                }
            }
        }
    }
    
    func resetTranscription() {
        transcriptionText = ""
        errorMessage = nil
    }
    
    deinit {
        audioEngine.stop()
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