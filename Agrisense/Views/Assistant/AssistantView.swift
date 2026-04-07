//
//  AssistantView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI
import Vision
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

// Extension to handle keyboard dismissal
extension View {
    func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// Basic message model for the assistant
struct SimpleMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}

struct AssistantView: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var messageText = ""
    @State private var messages: [SimpleMessage] = []
    @State private var showingQuickActions = false
    @State private var isWaitingForResponse = false
    @FocusState private var isTextFieldFocused: Bool
    @StateObject private var voiceService = VoiceTranscriptionService()
    @State private var isListening = false
    @State private var silenceTimer: Timer?
    @State private var lastTranscriptionLength = 0
    @State private var geminiService: GeminiAIService?
    @State private var showDocumentPicker = false
    @State private var attachedDocuments: [AttachedDocument] = []
    @State private var showLiveInteraction = false
    
    // Typing effect state variables
    @State private var displayedMessages: [UUID: String] = [:]
    @State private var typingTimers: [UUID: Timer] = [:]
    @State private var typingIndex: [UUID: Int] = [:]
    
    // Query execution control
    @State private var currentQueryTask: Task<Void, Never>?
    @State private var isQueryCancelled = false
    @State private var isTypingResponse = false
    @State private var currentTypingMessageId: UUID?
    
    // Initial message support
    let initialMessage: String?
    @State private var hasProcessedInitialMessage = false
    
    init(initialMessage: String? = nil) {
        self.initialMessage = initialMessage
        
        // Initialize Gemini AI service with API key from .env or environment
        let apiKey = Secrets.geminiAPIKey
        if apiKey != "YOUR_GEMINI_API_KEY_HERE" && !apiKey.isEmpty {
            _geminiService = State(initialValue: GeminiAIService(apiKey: apiKey))
            print("[AssistantView] Gemini AI service initialized")
        } else {
            print("[AssistantView] Gemini API key is not configured")
        }
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    // Navigation Bar with New Chat button
                    if !messages.isEmpty {
                        HStack {
                            Spacer()
                            Button(action: startNewChat) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.green)
                                    .frame(width: 36, height: 36)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }
                    
                    // Chat Messages or Centered Welcome
                    Group {
                        if messages.isEmpty {
                            // Centered welcome screen - minimalist design
                            Spacer()
                            WelcomeMessage()
                            Spacer()
                        } else {
                            // Chat messages view
                            ScrollViewReader { proxy in
                                ScrollView {
                                    LazyVStack(spacing: 16) {
                                        // Chat Messages
                                        ForEach(messages) { message in
                                            ChatBubble(message: message, displayedContent: displayedMessages[message.id] ?? "")
                                        }
                                        
                                        // Loading indicator
                                        if isWaitingForResponse {
                                            AIThinkingIndicator()
                                        }
                                    }
                                    .padding()
                                }
                                .background(Color(.systemBackground))
                                .onTapGesture {
                                    // Dismiss keyboard when tapping in chat area
                                    dismissKeyboard()
                                    isTextFieldFocused = false
                                }
                                .onChange(of: messages.count) { _, _ in
                                    if let lastMessage = messages.last {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .animation(.none, value: messages.isEmpty)
                    
                    // Quick Actions
                    if showingQuickActions {
                        QuickActionsView { action in
                            sendMessage(action)
                            showingQuickActions = false
                        }
                    }
                    
                    // Input Area
                    MessageInputView(
                        text: $messageText,
                        isTextFieldFocused: $isTextFieldFocused,
                        isListening: isListening,
                        isQueryInProgress: isWaitingForResponse || isTypingResponse,
                        attachedDocuments: $attachedDocuments,
                        onSend: sendMessage,
                        onQuickActions: { showingQuickActions.toggle() },
                        onAttachment: { showDocumentPicker = true },
                        onVoiceRecord: toggleVoiceRecording,
                        onLiveInteraction: { showLiveInteraction = true },
                        onStopQuery: stopCurrentQuery
                    )
                }
                .background(Color(.systemBackground))
                .navigationBarHidden(true)
                .sheet(isPresented: $showDocumentPicker) {
                    DocumentPicker(attachedDocuments: $attachedDocuments)
                }
                .fullScreenCover(isPresented: $showLiveInteraction) {
                    LiveAIInteractionView()
                        .environmentObject(localizationManager)
                }
                .onTapGesture {
                    // Dismiss keyboard when tapping outside text field
                    dismissKeyboard()
                    isTextFieldFocused = false
                }
                .onAppear {
                    // Process initial message if provided
                    if let initialMessage = initialMessage, !hasProcessedInitialMessage {
                        hasProcessedInitialMessage = true
                        // Small delay to ensure view is fully loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            sendMessage(initialMessage)
                        }
                    }
                }
                .onDisappear {
                    cleanupTransientState()
                }
            }
            
            // Listening Overlay - Floats above everything with transparent background
            if isListening {
                Color.clear
                    .ignoresSafeArea()
                    .overlay(
                        CircularMicListeningOverlay()
                    )
                    .transition(.opacity)
                    .onTapGesture {
                        stopListening()
                    }
            }
        }
    }
    
    private func startNewChat() {
        // Clear all chat data
        messages.removeAll()
        displayedMessages.removeAll()
        cleanupTransientState()
        
        // Reset other states
        messageText = ""
        isWaitingForResponse = false
        showingQuickActions = false
        
        // Dismiss keyboard
        dismissKeyboard()
        isTextFieldFocused = false
    }

    private func cleanupTransientState() {
        // Cancel pending query execution and typing effects.
        currentQueryTask?.cancel()
        currentQueryTask = nil

        silenceTimer?.invalidate()
        silenceTimer = nil

        for timer in typingTimers.values {
            timer.invalidate()
        }
        typingTimers.removeAll()
        typingIndex.removeAll()
        currentTypingMessageId = nil
        isTypingResponse = false
    }
    
    private func startTypingEffect(for message: SimpleMessage) {
        // Initialize displayed content as empty
        displayedMessages[message.id] = ""
        typingIndex[message.id] = 0
        
        // Track that we're typing a response
        isTypingResponse = true
        currentTypingMessageId = message.id
        
        // Create timer for typing effect
        let timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [self] timer in
            guard let currentIndex = typingIndex[message.id] else {
                timer.invalidate()
                isTypingResponse = false
                currentTypingMessageId = nil
                return
            }
            
            if currentIndex < message.content.count {
                let index = message.content.index(message.content.startIndex, offsetBy: currentIndex)
                let nextIndex = message.content.index(after: index)
                displayedMessages[message.id] = String(message.content[..<nextIndex])
                typingIndex[message.id] = currentIndex + 1
            } else {
                // Typing complete
                timer.invalidate()
                typingTimers.removeValue(forKey: message.id)
                typingIndex.removeValue(forKey: message.id)
                displayedMessages[message.id] = message.content
                isTypingResponse = false
                currentTypingMessageId = nil
            }
        }
        
        typingTimers[message.id] = timer
    }
    
    private func stopCurrentQuery() {
        // Cancel the current query task
        currentQueryTask?.cancel()
        currentQueryTask = nil
        isQueryCancelled = true
        isWaitingForResponse = false
        
        // Stop any ongoing typing effect and show full content immediately
        if let typingMessageId = currentTypingMessageId {
            if let timer = typingTimers[typingMessageId] {
                timer.invalidate()
                typingTimers.removeValue(forKey: typingMessageId)
            }
            // Show the full message content immediately
            if let messageIndex = messages.firstIndex(where: { $0.id == typingMessageId }) {
                displayedMessages[typingMessageId] = messages[messageIndex].content
            }
            typingIndex.removeValue(forKey: typingMessageId)
            currentTypingMessageId = nil
        }
        isTypingResponse = false
        
        // Add a system message indicating the query was stopped
        let stoppedMessage = SimpleMessage(
            content: localizationManager.localizedString(for: "assistant_query_stopped"),
            isUser: false
        )
        messages.append(stoppedMessage)
        displayedMessages[stoppedMessage.id] = stoppedMessage.content
    }
    
    private func sendMessage(_ text: String) {
        // Prevent multiple simultaneous queries
        guard !isWaitingForResponse else { return }
        
        let userMessage = SimpleMessage(content: text, isUser: true)
        
        // Disable animations when adding first message
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            messages.append(userMessage)
        }
        
        messageText = ""
        isWaitingForResponse = true
        isQueryCancelled = false
        
        // Dismiss keyboard after sending message
        dismissKeyboard()
        isTextFieldFocused = false
        
        // Call Gemini AI service with cancellation support
        currentQueryTask = Task {
            do {
                // Check for cancellation before proceeding
                guard !Task.isCancelled else {
                    return
                }
                
                guard let service = geminiService else {
                    print("[AssistantView] ❌ GeminiService is nil - API key not configured")
                    // Fallback if service is not initialized
                    let fallbackResponse = SimpleMessage(
                        content: localizationManager.localizedString(for: "assistant_missing_api_key"),
                        isUser: false
                    )
                    messages.append(fallbackResponse)
                    startTypingEffect(for: fallbackResponse)
                    isWaitingForResponse = false
                    currentQueryTask = nil
                    return
                }
                
                print("[AssistantView] 📤 Sending message: \(text.prefix(50))...")
                let context = AIContext.current()
                let response = try await service.sendMessage(text, context: context)
                
                // Check for cancellation after receiving response
                guard !Task.isCancelled else {
                    return
                }
                
                print("[AssistantView] ✅ Received response: \(response.content.prefix(50))...")
                
                let aiResponse = SimpleMessage(
                    content: response.content,
                    isUser: false
                )
                messages.append(aiResponse)
                startTypingEffect(for: aiResponse)
                isWaitingForResponse = false
                currentQueryTask = nil
            } catch let error as AIError {
                // Don't show error if query was cancelled
                guard !Task.isCancelled else {
                    return
                }
                
                print("[AssistantView] ❌ AIError occurred: \(error)")
                print("[AssistantView] Error description: \(error.errorDescription ?? "unknown")")
                
                // Provide more specific error messages
                let errorContent: String
                switch error {
                case .rateLimitExceeded:
                    errorContent = "I'm currently experiencing high demand. All available AI models are temporarily rate-limited. Please wait a few moments and try again."
                case .serviceUnavailable:
                    errorContent = "I'm having trouble connecting to my AI service. This might be due to high demand or network issues. Please try again in a moment."
                case .invalidResponse:
                    errorContent = "I received an unexpected response. Please try rephrasing your question."
                case .timeout:
                    errorContent = "The request took too long. Please try again."
                case .networkError(let networkError):
                    errorContent = "Network error: \(networkError.localizedDescription). Please check your connection."
                default:
                    let errorTemplate = localizationManager.localizedString(for: "assistant_generic_error")
                    errorContent = String(format: errorTemplate, error.errorDescription ?? "Unknown error")
                }
                
                let errorMessage = SimpleMessage(
                    content: errorContent,
                    isUser: false
                )
                messages.append(errorMessage)
                startTypingEffect(for: errorMessage)
                isWaitingForResponse = false
                currentQueryTask = nil
            } catch {
                // Don't show error if query was cancelled
                guard !Task.isCancelled else {
                    return
                }
                
                print("[AssistantView] ❌ Unknown error: \(error)")
                print("[AssistantView] Error type: \(type(of: error))")
                print("[AssistantView] Error details: \(error.localizedDescription)")
                
                let errorTemplate = localizationManager.localizedString(for: "assistant_generic_error")
                let errorMessage = SimpleMessage(
                    content: String(format: errorTemplate, error.localizedDescription),
                    isUser: false
                )
                messages.append(errorMessage)
                startTypingEffect(for: errorMessage)
                isWaitingForResponse = false
                currentQueryTask = nil
            }
        }
    }
    
    private func toggleVoiceRecording() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    private func startListening() {
        Task {
            await voiceService.requestPermissions()
            if voiceService.hasPermission {
                await voiceService.startRecording()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isListening = true
                }
                lastTranscriptionLength = 0
                startSilenceDetection()
            }
        }
    }
    
    private func stopListening() {
        voiceService.stopRecording()
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isListening = false
        }
        
        // Place transcribed text in chatbox
        if !voiceService.transcriptionText.isEmpty {
            messageText = voiceService.transcriptionText
            voiceService.resetTranscription()
        }
    }
    
    private func startSilenceDetection() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [self] _ in
            let currentLength = voiceService.transcriptionText.count
            
            // If text hasn't changed for 1.5 seconds and we have some text, stop listening
            if currentLength > 0 && currentLength == lastTranscriptionLength {
                // Wait for another check to confirm silence
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if voiceService.transcriptionText.count == currentLength {
                        stopListening()
                    }
                }
            }
            
            lastTranscriptionLength = currentLength
        }
    }
}

