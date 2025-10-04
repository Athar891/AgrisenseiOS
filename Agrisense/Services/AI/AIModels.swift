//
//  AIModels.swift
//  Agrisense
//
//  Created by Kiro AI on 30/09/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Core Chat Message Model

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let attachments: [MessageAttachment]?
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), attachments: [MessageAttachment]? = nil) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.attachments = attachments
    }
}

// MARK: - AI Context Models

struct AIContext {
    var userProfile: UserProfile?
    var locationContext: LocationContext?
    var cropContext: CropContext?
    var weatherContext: WeatherContext?
    var marketContext: MarketContext?
    var seasonalContext: SeasonalContext?
    var deviceContext: DeviceContext?
    var conversationHistory: [ChatMessage]
    var timestamp: Date
    var appSection: String
    
    init() {
        self.conversationHistory = []
        self.timestamp = Date()
        self.appSection = "Assistant"
    }
    
    static func current() -> AIContext {
        return AIContext()
    }
}

// MARK: - Context Support Types

struct UserProfile: Codable {
    let id: String
    let name: String
    let userType: String // Changed from UserType to String to avoid dependency
    let experienceLevel: String
    let farmingMethods: [String]
    let preferredLanguage: String
    let location: String?
    let timezone: String
}

struct LocationContext: Codable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let region: String
    let climate: String
    let soilType: String?
    let elevation: Double?
    let timezone: String
}

struct CropContext: Codable {
    let activeCrops: [DetailedCropInfo]
    let previousCrops: [CropRotationEntry]
    let upcomingTasks: [UpcomingTask]
    let totalFarmArea: Double
    let irrigationSystem: String?
}

struct DetailedCropInfo: Codable {
    let id: String
    let name: String
    let variety: String?
    let plantingDate: Date
    let expectedHarvestDate: Date
    let currentStage: String
    let area: Double
    let location: String?
    let healthStatus: String
    let lastAction: String?
    let nextActionDue: Date?
}

struct CropRotationEntry: Codable {
    let cropName: String
    let season: String
    let year: Int
    let yield: Double?
    let notes: String?
}

struct UpcomingTask: Codable {
    let id: String
    let title: String
    let description: String
    let dueDate: Date
    let priority: String
    let cropId: String?
    let category: String
}

struct WeatherContext: Codable {
    let current: CurrentWeather
    let forecast: [WeatherForecastDay]
    let alerts: [WeatherAlert]?
    let lastUpdated: Date
}

struct CurrentWeather: Codable {
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: String
    let description: String
    let pressure: Double?
    let uvIndex: Double?
}

struct WeatherForecastDay: Codable {
    let date: Date
    let tempHigh: Double
    let tempLow: Double
    let humidity: Double
    let precipitation: Double
    let windSpeed: Double
    let description: String
}

struct WeatherAlert: Codable {
    let title: String
    let description: String
    let severity: String
    let startTime: Date
    let endTime: Date
}

struct MarketContext: Codable {
    let localPrices: [MarketPrice]
    let trends: [PriceTrend]
    let opportunities: [MarketOpportunity]
    let lastUpdated: Date
}

struct MarketPrice: Codable {
    let cropName: String
    let price: Double
    let unit: String
    let market: String
    let date: Date
}

struct PriceTrend: Codable {
    let cropName: String
    let trend: String // "up", "down", "stable"
    let percentage: Double
    let timeframe: String
}

struct MarketOpportunity: Codable {
    let title: String
    let description: String
    let cropType: String?
    let deadline: Date?
    let potential: String
}

struct SeasonalContext: Codable {
    let currentSeason: AIModelsSeason
    let weekInSeason: Int
    let cropCalendar: [CropCalendarEntry]
    let seasonalTips: [String]
    let commonIssues: [String]
}

enum AIModelsSeason: String, Codable {
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"
    case monsoon = "Monsoon"
    case postMonsoon = "Post-Monsoon"
}

struct CropCalendarEntry: Codable {
    let cropName: String
    let action: String
    let timeframe: String
    let priority: String
    let description: String
}

struct DeviceContext: Codable {
    let platform: String
    let version: String
    let language: String
    let timezone: String
    let connectivity: String
    let batteryLevel: Double?
    let location: String?
}

// MARK: - AI Response Models

struct AIResponse: Codable {
    let content: String
    let confidence: Double
    let sources: [String]
    let recommendations: [String]
    let followUpQuestions: [String]
    let metadata: ResponseMetadata
    
    init(content: String, confidence: Double = 0.8, sources: [String] = [], recommendations: [String] = [], followUpQuestions: [String] = [], metadata: ResponseMetadata? = nil) {
        self.content = content
        self.confidence = confidence
        self.sources = sources
        self.recommendations = recommendations
        self.followUpQuestions = followUpQuestions
        self.metadata = metadata ?? ResponseMetadata(
            processingTime: 0.0,
            model: "gemini-2.0-flash",
            tokensUsed: 0,
            cost: nil
        )
    }
}

struct ResponseMetadata: Codable {
    let processingTime: TimeInterval
    let model: String
    let tokensUsed: Int
    let cost: Double?
}

// MARK: - Context Validation

struct ContextValidationResult {
    let isValid: Bool
    let issues: [String]
    let suggestions: [String]
    
    init(isValid: Bool, issues: [String], suggestions: [String]) {
        self.isValid = isValid
        self.issues = issues
        self.suggestions = suggestions
    }
}

// MARK: - Enhanced Chat Message Models

