//
//  AudioSessionManager.swift
//  Agrisense
//
//  Created by GitHub Copilot on 06/10/25.
//  Centralized audio session manager to prevent conflicts between TTS, Voice, and Wake Word services
//

import Foundation
import AVFoundation

/// Centralized audio session manager to coordinate multiple audio services
/// Prevents conflicts between TTS, voice transcription, and wake word detection
@MainActor
class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    private var activeServices: Set<AudioServiceType> = []
    private let audioSession = AVAudioSession.sharedInstance()
    private var lastConfigurationTime: Date = .distantPast
    private let configurationDebounceInterval: TimeInterval = 0.1 // 100ms debounce
    private var pendingConfiguration: (() -> Void)?
    
    enum AudioServiceType: Hashable {
        case tts
        case voiceTranscription
        case wakeWordDetection
    }
    
    private init() {}
    
    /// Configure audio session for recording (voice/wake word) with debouncing
    func configureForRecording(service: AudioServiceType) throws {
        activeServices.insert(service)
        
        // Debounce rapid configuration changes
        let timeSinceLastConfig = Date().timeIntervalSince(lastConfigurationTime)
        if timeSinceLastConfig < configurationDebounceInterval {
            print("[AudioSessionManager] Debouncing config for \(service) (\(String(format: "%.0f", timeSinceLastConfig * 1000))ms since last)")
            return
        }
        
        do {
            // If TTS is active, use playAndRecord with speaker; otherwise just record
            if activeServices.contains(.tts) {
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetooth, .defaultToSpeaker])
            } else {
                // For wake word + voice, use playAndRecord for compatibility
                try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetooth])
            }
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            lastConfigurationTime = Date()
            print("[AudioSessionManager] Configured for recording: \(service)")
        } catch {
            print("[AudioSessionManager] Error configuring for recording: \(error)")
            throw error
        }
    }
    
    /// Configure audio session for playback (TTS) with debouncing
    func configureForPlayback(service: AudioServiceType) throws {
        activeServices.insert(service)
        
        // Debounce rapid configuration changes
        let timeSinceLastConfig = Date().timeIntervalSince(lastConfigurationTime)
        if timeSinceLastConfig < configurationDebounceInterval {
            print("[AudioSessionManager] Debouncing playback config for \(service) (\(String(format: "%.0f", timeSinceLastConfig * 1000))ms since last)")
            return
        }
        
        do {
            // If recording services are active, use playAndRecord
            if activeServices.contains(.voiceTranscription) || activeServices.contains(.wakeWordDetection) {
                try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .allowBluetooth, .defaultToSpeaker])
            } else {
                // For TTS-only playback, defaultToSpeaker should route to the speaker
                try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            }
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            lastConfigurationTime = Date()
            print("[AudioSessionManager] Configured for playback: \(service)")
        } catch {
            print("[AudioSessionManager] Error configuring for playback: \(error)")
            throw error
        }
    }
    
    /// Release audio session when service stops
    func releaseAudioSession(service: AudioServiceType) {
        activeServices.remove(service)
        
        // If no services are active, deactivate session
        if activeServices.isEmpty {
            do {
                try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                print("[AudioSessionManager] Audio session deactivated")
            } catch {
                print("[AudioSessionManager] Error deactivating: \(error)")
            }
        } else {
            // Only log, no immediate reconfiguration needed
            // Next service request will configure appropriately
            print("[AudioSessionManager] Services still active: \(activeServices) - will reconfigure on next request")
        }
    }
    
    /// Check if audio session is available for use
    func isAvailable() -> Bool {
        return !audioSession.isOtherAudioPlaying
    }
}
