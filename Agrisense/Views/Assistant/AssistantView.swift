//
//  AssistantView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

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
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var showingQuickActions = false
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
                        }
                        .padding()
                    }
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
            .navigationTitle(localizationManager.localizedString(for: "ai_assistant_title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingQuickActions.toggle() }) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.green)
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
        
        // Dismiss keyboard after sending message
        dismissKeyboard()
        isTextFieldFocused = false
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let aiResponse = generateAIResponse(to: text)
            let aiMessage = ChatMessage(
                id: UUID(),
                content: aiResponse,
                isUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)
        }
    }
    
    private func generateAIResponse(to message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("weather") {
            return "Based on current forecasts, you can expect sunny conditions for the next 3 days with temperatures ranging from 18-24°C. This is ideal for most crops, but consider irrigation if you're in a dry area."
        } else if lowercased.contains("pest") || lowercased.contains("disease") {
            return "For pest and disease management, I recommend regular monitoring of your crops. Look for early signs like yellowing leaves or unusual spots. Consider integrated pest management (IPM) approaches for sustainable control."
        } else if lowercased.contains("soil") {
            return "Soil health is crucial for crop success. I recommend testing your soil pH and nutrient levels every 2-3 years. For most crops, a pH between 6.0-7.0 is ideal. Consider adding organic matter to improve soil structure."
        } else if lowercased.contains("market") || lowercased.contains("price") {
            return "Current market prices are showing strong demand for organic produce. Local markets are paying premium prices for fresh, locally-grown vegetables. Consider direct-to-consumer sales for better margins."
        } else if lowercased.contains("irrigation") {
            return "Smart irrigation systems can save up to 30% of water usage. Consider soil moisture sensors and automated systems. Drip irrigation is particularly effective for row crops and can reduce water waste."
        } else {
            return "I'm here to help with your agricultural questions! You can ask me about weather, pests, soil health, market prices, irrigation, crop management, or any other farming-related topics. What would you like to know more about?"
        }
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}

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
        .background(Color(.systemGray6))
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
                        
                        Text("AgriSense AI")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(message.content)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(18)
                    
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
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(QuickAction.allCases, id: \.self) { action in
                    AssistantQuickActionButton(action: action) {
                        onAction(action)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}

enum QuickAction: String, CaseIterable {
    case weather = "weather"
    case pestControl = "pest_control"
    case soilHealth = "soil_health"
    case marketPrices = "market_prices"
    case irrigation = "irrigation"
    case cropPlanning = "crop_planning"
    
    var title: String {
        switch self {
        case .weather:
            return "Weather"
        case .pestControl:
            return "Pest Control"
        case .soilHealth:
            return "Soil Health"
        case .marketPrices:
            return "Market Prices"
        case .irrigation:
            return "Irrigation"
        case .cropPlanning:
            return "Crop Planning"
        }
    }
    
    var icon: String {
        switch self {
        case .weather:
            return "cloud.sun.fill"
        case .pestControl:
            return "ant.fill"
        case .soilHealth:
            return "drop.fill"
        case .marketPrices:
            return "chart.line.uptrend.xyaxis"
        case .irrigation:
            return "drop.degreesign"
        case .cropPlanning:
            return "calendar"
        }
    }
    
    var prompt: String {
        switch self {
        case .weather:
            return "What's the weather forecast for this week and how should I plan my farming activities?"
        case .pestControl:
            return "I'm seeing some pests on my crops. What are the best organic pest control methods?"
        case .soilHealth:
            return "How can I improve my soil health and what tests should I run?"
        case .marketPrices:
            return "What are the current market prices for vegetables and when is the best time to sell?"
        case .irrigation:
            return "What's the most efficient irrigation system for my farm?"
        case .cropPlanning:
            return "Help me plan my crop rotation for next season."
        }
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
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onQuickActions) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            HStack {
                TextField("Ask me anything...", text: $text, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .lineLimit(1...4)
                    .focused($isTextFieldFocused)
                
                Button(action: {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend(text)
                        // Additional keyboard dismissal for safety
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        isTextFieldFocused = false
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(text.isEmpty ? .secondary : .green)
                }
                .disabled(text.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview {
    AssistantView()
        .environmentObject(UserManager())
}
