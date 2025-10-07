//
//  GeminiAIService.swift
//  Agrisense
//
//  Created by GitHub Copilot
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Gemini AI Service Implementation

@MainActor
class GeminiAIService: @preconcurrency AIService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    
    // Model fallback chain - try these in order
    private let modelFallbackChain = [
        "gemini-2.0-flash-exp",                    // Primary: Gemini 2.0 Flash Experimental
        "gemini-2.0-flash-thinking-exp-01-21",     // Backup 1: Gemini 2.0 Flash Thinking
        "gemini-1.5-flash",                         // Backup 2: Gemini 1.5 Flash (stable)
        "gemini-1.5-pro"                            // Backup 3: Gemini 1.5 Pro (most reliable)
    ]
    
    // Track which models are rate-limited or unavailable
    private var unavailableModels: Set<String> = []
    private var rateLimitedModels: [String: Date] = [:] // Model -> time when rate limited
    
    private let rateLimitCooldown: TimeInterval = 60.0 // 60 seconds cooldown per model
    
    nonisolated init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // Get the next available model from the fallback chain
    private func getAvailableModel() -> String? {
        let now = Date()
        
        for model in modelFallbackChain {
            // Skip if model is permanently unavailable (404 errors)
            if unavailableModels.contains(model) {
                continue
            }
            
            // Skip if model is rate-limited and cooldown hasn't expired
            if let rateLimitTime = rateLimitedModels[model] {
                if now.timeIntervalSince(rateLimitTime) < rateLimitCooldown {
                    continue
                }
                // Cooldown expired, remove from rate-limited list
                rateLimitedModels.removeValue(forKey: model)
            }
            
            return model
        }
        
        return nil // All models exhausted
    }
    
    // Mark a model as rate-limited
    private func markModelRateLimited(_ model: String) {
        rateLimitedModels[model] = Date()
        print("[GeminiAI] 🚫 Model '\(model)' marked as rate-limited")
    }
    
    // Mark a model as unavailable (404)
    private func markModelUnavailable(_ model: String) {
        unavailableModels.insert(model)
        print("[GeminiAI] ❌ Model '\(model)' marked as unavailable (404)")
    }
    
    // Reset rate limits (called when a request succeeds)
    private func resetModelStatus(_ model: String) {
        rateLimitedModels.removeValue(forKey: model)
    }
    
    // MARK: - Protocol Conformance
    
    func sendMessage(_ message: String, context: AIContext) async throws -> AIResponse {
        return try await sendMessage(message, context: context, forVoice: false)
    }
    
    // MARK: - Text-only Messages
    
    func sendMessage(_ message: String, context: AIContext, forVoice: Bool = false) async throws -> AIResponse {
        let maxAttempts = 5
        var lastError: Error?
        var attemptCount = 0
        
        // Build context-aware prompt once (with voice flag)
        let systemPrompt = buildSystemPrompt(context: context, forVoice: forVoice)
        let fullPrompt = "\(systemPrompt)\n\nUser: \(message)"
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": fullPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ]
            ]
        ]
        
        // Try each available model in the fallback chain
        while attemptCount < maxAttempts {
            attemptCount += 1
            
            guard let currentModel = getAvailableModel() else {
                print("[GeminiAI] ❌ All models exhausted after \(attemptCount) attempts")
                throw lastError ?? AIError.serviceUnavailable
            }
            
            do {
                print("[GeminiAI] 🔄 Attempt \(attemptCount)/\(maxAttempts) with model '\(currentModel)'")
                
                let url = URL(string: "\(baseURL)/models/\(currentModel):generateContent?key=\(apiKey)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                
                let startTime = Date()
                print("[GeminiAI] Making API request...")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                let processingTime = Date().timeIntervalSince(startTime)
                print("[GeminiAI] API request completed in \(String(format: "%.2f", processingTime))s")
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[GeminiAI] ❌ Invalid HTTP response")
                    throw AIError.invalidResponse
                }
                
                print("[GeminiAI] HTTP Status: \(httpResponse.statusCode)")
                
                // Handle rate limit (429)
                if httpResponse.statusCode == 429 {
                    print("[GeminiAI] ❌ Rate limit exceeded")
                    print("[GeminiAI] ⚠️ Rate limit on '\(currentModel)' (attempt \(attemptCount)/\(maxAttempts))")
                    markModelRateLimited(currentModel)
                    lastError = AIError.rateLimitExceeded
                    
                    // Try next model in chain
                    if let nextModel = getAvailableModel() {
                        print("[GeminiAI] 🔄 Switched from '\(currentModel)' to '\(nextModel)'")
                        continue
                    } else {
                        throw AIError.rateLimitExceeded
                    }
                }
                
                // Handle not found (404) - model doesn't exist
                if httpResponse.statusCode == 404 {
                    print("[GeminiAI] ❌ Service error: \(httpResponse.statusCode)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("[GeminiAI] Error details: \(errorString)")
                    }
                    markModelUnavailable(currentModel)
                    lastError = AIError.serviceUnavailable
                    
                    // Try next model
                    if let nextModel = getAvailableModel() {
                        print("[GeminiAI] 🔄 Switched from '\(currentModel)' to '\(nextModel)'")
                        continue
                    } else {
                        throw AIError.serviceUnavailable
                    }
                }
                
                // Handle other errors
                guard httpResponse.statusCode == 200 else {
                    print("[GeminiAI] ❌ Service error: \(httpResponse.statusCode)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("[GeminiAI] Error details: \(errorString)")
                    }
                    throw AIError.serviceUnavailable
                }
                
                // Success! Parse response
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                
                guard let firstCandidate = geminiResponse.candidates.first,
                      let content = firstCandidate.content.parts.first?.text else {
                    throw AIError.invalidResponse
                }
                
                // Extract metadata
                let tokensUsed = geminiResponse.usageMetadata?.totalTokenCount ?? 0
                
                // Reset rate limit status on success
                resetModelStatus(currentModel)
                print("[GeminiAI] ✅ Successfully used model '\(currentModel)'")
                
                return AIResponse(
                    content: content,
                    confidence: 0.9,
                    sources: ["Gemini API (\(currentModel))"],
                    recommendations: extractRecommendations(from: content),
                    followUpQuestions: extractFollowUpQuestions(from: content),
                    metadata: ResponseMetadata(
                        processingTime: processingTime,
                        model: currentModel,
                        tokensUsed: tokensUsed,
                        cost: nil
                    )
                )
                
            } catch {
                lastError = error
                print("[GeminiAI] ⚠️ Error with model '\(currentModel)': \(error.localizedDescription)")
                // Continue to next model in fallback chain
            }
        }
        
        // All attempts failed
        print("[GeminiAI] ❌ All \(maxAttempts) attempts failed")
        throw lastError ?? AIError.serviceUnavailable
    }
    
    // MARK: - Messages with Images
    
    func sendMessageWithImage(_ message: String, image: PlatformImage, context: AIContext) async throws -> AIResponse {
        #if canImport(UIKit)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()
        
        let systemPrompt = buildSystemPrompt(context: context)
        let fullPrompt = "\(systemPrompt)\n\nUser: \(message)"
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": fullPrompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]
        
        let maxAttempts = 5
        var lastError: Error?
        var attemptCount = 0
        
        // Try each available model in the fallback chain
        while attemptCount < maxAttempts {
            attemptCount += 1
            
            guard let currentModel = getAvailableModel() else {
                print("[GeminiAI] ❌ All models exhausted for image request")
                throw lastError ?? AIError.serviceUnavailable
            }
            
            do {
                print("[GeminiAI] 🔄 Image request attempt \(attemptCount)/\(maxAttempts) with '\(currentModel)'")
                
                let url = URL(string: "\(baseURL)/models/\(currentModel):generateContent?key=\(apiKey)")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                
                let startTime = Date()
                let (data, response) = try await URLSession.shared.data(for: request)
                let processingTime = Date().timeIntervalSince(startTime)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AIError.invalidResponse
                }
                
                // Handle rate limit
                if httpResponse.statusCode == 429 {
                    markModelRateLimited(currentModel)
                    lastError = AIError.rateLimitExceeded
                    if let nextModel = getAvailableModel() {
                        print("[GeminiAI] 🔄 Switched to '\(nextModel)' for image request")
                        continue
                    } else {
                        throw AIError.rateLimitExceeded
                    }
                }
                
                // Handle not found
                if httpResponse.statusCode == 404 {
                    markModelUnavailable(currentModel)
                    lastError = AIError.serviceUnavailable
                    if let nextModel = getAvailableModel() {
                        print("[GeminiAI] 🔄 Switched to '\(nextModel)' for image request")
                        continue
                    } else {
                        throw AIError.serviceUnavailable
                    }
                }
                
                guard httpResponse.statusCode == 200 else {
                    throw AIError.serviceUnavailable
                }
                
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                
                guard let firstCandidate = geminiResponse.candidates.first,
                      let content = firstCandidate.content.parts.first?.text else {
                    throw AIError.invalidResponse
                }
                
                let tokensUsed = geminiResponse.usageMetadata?.totalTokenCount ?? 0
                
                resetModelStatus(currentModel)
                print("[GeminiAI] ✅ Image request successful with '\(currentModel)'")
                
                return AIResponse(
                    content: content,
                    confidence: 0.9,
                    sources: ["Gemini Vision (\(currentModel))"],
                    recommendations: extractRecommendations(from: content),
                    followUpQuestions: extractFollowUpQuestions(from: content),
                    metadata: ResponseMetadata(
                        processingTime: processingTime,
                        model: currentModel,
                        tokensUsed: tokensUsed,
                        cost: nil
                    )
                )
                
            } catch {
                lastError = error
                print("[GeminiAI] ⚠️ Image request error with '\(currentModel)': \(error.localizedDescription)")
            }
        }
        
        throw lastError ?? AIError.serviceUnavailable
        #else
        throw AIError.invalidImage
        #endif
    }
    
    // MARK: - Streaming Messages
    
    func streamMessage(_ message: String, context: AIContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await self.sendMessage(message, context: context)
                    continuation.yield(response.content)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Fast Message with Streaming (for real-time interaction)
    
    func sendMessageWithStreaming(_ message: String, context: AIContext, forVoice: Bool = false) async throws -> AIResponse {
        // For now, use the standard sendMessage but with timeout handling
        // In future, this can be enhanced with actual streaming from Gemini API
        
        print("[GeminiAI] Sending message to API... (forVoice: \(forVoice))")
        let response = try await withTimeout(seconds: 12.0) {
            try await self.sendMessage(message, context: context, forVoice: forVoice)
        }
        print("[GeminiAI] ✅ Response received: \(response.content.prefix(50))...")
        return response
    }
    
    // Timeout wrapper for API calls
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add the timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AIError.timeout
            }
            
            // Return the first result (either success or timeout)
            guard let result = try await group.next() else {
                throw AIError.timeout
            }
            
            // Cancel remaining tasks
            group.cancelAll()
            
            return result
        }
    }
    
    // MARK: - Helper Methods
    
    private func buildSystemPrompt(context: AIContext, forVoice: Bool = false) -> String {
        var prompt = """
        You are Krishi AI, an intelligent agricultural assistant designed to help farmers with their agricultural needs. 
        You provide expert advice on weather, crops, market trends, pest management, soil health, and farming best practices.
        
        Be helpful, concise, and practical in your responses. Use simple language that farmers can easily understand.
        """
        
        if forVoice {
            // Voice-specific instructions: NO emojis, natural speech
            prompt += """
            
            
            CRITICAL VOICE RESPONSE RULES - YOU MUST FOLLOW THESE EXACTLY:
            
            1. NO EMOJIS: Do not use any emojis whatsoever. They sound unnatural when spoken aloud.
            
            2. NO SPECIAL CHARACTERS: Do not use bullet points (•), asterisks (*), underscores (_), or any markdown formatting.
            
            3. NATURAL SPEECH: Write as if you're speaking directly to the person. Use complete sentences that flow naturally when read aloud.
            
            4. CONVERSATIONAL TONE: Use words like "first", "second", "also", "additionally" instead of bullet points.
            
            5. SHORT AND CLEAR: Keep responses under 100 words. Be direct and to the point.
            
            EXAMPLE OF CORRECT VOICE FORMATTING:
            
            "Of course I can help with that. To give you the most useful forecast, I need to know your location and what crops you're growing. Once I have that information, I can tell you about temperature, chance of rain, and wind conditions."
            
            WRONG (don't do this for voice):
            "Of course! 👋 I can help with that!
            
            • 📍 Your location
            • 🌱 Crops you're growing"
            """
        } else {
            // Text-specific instructions: emojis OK for visual appeal
            prompt += """
            
            
            CRITICAL FORMATTING RULES - YOU MUST FOLLOW THESE EXACTLY:
            
            1. Remove Special Characters: Do not use any markdown-style formatting. This means you must remove all asterisks (*), underscores (_), or other characters used for bolding, italics, or lists.
            
            2. Use Clean Bullet Points: When you need to present a list, use standard, clean bullet points (• or a simple hyphen -).
            
            3. Incorporate Relevant Emojis: Add a relevant emoji at the beginning of each list item or where it enhances meaning. This makes the information easier to scan and more interactive.
               For example: 📍 for location, 🌱 for crops, 🌡️ for temperature, 💧 for rain, 🌾 for harvest, 🚜 for farming equipment, 🐛 for pests, 💰 for market prices, ☀️ for sunny weather, ⛈️ for storms, 🌿 for soil health, 📊 for data/statistics.
            
            4. Ensure Readability and Spacing:
               - Keep your sentences and paragraphs short and to the point.
               - Use single line breaks between list items and double line breaks between different sections of the text to ensure there is plenty of white space.
            
            EXAMPLE OF CORRECT FORMATTING:
            
            Of course, I can help with that! 👋

            To give you the most useful forecast, I just need to know two things:

            • 📍 Your current location
            • 🌱 The crops you are growing

            Once I have that, I can tell you about:

            • 🌡️ Temperature (highs and lows)
            • 💧 Chance of rain
            • 💨 Wind speed and direction
            
            NEVER use markdown formatting like **bold** or *italic* or markdown lists with - or *. Always use clean bullet points with emojis as shown above.
            """
        }
        
        // Add location context
        if let location = context.locationContext {
            prompt += "\n\nUser's location: \(location.region), Climate: \(location.climate)"
        }
        
        // Add crop context
        if let crops = context.cropContext, !crops.activeCrops.isEmpty {
            let cropNames = crops.activeCrops.map { $0.name }.joined(separator: ", ")
            prompt += "\n\nUser's active crops: \(cropNames)"
        }
        
        // Add weather context
        if let weather = context.weatherContext {
            prompt += "\n\nCurrent weather: \(weather.current.description), Temp: \(weather.current.temperature)°C, Humidity: \(weather.current.humidity)%"
        }
        
        // Add seasonal context
        if let seasonal = context.seasonalContext {
            prompt += "\n\nCurrent season: \(seasonal.currentSeason.rawValue)"
        }
        
        prompt += "\n\nAlways respond in a helpful and supportive manner."
        
        return prompt
    }
    
    private func extractRecommendations(from content: String) -> [String] {
        // Simple extraction - can be enhanced with better parsing
        let lines = content.components(separatedBy: "\n")
        return lines.filter { line in
            line.contains("recommend") || line.contains("suggest") || line.hasPrefix("•") || line.hasPrefix("-")
        }.prefix(3).map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    private func extractFollowUpQuestions(from content: String) -> [String] {
        // Extract questions from the response
        let sentences = content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        return sentences.filter { $0.contains("?") }.prefix(2).map { 
            $0.trimmingCharacters(in: .whitespaces) 
        }
    }
}

// MARK: - Gemini API Response Models

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
    let usageMetadata: GeminiUsageMetadata?
    let promptFeedback: GeminiPromptFeedback?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
    let finishReason: String?
    let index: Int?
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
    let role: String?
}

struct GeminiPart: Codable {
    let text: String?
}

struct GeminiUsageMetadata: Codable {
    let promptTokenCount: Int?
    let candidatesTokenCount: Int?
    let totalTokenCount: Int?
}

struct GeminiPromptFeedback: Codable {
    let safetyRatings: [GeminiSafetyRating]?
}

struct GeminiSafetyRating: Codable {
    let category: String
    let probability: String
}
