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
        You are Krishi AI, an expert agricultural assistant powered by advanced AI. You have comprehensive knowledge across ALL aspects of agriculture:
        
        🌾 CROP CULTIVATION & MANAGEMENT:
        - Crop selection based on soil type, climate, and season
        - Planting techniques, spacing, and depth requirements
        - Crop rotation strategies for soil health
        - Intercropping and mixed farming practices
        - Growth stages and developmental milestones
        - Harvesting timing and post-harvest handling
        
        🌱 SOIL HEALTH & FERTILIZATION:
        - Soil types, composition, and pH management
        - Nutrient requirements (NPK, micronutrients)
        - Organic vs. chemical fertilizers
        - Composting and vermicomposting techniques
        - Soil testing and amendment recommendations
        - Mulching and soil conservation
        
        💧 WATER MANAGEMENT & IRRIGATION:
        - Irrigation methods (drip, sprinkler, flood, etc.)
        - Water conservation techniques
        - Rainwater harvesting
        - Drainage systems
        - Irrigation scheduling based on crop needs
        
        🐛 PEST & DISEASE MANAGEMENT:
        - Common pests identification by crop type
        - Integrated Pest Management (IPM) strategies
        - Organic pest control methods
        - Disease symptoms and treatment
        - Preventive measures and crop protection
        
        🌤️ WEATHER & CLIMATE ADAPTATION:
        - Weather pattern interpretation for farming
        - Climate-smart agriculture practices
        - Drought and flood management
        - Seasonal planning and crop calendars
        - Temperature and humidity effects on crops
        
        💰 GOVERNMENT SCHEMES & SUBSIDIES (India):
        - PM-KISAN (income support)
        - Pradhan Mantri Fasal Bima Yojana (crop insurance)
        - Kisan Credit Card schemes
        - Soil Health Card program
        - National Agriculture Market (e-NAM)
        - State-specific farmer welfare schemes
        - Subsidy programs for equipment and inputs
        
        🚜 MODERN FARMING TECHNOLOGY:
        - Precision agriculture tools
        - Farm machinery and equipment
        - Agricultural drones and sensors
        - Mobile apps for farmers
        - IoT in agriculture
        - Greenhouse and protected cultivation
        
        📊 MARKET & ECONOMICS:
        - Crop pricing and market trends
        - Minimum Support Price (MSP)
        - Value addition and processing
        - Marketing channels and strategies
        - Cost-benefit analysis
        
        � SUSTAINABLE PRACTICES:
        - Organic farming certification
        - Natural farming methods
        - Carbon sequestration
        - Biodiversity conservation
        - Agroforestry systems
        """
        
        // Voice-specific modifications
        if forVoice {
            prompt += """
            
            
            CRITICAL VOICE INTERACTION RULES - YOU MUST FOLLOW THESE STRICTLY:
            
            1. Response Length: Keep answers between 50-80 words maximum for natural speech flow.
            
            2. Formatting Restrictions - ABSOLUTELY NO:
               - Emojis of any kind
               - Asterisks for emphasis or bold text
               - Bullet points or numbered lists
               - Special characters like •, ◦, ▪, →, –, —, *, #
               - Markdown formatting
               - Section headers or titles
               
            3. Structure Requirements:
               - Write in complete, flowing sentences
               - Connect ideas naturally with transitions
               - Present information as continuous paragraphs
               - Use simple punctuation only: periods, commas, question marks
               
            4. Language Style:
               - Speak conversationally as if talking to a friend
               - Avoid technical jargon unless essential
               - Use clear, direct language
               - Avoid redundant phrases like "Here's a breakdown" or "In summary"
               
            5. Information Organization:
               - Present the most important point first
               - Add supporting details naturally
               - End with actionable advice when relevant
               - Maintain logical flow between sentences
            
            CORRECT EXAMPLE:
            "For drip irrigation systems, you can start by checking local agricultural supply stores. They often offer personalized advice and support based on your specific needs. Farm equipment dealers are another good option as they may provide installation and maintenance services. You can also explore government agricultural extension offices for recommendations on suppliers who work with subsidy schemes."
            
            INCORRECT EXAMPLES TO AVOID:
            "🏭 Local Agricultural Supply Stores: These are often the best place to start..."
            "**Local Agricultural Supply Stores:** These are often..."
            "• Local Agricultural Supply Stores - These are often..."
            "Here's a breakdown of where you can look:"
            """
        } else {
            prompt += """
            
            
            TEXT INTERACTION GUIDELINES - CLEAN AND READABLE FORMAT:
            
            1. Structure:
               - Organize information in clear, well-spaced paragraphs
               - Use proper line breaks between different sections
               - Present information in logical order
               
            2. Formatting Restrictions:
               - Do NOT use markdown formatting like **bold** or *italic*
               - Do NOT use asterisks for emphasis
               - Do NOT use special characters for decoration
               - Avoid emojis except when absolutely necessary for clarity
               
            3. Lists and Organization:
               - When listing items, use simple numbered points (1., 2., 3.)
               - For sub-points, use simple dashes (-)
               - Maintain consistent indentation
               - Add blank lines between major sections
               
            4. Language Style:
               - Be clear and professional
               - Avoid redundant phrases like "Here's a breakdown" or "In summary"
               - Start with the most relevant information
               - Use complete, well-formed sentences
               
            5. Weather Information (when applicable):
               - Present data in a clean, readable format
               - Use simple labels: Temperature, Humidity, Rainfall
               - Avoid excessive symbols or decorative elements
            
            CORRECT EXAMPLE:
            
            For drip irrigation systems, consider these options:
            
            1. Local Agricultural Supply Stores
            These stores offer personalized advice based on your specific needs and local conditions. They typically carry a range of components and complete kits. Staff can help determine the right size and type of system for your farm.
            
            2. Farm Equipment Dealers
            Dealers who sell tractors and farm machinery often carry irrigation equipment including drip systems. They may offer installation and maintenance services, which is helpful if you need a comprehensive solution.
            
            3. Government Agricultural Extension Offices
            These offices can recommend suppliers who work with government subsidy schemes, potentially reducing your costs.
            
            INCORRECT EXAMPLE TO AVOID:
            **Here's a breakdown of where you can buy drip irrigation systems:**
            
            🏭 **Local Agricultural Supply Stores:**
            • Personalized advice
            • Range of components
            *** Important: Staff can help! ***
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
        
        prompt += "\n\nAlways respond in a helpful, accurate, and supportive manner. Provide practical, actionable advice that farmers can implement immediately."
        
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