// MARK: - Supporting Views

struct WelcomeMessage: View {
    @EnvironmentObject var localizationManager: LocalizationManager
    var body: some View {
        // Minimalist centered gradient text - no icon, no card, no background
        GradientTitle(text: localizationManager.localizedString(for: "assistant_welcome_title"))
            .frame(maxWidth: .infinity)
            .transition(.identity) // Disable any transition effects
    }
}

// Animated gradient title used in the welcome card
struct GradientTitle: View {
    let text: String
    @State private var gradientOffset: CGFloat = 0

    var body: some View {
        // Clean gradient text with animated colors only
        Text(text)
            .font(.system(size: 34, weight: .bold))
            .foregroundColor(.clear)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(#colorLiteral(red: 0.117, green: 0.78, blue: 0.317, alpha: 1)), 
                        Color.blue, 
                        Color.purple, 
                        Color(#colorLiteral(red: 0.117, green: 0.78, blue: 0.317, alpha: 1))
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .hueRotation(Angle(degrees: gradientOffset))
                .animation(.linear(duration: 3.0).repeatForever(autoreverses: false), value: gradientOffset)
            )
            .mask(
                Text(text)
                    .font(.system(size: 34, weight: .bold))
            )
            .task {
                // Start animation immediately without any delay or movement
                gradientOffset = 360
            }
            .transition(.identity)
            .animation(.none, value: gradientOffset) // Prevent any layout animation
    }
}

struct ChatBubble: View {
    let message: SimpleMessage
    let displayedContent: String
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: 280, alignment: .trailing)
            } else {
                VStack(alignment: .leading) {
                    // AI message without bubble - direct text on background
                    FormattedMarkdownText(content: displayedContent.isEmpty ? message.content : displayedContent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Clean Text Formatting Helper

struct FormattedMarkdownText: View {
    let content: String
    
    var body: some View {
        // Since we're now using clean formatting without markdown,
        // we just need to display the text with proper line spacing
        Text(content)
            .font(.body)
            .lineSpacing(4) // Add some line spacing for better readability
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct AIThinkingIndicator: View {
    @State private var dotCount = 0
    
    var body: some View {
        HStack {
            Text("AI is thinking" + String(repeating: ".", count: dotCount))
                .font(.caption)
                .foregroundColor(.secondary)
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                        dotCount = (dotCount + 1) % 4
                    }
                }
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct QuickActionsView: View {
    let onActionSelected: (String) -> Void
    
    @EnvironmentObject var localizationManager: LocalizationManager
    private var quickActions: [String] {
        [
            localizationManager.localizedString(for: "assistant_action_weather"),
            localizationManager.localizedString(for: "assistant_action_disease"),
            localizationManager.localizedString(for: "assistant_action_market_prices"),
            localizationManager.localizedString(for: "assistant_action_irrigation"),
            localizationManager.localizedString(for: "assistant_action_seasonal")
        ]
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(quickActions, id: \.self) { action in
                    Button(action: {
                        onActionSelected(action)
                    }) {
                        Text(action)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct CircularMicListeningOverlay: View {
    @State private var animationScale: CGFloat = 1.0
    @State private var ringScale1: CGFloat = 1.0
    @State private var ringScale2: CGFloat = 1.0
    @State private var ringScale3: CGFloat = 1.0
    @State private var ringOpacity1: Double = 0.7
    @State private var ringOpacity2: Double = 0.5
    @State private var ringOpacity3: Double = 0.3
    
    var body: some View {
        // Circular mic with dynamic animation rings - completely transparent, no background
        ZStack {
            // Animated rings (pulsing outward)
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        Color.green.opacity(
                            index == 0 ? ringOpacity1 :
                            index == 1 ? ringOpacity2 :
                            ringOpacity3
                        ),
                        lineWidth: 2.5
                    )
                    .frame(
                        width: CGFloat(100 + (index * 40)),
                        height: CGFloat(100 + (index * 40))
                    )
                    .scaleEffect(
                        index == 0 ? ringScale1 :
                        index == 1 ? ringScale2 :
                        ringScale3
                    )
                    .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            // Central mic icon with subtle pulse
            ZStack {
                // White circular background for mic
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 2)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.green)
            }
            .scaleEffect(animationScale)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Animate mic icon with subtle pulse
        withAnimation(
            Animation.easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            animationScale = 1.08
        }
        
        // Animate ring 1 (innermost)
        withAnimation(
            Animation.easeOut(duration: 1.8)
                .repeatForever(autoreverses: false)
        ) {
            ringScale1 = 1.6
            ringOpacity1 = 0.0
        }
        
        // Animate ring 2 (middle) with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(
                Animation.easeOut(duration: 1.8)
                    .repeatForever(autoreverses: false)
            ) {
                ringScale2 = 1.6
                ringOpacity2 = 0.0
            }
        }
        
        // Animate ring 3 (outermost) with more delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(
                Animation.easeOut(duration: 1.8)
                    .repeatForever(autoreverses: false)
            ) {
                ringScale3 = 1.6
                ringOpacity3 = 0.0
            }
        }
    }
}

struct MessageInputView: View {
    @Binding var text: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    let isListening: Bool
    let isQueryInProgress: Bool
    @Binding var attachedDocuments: [AttachedDocument]
    let onSend: (String) -> Void
    let onQuickActions: () -> Void
    let onAttachment: () -> Void
    let onVoiceRecord: () -> Void
    let onLiveInteraction: () -> Void
    let onStopQuery: () -> Void
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Main input container
            HStack(spacing: 12) {
                // Integrated search bar with all controls
                VStack(alignment: .leading, spacing: 12) {
                    // Text input area at the top - "Ask me anything" as placeholder
                    VStack(alignment: .leading, spacing: 8) {
                        // Display attached documents above text field
                        if !attachedDocuments.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(attachedDocuments) { doc in
                                        AttachedDocumentChip(document: doc) {
                                            attachedDocuments.removeAll { $0.id == doc.id }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Text input with "Ask me anything" as placeholder
                        TextField(localizationManager.localizedString(for: "assistant_input_placeholder"), text: $text, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1...4)
                            .focused(isTextFieldFocused)
                            .frame(minHeight: 20)
                            .disabled(isQueryInProgress)
                            .opacity(isQueryInProgress ? 0.6 : 1.0)
                    }
                    .padding(.leading, 4)
                    
                    HStack(spacing: 12) {
                        // Plus button (disabled during query)
                        Button(action: onAttachment) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isQueryInProgress ? .gray : .green)
                                .frame(width: 28, height: 28)
                        }
                        .disabled(isQueryInProgress)
                        
                        // Tools button (disabled during query)
                        Button(action: onQuickActions) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isQueryInProgress ? .gray : .green)
                                .frame(width: 28, height: 28)
                        }
                        .disabled(isQueryInProgress)
                        
                        Spacer(minLength: 0)
                        
                        // Right side controls
                        HStack(spacing: 8) {
                            // Voice input button (disabled during query)
                            Button(action: onVoiceRecord) {
                                Image(systemName: isListening ? "stop.circle.fill" : "mic.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isListening ? .red : (isQueryInProgress ? .gray : .secondary))
                                    .frame(width: 28, height: 28)
                            }
                            .disabled(isQueryInProgress)
                            
                            // Live Interaction / Stop / Send button
                            Button(action: {
                                if isQueryInProgress {
                                    // Stop the current query
                                    onStopQuery()
                                } else if text.isEmpty {
                                    // Launch live interaction when text is empty
                                    onLiveInteraction()
                                } else {
                                    // Send message when text is present
                                    onSend(text)
                                    #if canImport(UIKit)
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    #endif
                                    isTextFieldFocused.wrappedValue = false
                                }
                            }) {
                                Image(systemName: isQueryInProgress ? "stop.fill" : (text.isEmpty ? "waveform.path.ecg" : "arrow.up"))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(isQueryInProgress ? Color.red : (text.isEmpty ? Color.blue : Color.green))
                                    .clipShape(Circle())
                            }
                            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                            .animation(.easeInOut(duration: 0.2), value: isQueryInProgress)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(25)
                .overlay(
                    AnimatedGradientBorder(cornerRadius: 25, lineWidth: 2)
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Bottom safe area spacer
            Rectangle()
                .fill(Color.clear)
                .frame(height: 8)
        }
        .background(
            Color(.systemBackground)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Document Attachment Support

struct AttachedDocument: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let type: DocumentType
    
    enum DocumentType {
        case pdf
        case docx
        case ppt
        case image
        case other
        
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .docx: return "doc.text.fill"
            case .ppt: return "doc.richtext.fill"
            case .image: return "photo.fill"
            case .other: return "doc.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pdf: return .red
            case .docx: return .blue
            case .ppt: return .orange
            case .image: return .green
            case .other: return .gray
            }
        }
        
        static func from(url: URL) -> DocumentType {
            let ext = url.pathExtension.lowercased()
            switch ext {
            case "pdf": return .pdf
            case "doc", "docx": return .docx
            case "ppt", "pptx": return .ppt
            case "jpg", "jpeg", "png", "heic", "heif": return .image
            default: return .other
            }
        }
    }
}

struct AttachedDocumentChip: View {
    let document: AttachedDocument
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: document.type.icon)
                .font(.system(size: 12))
                .foregroundColor(document.type.color)
            
            Text(document.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var attachedDocuments: [AttachedDocument]
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            .pdf,
            .plainText,
            .png, .jpeg, .heic,
            UTType(filenameExtension: "docx") ?? .data,
            UTType(filenameExtension: "doc") ?? .data,
            UTType(filenameExtension: "ppt") ?? .data,
            UTType(filenameExtension: "pptx") ?? .data
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                let document = AttachedDocument(
                    name: url.lastPathComponent,
                    url: url,
                    type: AttachedDocument.DocumentType.from(url: url)
                )
                parent.attachedDocuments.append(document)
            }
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AssistantView()
}
