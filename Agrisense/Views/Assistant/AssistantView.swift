//
//  AssistantView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI
import UIKit

// Extension to handle keyboard dismissal
extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AssistantView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @StateObject private var aiServiceManager = AIServiceManager.shared
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var showingQuickActions = false
    @State private var isWaitingForResponse = false
    @State private var isTyping = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome Message
                            if messages.isEmpty {
                                WelcomeMessage()
                            }
                            
                            // Chat Messages
                            ForEach(messages) { message in
                                ChatBubble(message: message)
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
                
                // Quick Actions
                if showingQuickActions {
                    QuickActionsView { action in
                        sendMessage(action.prompt)
                        showingQuickActions = false
                    }
                }
                
                // Input Area
                MessageInputView(
                    text: $messageText,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSend: sendMessage,
                    onQuickActions: { showingQuickActions.toggle() }
                )
            }
            .background(Color(.systemBackground))
            .navigationTitle("Ask Krishi AI")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear Chat") {
                            messages.removeAll()
                        }
                        Button("Voice Settings") {
                            // Handle voice settings
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside text field
                dismissKeyboard()
                isTextFieldFocused = false
            }
            .onDisappear {
                // Dismiss keyboard when leaving the view
                dismissKeyboard()
                isTextFieldFocused = false
            }
            .onChange(of: appState.selectedTab) { _, newTab in
                // Dismiss keyboard when switching away from assistant tab
                if newTab != AppState.Tab.assistant {
                    dismissKeyboard()
                    isTextFieldFocused = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                // Dismiss keyboard when app goes to background
                dismissKeyboard()
                isTextFieldFocused = false
            }
            .onAppear {
                configureAIService()
            }
        }
    }
    
    private func sendMessage(_ text: String) {
        let userMessage = ChatMessage(
            id: UUID(),
            content: text,
            isUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        messageText = ""
        isWaitingForResponse = true
        
        // Dismiss keyboard after sending message
        dismissKeyboard()
        isTextFieldFocused = false
        
        // Send message to AI service
        Task {
            do {
                let response = try await aiServiceManager.sendMessage(text, conversationHistory: messages)
                
                await MainActor.run {
                    // Clean and format the response content
                    let cleanedContent = cleanResponseContent(response.content)
                    
                    let aiMessage = ChatMessage(
                        id: UUID(),
                        content: cleanedContent,
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(aiMessage)
                    isWaitingForResponse = false
                    
                    // Start typing effect for the AI response
                    if !messages.isEmpty {
                        isTyping = true
                        // Typing will be handled by TypingText component
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTyping = false
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        id: UUID(),
                        content: "I'm sorry, I encountered an error: \(error.localizedDescription). Please try again.",
                        isUser: false,
                        timestamp: Date()
                    )
                    messages.append(errorMessage)
                    isWaitingForResponse = false
                }
            }
        }
    }
    
    private func configureAIService() {
        // For now, we'll configure with available managers
        // In a future update, we can integrate with the existing DI system
        
        // Create temporary instances for now - this will be improved in future tasks
        let cropManager = CropManager()
        let weatherService = WeatherService()
        
        aiServiceManager.configure(
            userManager: userManager,
            cropManager: cropManager,
            weatherService: weatherService,
            appState: appState
        )
    }
    
    private func cleanResponseContent(_ content: String) -> String {
        var cleaned = content
        
        // Remove excessive asterisks and markdown formatting
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "*", with: "")
        
        // Remove excessive newlines
        cleaned = cleaned.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
        
        // Clean up bullet points and formatting
        cleaned = cleaned.replacingOccurrences(of: "• ", with: "• ")
        cleaned = cleaned.replacingOccurrences(of: "- ", with: "• ")
        
        // Remove any leading/trailing whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure proper sentence spacing
        cleaned = cleaned.replacingOccurrences(of: ".  ", with: ". ")
        cleaned = cleaned.replacingOccurrences(of: ".   ", with: ". ")
        
        return cleaned
    }
}