extension ChatMessage {
    enum MessageType: String, Codable {
        case text
        case voice
        case image
        case system
    }
}

struct MessageAttachment: Identifiable, Codable {
    let id: UUID
    let type: AttachmentType
    let url: String
    let fileName: String
    let fileSize: Int64
    let mimeType: String
    let thumbnailData: Data? // For images
    let extractedText: String? // For documents or OCR from images
    let metadata: [String: String]
    
    enum AttachmentType: String, Codable, CaseIterable {
        case image = "image"
        case audio = "audio"
        case document = "document"
        case pdf = "pdf"
        
        var icon: String {
            switch self {
            case .image:
                return "photo"
            case .audio:
                return "waveform"
            case .document:
                return "doc.text"
            case .pdf:
                return "doc.richtext"
            }
        }
        
        var supportedMimeTypes: [String] {
            switch self {
            case .image:
                return ["image/jpeg", "image/png", "image/heic", "image/heif", "image/gif"]
            case .audio:
                return ["audio/mpeg", "audio/wav", "audio/m4a"]
            case .document:
                return ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", 
                       "application/msword", 
                       "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                       "application/vnd.ms-powerpoint"]
            case .pdf:
                return ["application/pdf"]
            }
        }
    }
    
    init(type: AttachmentType, url: String, fileName: String, fileSize: Int64, mimeType: String, thumbnailData: Data? = nil, extractedText: String? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.type = type
        self.url = url
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.thumbnailData = thumbnailData
        self.extractedText = extractedText
        self.metadata = metadata
    }
}

struct MessageMetadata: Codable {
    let processingTime: TimeInterval?
    let confidence: Double?
    let sources: [String]?
    let analysisResults: [String: String]?
    
    init(processingTime: TimeInterval? = nil, confidence: Double? = nil, sources: [String]? = nil, analysisResults: [String: String]? = nil) {
        self.processingTime = processingTime
        self.confidence = confidence
        self.sources = sources
        self.analysisResults = analysisResults
    }
}

// Note: Gemini API models are defined in GeminiAIService.swift to avoid duplication

// MARK: - AI Error Types

enum AIError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case rateLimitExceeded
    case contentFiltered
    case serviceUnavailable
    case invalidImage
    case contextTooLarge
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .contentFiltered:
            return "Content was filtered by safety settings"
        case .serviceUnavailable:
            return "AI service is currently unavailable"
        case .invalidImage:
            return "Invalid image format"
        case .contextTooLarge:
            return "Context is too large for processing"
        }
    }
}

// MARK: - Quick Actions

struct QuickAction {
    let id: String
    let title: String
    let icon: String
    let prompt: String
    let category: QuickActionCategory
}

enum QuickActionCategory {
    case general
    case weather
    case crops
    case pests
    case soil
    case market
}

// MARK: - AI Service Protocol

protocol AIService {
    func sendMessage(_ message: String, context: AIContext) async throws -> AIResponse
    func sendMessageWithImage(_ message: String, image: PlatformImage, context: AIContext) async throws -> AIResponse
    func streamMessage(_ message: String, context: AIContext) -> AsyncThrowingStream<String, Error>
}

// MARK: - Platform Image Type

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#else
struct PlatformImage {}
#endif

// MARK: - AI Service Manager (Gemini 2.0 Implementation)

@MainActor
class AIServiceManager: ObservableObject {
    static let shared = AIServiceManager()
    private var geminiService: GeminiAIService?
    private var isInitialized = false
    
    private init() {
        // Lazy initialization - service will be created on first use
    }
    
    func getService() -> GeminiAIService? {
        if !isInitialized {
            // Initialize with API key from environment or Secrets
            if let apiKey = getAPIKey() {
                geminiService = GeminiAIService(apiKey: apiKey)
                isInitialized = true
            }
        }
        return geminiService
    }
    
    private func getAPIKey() -> String? {
        // Load from Secrets which handles both .env file and environment variables
        let key = Secrets.geminiAPIKey
        if key != "YOUR_GEMINI_API_KEY_HERE" && !key.isEmpty {
            return key
        }
        return nil
    }
    
    func configure(userManager: Any?, cropManager: Any?, weatherService: Any?, appState: Any?) {
        // Configuration placeholder - implement as needed
        // Using Any? to avoid import dependencies for now
    }
    
    func sendMessage(_ message: String, conversationHistory: [ChatMessage]) async throws -> AIResponse {
        guard let service = geminiService else {
            return AIResponse(
                content: "Please configure your Gemini API key to use AI features. Visit https://makersuite.google.com/app/apikey to get your key.",
                confidence: 0.0,
                sources: [],
                recommendations: ["Add GEMINI_API_KEY to your environment variables", "Or add it to Secrets.swift"],
                followUpQuestions: [],
                metadata: nil
            )
        }
        
        let context = AIContext.current()
        return try await service.sendMessage(message, context: context)
    }
    
    func getContextualQuickActions() -> [QuickAction] {
        return [
            QuickAction(
                id: "weather",
                title: "Weather",
                icon: "cloud.sun",
                prompt: "What's the current weather for my crops?",
                category: .weather
            ),
            QuickAction(
                id: "crops",
                title: "My Crops",
                icon: "leaf",
                prompt: "Show me my current crop status",
                category: .crops
            ),
            QuickAction(
                id: "market",
                title: "Market Prices",
                icon: "chart.line.uptrend.xyaxis",
                prompt: "What are the current market prices for my crops?",
                category: .market
            )
        ]
    }
}