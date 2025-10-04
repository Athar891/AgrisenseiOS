//
//  CameraService.swift
//  Agrisense
//
//  Created by AI Assistant on 04/10/25.
//  Enhanced camera service with robust error handling and device support
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Camera Service
@MainActor
class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var session = AVCaptureSession()
    @Published var isCameraOn = false  // Start with camera OFF by default
    @Published var error: Error?
    @Published var permissionDenied = false
    @Published var canRetry = false
    @Published var setupAttempts = 0
    @Published var isSessionRunning = false
    
    private var videoOutput: AVCaptureVideoDataOutput?
    private var videoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private let maxSetupAttempts = 3
    private let sessionQueue = DispatchQueue(label: "com.agrisense.camera.session")
    
    override init() {
        super.init()
        // Don't check permission immediately - wait for explicit user action
        // This prevents premature permission requests
    }
    
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            isAuthorized = true
            permissionDenied = false
            canRetry = false
            setupCamera()
            
        case .notDetermined:
            // Request camera permission
            Task { @MainActor in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                self.isAuthorized = granted
                self.permissionDenied = !granted
                self.canRetry = !granted
                
                if granted {
                    self.setupCamera()
                }
            }
            
        case .denied, .restricted:
            isAuthorized = false
            permissionDenied = true
            canRetry = true
            
        @unknown default:
            isAuthorized = false
            permissionDenied = true
            canRetry = true
        }
    }
    
    func retrySetup() {
        guard canRetry && setupAttempts < maxSetupAttempts else { return }
        
        setupAttempts += 1
        error = nil
        
        // Re-check permissions
        checkCameraPermission()
        
        // If still having issues after max attempts, provide fallback
        if setupAttempts >= maxSetupAttempts && !isAuthorized {
            canRetry = false
            // Enable text/voice-only mode
        }
    }
    
    func setupCamera() {
        guard isAuthorized else { 
            canRetry = true
            return 
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Clear any existing inputs/outputs
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            
            // Configure session for high quality
            if self.session.canSetSessionPreset(.high) {
                self.session.sessionPreset = .high
            } else {
                self.session.sessionPreset = .medium
            }
            
            // Set up video device (back camera)
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                Task { @MainActor in
                    self.error = CameraError.deviceNotFound
                    self.canRetry = true
                }
                self.session.commitConfiguration()
                return
            }
            
            self.videoDevice = videoDevice
            
            do {
                // Configure device for optimal performance
                try videoDevice.lockForConfiguration()
                
                // Set autofocus if available
                if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                    videoDevice.focusMode = .continuousAutoFocus
                }
                
                // Set exposure mode if available
                if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                    videoDevice.exposureMode = .continuousAutoExposure
                }
                
                videoDevice.unlockForConfiguration()
                
                // Add video input
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.session.canAddInput(videoInput) {
                    self.session.addInput(videoInput)
                    self.videoInput = videoInput
                } else {
                    throw CameraError.inputCreationFailed
                }
                
                // Add video output
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.agrisense.camera.video"))
                
                if self.session.canAddOutput(videoOutput) {
                    self.session.addOutput(videoOutput)
                    self.videoOutput = videoOutput
                    
                    // Set video orientation
                    if let connection = videoOutput.connection(with: .video) {
                        if connection.isVideoOrientationSupported {
                            connection.videoOrientation = .portrait
                        }
                        if connection.isVideoMirroringSupported {
                            connection.isVideoMirrored = false
                        }
                    }
                } else {
                    throw CameraError.outputCreationFailed
                }
                
                // Success - clear error state
                Task { @MainActor in
                    self.error = nil
                    self.canRetry = false
                    self.setupAttempts = 0
                }
                
            } catch {
                Task { @MainActor in
                    self.error = error
                    self.canRetry = true
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func startSession() {
        guard isAuthorized && !session.isRunning else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Verify session configuration before starting
            guard !self.session.inputs.isEmpty && !self.session.outputs.isEmpty else {
                Task { @MainActor in
                    self.error = CameraError.sessionConfigurationFailed
                    self.canRetry = true
                }
                return
            }
            
            self.session.startRunning()
            
            Task { @MainActor in
                self.isSessionRunning = self.session.isRunning
                if !self.session.isRunning {
                    self.error = CameraError.sessionStartFailed
                    self.canRetry = true
                }
            }
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Gracefully stop the session
            self.session.stopRunning()
            
            Task { @MainActor in
                self.isSessionRunning = false
                self.error = nil
            }
        }
    }
    
    func toggleCamera() {
        isCameraOn.toggle()
        
        if isCameraOn {
            // Request camera permission if not already granted
            if !isAuthorized {
                checkCameraPermission()
            } else {
                startSession()
            }
        } else {
            stopSession()
        }
    }
    
    func switchCamera() {
        guard let currentInput = videoInput else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.removeInput(currentInput)
            
            let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
            
            guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
                self.session.addInput(currentInput) // Re-add the original input if switching fails
                self.session.commitConfiguration()
                return
            }
            
            self.session.addInput(newInput)
            
            Task { @MainActor in
                self.videoInput = newInput
                self.videoDevice = newDevice
            }
            
            // Update video orientation for the new connection
            if let videoOutput = self.videoOutput,
               let connection = videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = (newPosition == .front)
                }
            }
            
            self.session.commitConfiguration()
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraService: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // This method will be called for each frame captured
        // We can process the video frames here for AI analysis
        // For now, we'll just let the preview layer handle the display
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Update the preview layer frame when view bounds change
        DispatchQueue.main.async {
            uiView.previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Camera Preview UIView
class CameraPreviewView: UIView {
    var session: AVCaptureSession? {
        didSet {
            if let session = session {
                previewLayer.session = session
            }
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }
    
    private func setupPreviewLayer() {
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        backgroundColor = .black
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

// MARK: - Camera Errors
enum CameraError: Error, LocalizedError {
    case deviceNotFound
    case inputCreationFailed
    case outputCreationFailed
    case authorizationDenied
    case sessionConfigurationFailed
    case sessionStartFailed
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Camera device not found"
        case .inputCreationFailed:
            return "Failed to create camera input"
        case .outputCreationFailed:
            return "Failed to create camera output"
        case .authorizationDenied:
            return "Camera access denied"
        case .sessionConfigurationFailed:
            return "Camera session not properly configured"
        case .sessionStartFailed:
            return "Failed to start camera session"
        }
    }
}