// WelcomeMessage and other supporting views remain unchanged
struct WelcomeMessage: View {
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AgriSense AI")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Your agricultural assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("Hello! I'm your AI assistant, here to help with your \(userManager.currentUser?.userType == .farmer ? "farming" : "business") needs. I can provide advice on:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "cloud.sun.fill", text: "Weather forecasts and crop planning")
                FeatureRow(icon: "leaf.fill", text: "Pest and disease identification")
                FeatureRow(icon: "drop.fill", text: "Soil health and irrigation advice")
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Market trends and pricing")
                FeatureRow(icon: "gear", text: "Equipment and technology recommendations")
            }
            
            Text("Just ask me anything!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    @State private var hasAppeared = false
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(18)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("Krishi AI")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    // Use TypingText for AI responses
                    TypingText(
                        text: message.content,
                        font: .subheadline,
                        color: .primary,
                        typingSpeed: 0.03,
                        startTyping: hasAppeared
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(18)
                    .onAppear {
                        hasAppeared = true
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
}

struct QuickActionsView: View {
    let onAction: (QuickAction) -> Void
    @StateObject private var aiServiceManager = AIServiceManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(aiServiceManager.getContextualQuickActions(), id: \.id) { action in
                    AssistantQuickActionButton(action: action) {
                        onAction(action)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}



struct AssistantQuickActionButton: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.title3)
                    .foregroundColor(.green)
                
                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 80, height: 60)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MessageInputView: View {
    @Binding var text: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: (String) -> Void
    let onQuickActions: () -> Void
    @State private var showingVoiceInput = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main input container
            HStack(spacing: 12) {
                // Integrated search bar with all controls
                HStack(spacing: 12) {
                    // Plus button inside search bar
                    Button(action: {
                        // Handle attachment or additional options
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                    }
                    
                    // Tools button
                    Button(action: onQuickActions) {
                        HStack(spacing: 6) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                            
                            Text("Tools")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    // Text input area
                    TextField("Ask me anything...", text: $text, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.primary)
                        .lineLimit(1...4)
                        .focused($isTextFieldFocused)
                        .frame(minHeight: 20)
                    
                    Spacer(minLength: 0)
                    
                    // Right side controls
                    HStack(spacing: 8) {
                        // Voice input button
                        Button(action: {
                            showingVoiceInput.toggle()
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                        }
                        
                        // Send button
                        Button(action: {
                            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSend(text)
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                isTextFieldFocused = false
                            }
                        }) {
                            Image(systemName: text.isEmpty ? "waveform" : "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(text.isEmpty ? Color(.systemGray4) : Color.green)
                                .clipShape(Circle())
                        }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color(.separator), lineWidth: 0.5)
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

// MARK: - Typing Text Component

struct TypingText: View {
    let text: String
    let font: Font
    let color: Color
    let typingSpeed: Double
    let startTyping: Bool
    
    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var timer: Timer?
    
    init(text: String, font: Font = .body, color: Color = .primary, typingSpeed: Double = 0.05, startTyping: Bool = true) {
        self.text = text
        self.font = font
        self.color = color
        self.typingSpeed = typingSpeed
        self.startTyping = startTyping
    }
    
    var body: some View {
        Text(displayedText)
            .font(font)
            .foregroundColor(color)
            .multilineTextAlignment(.leading)
            .onAppear {
                if startTyping {
                    startTypingAnimation()
                }
            }
            .onChange(of: startTyping) { _, newValue in
                if newValue {
                    startTypingAnimation()
                }
            }
            .onDisappear {
                stopTypingAnimation()
            }
    }
    
    private func startTypingAnimation() {
        // Reset states
        displayedText = ""
        currentIndex = 0
        stopTypingAnimation()
        
        // Start typing animation
        timer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { _ in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText = String(text[..<text.index(after: index)])
                currentIndex += 1
            } else {
                stopTypingAnimation()
            }
        }
    }
    
    private func stopTypingAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

struct AIThinkingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Krishi AI is thinking...")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.green.opacity(animationPhase == index ? 1.0 : 0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2), value: animationPhase)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(18)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

#Preview {
    AssistantView()
        .environmentObject(UserManager())
}
