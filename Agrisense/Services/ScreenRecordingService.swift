//
//  ScreenRecordingService.swift
//  Agrisense
//
//  Created by AI Assistant on 03/10/25.
//

import SwiftUI
import ReplayKit
import AVFoundation

// MARK: - Screen Recording Service
@MainActor
class ScreenRecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isAvailable = false
    @Published var error: Error?
    @Published var hasPermission = false
    
    private let screenRecorder = RPScreenRecorder.shared()
    private weak var delegate: ScreenRecordingDelegate?
    
    override init() {
        super.init()
        checkAvailability()
    }
    
    func setDelegate(_ delegate: ScreenRecordingDelegate) {
        self.delegate = delegate
    }
    
    private func checkAvailability() {
        isAvailable = screenRecorder.isAvailable
    }
    
    func requestPermission() async throws {
        guard isAvailable else {
            throw ScreenRecordingError.notAvailable
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            screenRecorder.startCapture(handler: { [weak self] sampleBuffer, bufferType, error in
                // Handle frames during recording
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                Task { @MainActor in
                    self?.delegate?.didReceiveScreenFrame(sampleBuffer, bufferType: bufferType)
                }
                
            }, completionHandler: { [weak self] error in
                Task { @MainActor in
                    if let error = error {
                        self?.error = error
                        continuation.resume(throwing: error)
                    } else {
                        self?.isRecording = true
                        self?.hasPermission = true
                        continuation.resume()
                    }
                }
            })
        }
    }
    
    func startRecording() async throws {
        // Check if already recording - prevents "already active with another session" error
        guard !isRecording else { 
            print("[ScreenRecording] Already recording, ignoring start request")
            return 
        }
        
        // Check if recorder is already capturing
        if screenRecorder.isRecording {
            print("[ScreenRecording] Screen recorder already active, stopping first")
            await stopRecording()
            // Wait a moment for cleanup
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        
        if !hasPermission {
            try await requestPermission()
        } else {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                screenRecorder.startCapture(handler: { [weak self] sampleBuffer, bufferType, error in
                    if let error = error {
                        print("[ScreenRecording] Capture error: \(error)")
                        Task { @MainActor in
                            self?.error = error
                        }
                        return
                    }
                    
                    Task { @MainActor in
                        self?.delegate?.didReceiveScreenFrame(sampleBuffer, bufferType: bufferType)
                    }
                    
                }, completionHandler: { [weak self] error in
                    Task { @MainActor in
                        if let error = error {
                            print("[ScreenRecording] Start error: \(error)")
                            self?.error = error
                            continuation.resume(throwing: error)
                        } else {
                            print("[ScreenRecording] Started successfully")
                            self?.isRecording = true
                            continuation.resume()
                        }
                    }
                })
            }
        }
    }
    
    func stopRecording() async {
        guard isRecording else { 
            print("[ScreenRecording] Not recording, ignoring stop request")
            return 
        }
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            screenRecorder.stopCapture { [weak self] error in
                Task { @MainActor in
                    self?.isRecording = false
                    if let error = error {
                        print("[ScreenRecording] Stop error: \(error)")
                        self?.error = error
                    } else {
                        print("[ScreenRecording] Stopped successfully")
                    }
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Screen Recording Delegate
protocol ScreenRecordingDelegate: AnyObject {
    func didReceiveScreenFrame(_ sampleBuffer: CMSampleBuffer, bufferType: RPSampleBufferType)
}

// MARK: - Screen Recording Errors
enum ScreenRecordingError: Error, LocalizedError {
    case notAvailable
    case permissionDenied
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Screen recording is not available on this device"
        case .permissionDenied:
            return "Screen recording permission was denied"
        case .recordingFailed:
            return "Failed to start screen recording"
        }
    }
}