//
//  AssistantView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI
import Vision
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
    @State private var messageText = ""
    @State private var messages: [SimpleMessage] = []
    @State private var showingQuickActions = false
    @State private var isWaitingForResponse = false
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
                        sendMessage(action)
                        showingQuickActions = false
                    }
                }
                
                // Input Area
                MessageInputView(
                    text: $messageText,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSend: sendMessage,
                    onQuickActions: { showingQuickActions.toggle() },
                    onAttachment: { },
                    onVoiceRecord: { }
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
        }
    }
    
    private func sendMessage(_ text: String) {
        let userMessage = SimpleMessage(content: text, isUser: true)
        messages.append(userMessage)
        messageText = ""
        isWaitingForResponse = true
        
        // Dismiss keyboard after sending message
        dismissKeyboard()
        isTextFieldFocused = false
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let aiResponse = SimpleMessage(
                content: "Thank you for your question: '\(text)'. I'm here to help with your agricultural needs! I can provide advice on weather, crops, market trends, and more.",
                isUser: false
            )
            messages.append(aiResponse)
            isWaitingForResponse = false
        }
    }
}

// MARK: - Supporting Views

struct WelcomeMessage: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("AgriSense AI")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your agricultural assistant")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Hello! I'm your AI assistant, here to help with your farming needs. I can provide advice on:")
                .font(.body)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cloud.sun")
                        .foregroundColor(.blue)
                    Text("Weather forecasts and crop planning")
                }
                
                HStack {
                    Image(systemName: "leaf")
                        .foregroundColor(.green)
                    Text("Pest and disease identification")
                }
                
                HStack {
                    Image(systemName: "drop")
                        .foregroundColor(.blue)
                    Text("Soil health and irrigation advice")
                }
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.orange)
                    Text("Market trends and pricing")
                }
                
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.gray)
                    Text("Equipment and technology recommendations")
                }
            }
            .padding(.horizontal)
            
            Text("Just ask me anything!")
                .font(.headline)
                .foregroundColor(.green)
                .padding(.top)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding()
    }
}

struct ChatBubble: View {
    let message: SimpleMessage
    
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
                    Text(message.content)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                        .frame(maxWidth: 280, alignment: .leading)
                }
                Spacer()
            }
        }
        .padding(.horizontal)
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
    
    private let quickActions = [
        "What's the weather forecast for farming?",
        "How to identify crop diseases?",
        "Current market prices for vegetables",
        "Best irrigation practices",
        "Seasonal crop recommendations"
    ]
    
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

struct MessageInputView: View {
    @Binding var text: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    let onSend: (String) -> Void
    let onQuickActions: () -> Void
    let onAttachment: () -> Void
    let onVoiceRecord: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main input container
            HStack(spacing: 12) {
                // Integrated search bar with all controls
                HStack(spacing: 12) {
                    // Plus button inside search bar
                    Button(action: onAttachment) {
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
                        .focused(isTextFieldFocused)
                        .frame(minHeight: 20)
                    
                    Spacer(minLength: 0)
                    
                    // Right side controls
                    HStack(spacing: 8) {
                        // Voice input button
                        Button(action: onVoiceRecord) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                        }
                        
                        // Send button
                        Button(action: {
                            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSend(text)
                                #if canImport(UIKit)
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                #endif
                                isTextFieldFocused.wrappedValue = false
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

#Preview {
    AssistantView()
}
