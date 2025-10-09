//
//  LiveAIInteractionView.swift
//  Agrisense
//
//  Created by AI Assistant on 03/10/25.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct LiveAIInteractionView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var liveAIService: LiveAIService
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showEndSessionAlert = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showPermissionDenied = false
    @State private var hasUserSpoken = false
    @State private var showCameraError = false
    
    init() {
        let apiKey = Secrets.geminiAPIKey
        _liveAIService = StateObject(wrappedValue: LiveAIService(geminiApiKey: apiKey))
    }
    
    var body: some View {
        ZStack {
            // Adaptive Background
            adaptiveBackground
            
            // Main Content Area
            VStack(spacing: 0) {
                // Top Navigation Bar
                topNavigationBar
                
                Spacer()
                
                // Central Content (Standby Animation or Camera Feed)
                centralContent
                
                Spacer()
                
                // Bottom Control Bar
                bottomControlBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            setupLiveSession()
        }
        .onDisappear {
            liveAIService.endSession()
            cameraService.stopSession()
        }
        .alert(localizationManager.localizedString(for: "live_ai_end_session"), isPresented: $showEndSessionAlert) {
            Button(localizationManager.localizedString(for: "cancel"), role: .cancel) { }
            Button(localizationManager.localizedString(for: "live_ai_end_session"), role: .destructive) {
                endLiveSession()
            }
        } message: {
            Text(localizationManager.localizedString(for: "live_ai_end_session_confirmation"))
        }
        .alert("Camera Permission Required", isPresented: $showPermissionDenied) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Continue without Camera", role: .cancel) { }
        } message: {
            Text("AgriSense needs camera access to provide real-time crop analysis. You can enable it in Settings or continue with voice-only interaction.")
        }
        .sheet(isPresented: $showImagePicker) {
            LiveImagePicker(selectedImage: $selectedImage)
        }
        .alert("Screen Share Error", isPresented: $showCameraError) {
            Button("OK") { }
        } message: {
            Text(liveAIService.screenShareError ?? "Unknown error occurred")
        }
        .onChange(of: liveAIService.screenShareError) { _, error in
            showCameraError = error != nil
        }
        .onChange(of: cameraService.isCameraOn) { _, isCameraOn in
            if isCameraOn {
                // Enable frame capture for AI analysis
                cameraService.enableFrameCapture { [weak liveAIService] image in
                    guard let liveAIService = liveAIService else { return }
                    
                    // Only analyze frames if user asks a question about what they're seeing
                    let transcription = liveAIService.voiceService.transcriptionText.lowercased()
                    let cameraQueries = ["what do you see", "what's this", "identify", "what is", "tell me about", "look at", "analyze"]
                    
                    if cameraQueries.contains(where: { transcription.contains($0) }) && !liveAIService.isProcessing {
                        Task {
                            await liveAIService.processCameraFrame(image, userContext: transcription)
                        }
                    }
                }
            } else {
                cameraService.disableFrameCapture()
            }
        }
        .onChange(of: liveAIService.wakeWordService.wakeWordDetected) { _, detected in
            if detected {
                // Visual feedback for wake word detection
                print("✅ Wake word detected in view")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var adaptiveBackground: some View {
        (colorScheme == .dark ? Color.black : Color.white)
            .ignoresSafeArea()
    }
    
    private var topNavigationBar: some View {
        HStack {
            // Live status indicator
            liveStatusIndicator
            
            Spacer()
            
            // Subtitle toggle button with animation
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    liveAIService.toggleSubtitles()
                }
            }) {
                Image(systemName: liveAIService.subtitlesEnabled ? "captions.bubble.fill" : "captions.bubble")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(liveAIService.subtitlesEnabled ? .green : (colorScheme == .dark ? .white : .black))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.regularMaterial)
                    )
                    .scaleEffect(liveAIService.subtitlesEnabled ? 1.0 : 0.95)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: liveAIService.subtitlesEnabled)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var liveStatusIndicator: some View {
        HStack(spacing: 8) {
            LiveStatusIndicator(
                isActive: liveAIService.isActive && !liveAIService.isPaused,
                currentState: liveAIService.currentState,
                colorScheme: colorScheme
            )
            
            Text(statusText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
        )
    }
    
    private var statusText: String {
        switch liveAIService.currentState {
        case .standby:
            return localizationManager.localizedString(for: "live_ai_standby")
        case .listening:
            return localizationManager.localizedString(for: "live_ai_listening")
        case .thinking:
            return localizationManager.localizedString(for: "live_ai_thinking")
        case .responding:
            return localizationManager.localizedString(for: "live_ai_responding")
        case .paused:
            return localizationManager.localizedString(for: "live_ai_paused")
        }
    }
    
    private var centralContent: some View {
        Group {
            if cameraService.permissionDenied {
                // Camera permission denied message with retry options
                cameraPermissionDeniedView
            } else if cameraService.error != nil {
                // Camera error with retry option
                cameraErrorView
            } else if cameraService.isCameraOn && cameraService.isAuthorized {
                // Live camera feed
                CameraPreview(session: cameraService.session)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.3), Color.blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .padding(.horizontal, 20)
            } else {
                // Standby Animation (ChatGPT-style sphere)
                standbyAnimationView
            }
        }
    }
    
    private var cameraErrorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text(cameraService.error?.localizedDescription ?? "Camera setup failed")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("Try toggling the camera off and on, or check if another app is using it.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if cameraService.canRetry {
                Button(action: {
                    cameraService.retrySetup()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry (\(cameraService.setupAttempts)/\(cameraService.maxSetupAttempts))")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            } else {
                Text("Continuing with voice-only interaction")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }
    
    private var standbyAnimationView: some View {
        VStack(spacing: 30) {
            // Lottie-Based Animated Orb
            LottieOrbAnimation(
                currentState: liveAIService.currentState,
                audioLevel: liveAIService.audioLevel,
                isListening: liveAIService.currentState == .listening
            )
        }
    }
    
    private var cameraPermissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(localizationManager.localizedString(for: "live_ai_camera_permission_denied"))
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                if cameraService.canRetry {
                    Button(action: {
                        cameraService.retrySetup()
                    }) {
                        Text("Retry Camera Setup")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                
                Button(action: {
                    // Open Settings app
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    Text("Open Settings")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Text("Continue without camera for voice-only interaction")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }
    
    
    private var bottomControlBar: some View {
        HStack(spacing: 20) {
            // Video toggle button
            ControlButton(
                icon: cameraService.isCameraOn ? "video.fill" : "video.slash.fill",
                isActive: cameraService.isCameraOn && cameraService.isAuthorized,
                colorScheme: colorScheme,
                action: {
                    if cameraService.permissionDenied {
                        // Show permission denied alert
                        showPermissionDenied = true
                    } else {
                        cameraService.toggleCamera()
                    }
                }
            )
            
            // Screen share button
            ControlButton(
                icon: "shareplay",
                isActive: true,
                colorScheme: colorScheme,
                action: {
                    requestScreenSharePermission()
                }
            )
            
            // Pause/Resume button
            ControlButton(
                icon: liveAIService.isPaused ? "play.fill" : "pause.fill",
                isActive: !liveAIService.isPaused,
                colorScheme: colorScheme,
                action: {
                    if liveAIService.isPaused {
                        liveAIService.resumeSession()
                    } else {
                        liveAIService.pauseSession()
                    }
                }
            )
            
            // End session button (red)
            Button(action: {
                showEndSessionAlert = true
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.red)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(
                            LinearGradient(
                                colors: colorScheme == .dark ? 
                                    [Color.blue.opacity(0.3), Color.clear] :
                                    [Color.gray.opacity(0.2), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Methods
    
    private func setupLiveSession() {
        // Request all necessary permissions
        Task {
            // Request voice permissions
            await liveAIService.voiceService.requestPermissions()
            
            // Request wake word permissions
            await liveAIService.wakeWordService.requestPermissions()
            
            // Check camera permission status (don't request yet, just check)
            await MainActor.run {
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                cameraService.isAuthorized = (status == .authorized)
                cameraService.permissionDenied = (status == .denied || status == .restricted)
                
                // If already authorized, pre-configure the camera session
                if cameraService.isAuthorized {
                    print("[LiveAI] Camera already authorized, setting up session...")
                    cameraService.setupCamera()
                }
            }
            
            // Start the live session
            liveAIService.startLiveSession()
            
            // Auto-greet the user as specified
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            await liveAIService.performAutoGreeting()
        }
    }
    
    private func requestScreenSharePermission() {
        Task {
            await liveAIService.requestScreenShare()
        }
    }
    
    private func endLiveSession() {
        liveAIService.endSession()
        cameraService.stopSession()
        dismiss()
    }
}

// MARK: - Live Status Indicator
struct LiveStatusIndicator: View {
    let isActive: Bool
    let currentState: LiveAIState
    let colorScheme: ColorScheme
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Animated status icon based on current state
            Image(systemName: statusIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(statusColor)
                .scaleEffect(shouldAnimate ? (isAnimating ? 1.2 : 1.0) : 1.0)
                .animation(
                    shouldAnimate ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .none,
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
        }
    }
    
    private var statusIcon: String {
        switch currentState {
        case .standby:
            return "circle.fill"
        case .listening:
            return "waveform"
        case .thinking:
            return "brain.head.profile"
        case .responding:
            return "speaker.wave.2.fill"
        case .paused:
            return "pause.fill"
        }
    }
    
    private var statusColor: Color {
        switch currentState {
        case .standby:
            return .green
        case .listening:
            return .blue
        case .thinking:
            return .orange
        case .responding:
            return .purple
        case .paused:
            return .gray
        }
    }
    
    private var shouldAnimate: Bool {
        currentState == .listening || currentState == .thinking || currentState == .responding
    }
}

// MARK: - Control Button
struct ControlButton: View {
    let icon: String
    let isActive: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(buttonForegroundColor)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(buttonBackgroundColor)
                )
        }
        .scaleEffect(isActive ? 1.0 : 0.9)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
    
    private var buttonForegroundColor: Color {
        if isActive {
            return colorScheme == .dark ? .white : .black
        } else {
            return .gray
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isActive {
            return colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Live Image Picker
struct LiveImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: LiveImagePicker
        
        init(_ parent: LiveImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    LiveAIInteractionView()
        .environmentObject(LocalizationManager.shared)
}