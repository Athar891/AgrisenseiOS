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
    let maxSetupAttempts = 3
    private let sessionQueue = DispatchQueue(label: "com.agrisense.camera.session")
    private var isSessionConfigured = false
    private var isCheckingPermission = false
    
    override init() {
        super.init()
        // Check initial authorization status without requesting permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        isAuthorized = (status == .authorized)
        permissionDenied = (status == .denied || status == .restricted)
        
        // Set up notification observer for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleAppBecameActive() {
        // Re-check permissions when app becomes active (user might have changed them in Settings)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let wasAuthorized = isAuthorized
        
        Task { @MainActor in
            self.isAuthorized = (status == .authorized)
            self.permissionDenied = (status == .denied || status == .restricted)
            
            // If permission was just granted and camera is on, restart session
            if !wasAuthorized && self.isAuthorized && self.isCameraOn {
                if !self.isSessionConfigured {
                    self.setupCamera()
                }
                if !self.session.isRunning {
                    self.startSession()
                }
            }
        }
    }
    
    func checkCameraPermission() {
        // Prevent concurrent permission checks
        guard !isCheckingPermission else { return }
        isCheckingPermission = true
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            isAuthorized = true
            permissionDenied = false
            canRetry = false
            isCheckingPermission = false
            
            // Configure session if not already configured
            if !isSessionConfigured {
                setupCamera()
            }
            // Start session if camera is on
            if isCameraOn && !session.isRunning {
                startSession()
            }
            
        case .notDetermined:
            // Request camera permission
            Task { @MainActor in
                print("[CameraService] Requesting camera permission...")
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                
                print("[CameraService] Permission granted: \(granted)")
                self.isAuthorized = granted
                self.permissionDenied = !granted
                self.canRetry = !granted
                self.isCheckingPermission = false
                
                if granted {
                    // Configure and start session after permission granted
                    if !self.isSessionConfigured {
                        self.setupCamera()
                    }
                    if self.isCameraOn && !self.session.isRunning {
                        self.startSession()
                    }
                }
            }
            
        case .denied, .restricted:
            isAuthorized = false
            permissionDenied = true
            canRetry = true
            isCheckingPermission = false
            
            print("[CameraService] Camera permission denied or restricted")
            
        @unknown default:
            isAuthorized = false
            permissionDenied = true
            canRetry = true
            isCheckingPermission = false
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
            print("[CameraService] Cannot setup camera - not authorized")
            canRetry = true
            return 
        }
        
        // Avoid duplicate configuration
        guard !isSessionConfigured else {
            print("[CameraService] Session already configured")
            return
        }
        
        print("[CameraService] Setting up camera session...")
        
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
                
                // Success - clear error state and mark as configured
                Task { @MainActor in
                    self.error = nil
                    self.canRetry = false
                    self.setupAttempts = 0
                    self.isSessionConfigured = true
                    print("[CameraService] ✅ Camera session configured successfully")
                }
                
            } catch {
                Task { @MainActor in
                    self.error = error
                    self.canRetry = true
                    print("[CameraService] ❌ Camera setup error: \(error.localizedDescription)")
                }
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func startSession() {
        guard isAuthorized else { 
            print("[CameraService] Cannot start - not authorized")
            return 
        }
        
        guard !session.isRunning else {
            print("[CameraService] Session already running")
            Task { @MainActor in
                self.isSessionRunning = true
            }
            return
        }
        
        // Ensure session is configured before starting
        guard isSessionConfigured else {
            print("[CameraService] Session not configured, configuring now...")
            setupCamera()
            // Will start after configuration completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.startSession()
            }
            return
        }
        
        print("[CameraService] Starting camera session...")
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Verify session configuration before starting
            guard !self.session.inputs.isEmpty && !self.session.outputs.isEmpty else {
                print("[CameraService] Session not properly configured - inputs: \(self.session.inputs.count), outputs: \(self.session.outputs.count)")
                Task { @MainActor in
                    self.error = CameraError.sessionConfigurationFailed
                    self.canRetry = true
                    self.isSessionConfigured = false
                }
                return
            }
            
            print("[CameraService] Starting session.startRunning()...")
            self.session.startRunning()
            
            // Give it a moment to start
            Thread.sleep(forTimeInterval: 0.15)
            
            Task { @MainActor in
                self.isSessionRunning = self.session.isRunning
                if self.session.isRunning {
                    print("[CameraService] ✅ Session started successfully")
                    self.error = nil
                } else {
                    print("[CameraService] ❌ Session failed to start")
                    self.error = CameraError.sessionStartFailed
                    self.canRetry = true
                }
            }
        }
    }
    
    func stopSession() {
        guard session.isRunning else {
            print("[CameraService] Session not running, nothing to stop")
            return
        }
        
        print("[CameraService] Stopping camera session...")
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Gracefully stop the session
            self.session.stopRunning()
            
            Task { @MainActor in
                self.isSessionRunning = false
                self.error = nil
                print("[CameraService] ✅ Session stopped")
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
    
    // MARK: - Frame Capture for AI Analysis
    
    var onFrameCaptured: ((UIImage) -> Void)?
    private var lastFrameTime: Date = Date.distantPast
    private let frameInterval: TimeInterval = 1.0 // Capture 1 frame per second for AI
    
    func enableFrameCapture(callback: @escaping (UIImage) -> Void) {
        onFrameCaptured = callback
    }
    
    func disableFrameCapture() {
        onFrameCaptured = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraService: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Convert sample buffer to UIImage
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        
        // Throttle frame capture for AI analysis - do this in main actor context
        let now = Date()
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            guard now.timeIntervalSince(self.lastFrameTime) >= self.frameInterval else { return }
            self.lastFrameTime = now
            self.onFrameCaptured?(image)
        }
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
            if uiView.previewLayer.frame != uiView.bounds {
                uiView.previewLayer.frame = uiView.bounds
            }
            
            // Ensure session is connected
            if uiView.previewLayer.session !== uiView.session {
                uiView.previewLayer.session = uiView.session
            }
        }
    }
}

// MARK: - Camera Preview UIView
class CameraPreviewView: UIView {
    var session: AVCaptureSession? {
        didSet {
            setupSession()
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
        backgroundColor = .black
        
        // Ensure proper orientation
        DispatchQueue.main.async { [weak self] in
            if let connection = self?.previewLayer.connection, connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
    }
    
    private func setupSession() {
        guard let session = session else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Set the session
            self.previewLayer.session = session
            
            // Configure the preview layer
            self.previewLayer.videoGravity = .resizeAspectFill
            self.previewLayer.frame = self.bounds
            
            // Set video orientation
            if let connection = self.previewLayer.connection, connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            print("📹 Camera preview layer configured - session running: \\(session.isRunning)")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        
        // Ensure connection is properly oriented
        if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
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