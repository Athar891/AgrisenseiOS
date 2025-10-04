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
class GeminiAIService: AIService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let model = "gemini-2.0-flash-exp" // Using Gemini 2.0 Flash Experimental
    
    nonisolated init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Text-only Messages
    
    func sendMessage(_ message: String, context: AIContext) async throws -> AIResponse {
        let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build context-aware prompt
        let systemPrompt = buildSystemPrompt(context: context)
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let processingTime = Date().timeIntervalSince(startTime)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            throw AIError.rateLimitExceeded
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AIError.serviceUnavailable
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let firstCandidate = geminiResponse.candidates.first,
              let content = firstCandidate.content.parts.first?.text else {
            throw AIError.invalidResponse
        }
        
        // Extract metadata
        let tokensUsed = geminiResponse.usageMetadata?.totalTokenCount ?? 0
        
        return AIResponse(
            content: content,
            confidence: 0.9,
            sources: ["Gemini 2.0 Flash"],
            recommendations: extractRecommendations(from: content),
            followUpQuestions: extractFollowUpQuestions(from: content),
            metadata: ResponseMetadata(
                processingTime: processingTime,
                model: model,
                tokensUsed: tokensUsed,
                cost: nil
            )
        )
    }
    
    // MARK: - Messages with Images
    
    func sendMessageWithImage(_ message: String, image: PlatformImage, context: AIContext) async throws -> AIResponse {
        #if canImport(UIKit)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AIError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()
        
        let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let processingTime = Date().timeIntervalSince(startTime)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        
        if httpResponse.statusCode == 429 {
            throw AIError.rateLimitExceeded
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
        
        return AIResponse(
            content: content,
            confidence: 0.9,
            sources: ["Gemini 2.0 Flash Vision"],
            recommendations: extractRecommendations(from: content),
            followUpQuestions: extractFollowUpQuestions(from: content),
            metadata: ResponseMetadata(
                processingTime: processingTime,
                model: model,
                tokensUsed: tokensUsed,
                cost: nil
            )
        )
        #else
        throw AIError.invalidImage
        #endif
    }
    
    // MARK: - Streaming Messages
    
    func streamMessage(_ message: String, context: AIContext) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await sendMessage(message, context: context)
                    continuation.yield(response.content)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func buildSystemPrompt(context: AIContext) -> String {
        var prompt = """
        You are Krishi AI, an intelligent agricultural assistant designed to help farmers with their agricultural needs. 
        You provide expert advice on weather, crops, market trends, pest management, soil health, and farming best practices.
        
        Be helpful, concise, and practical in your responses. Use simple language that farmers can easily understand.
        
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
