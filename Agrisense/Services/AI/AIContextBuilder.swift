//
//  AIContextBuilder.swift
//  Agrisense
//
//  Built by AI Assistant
//

import Foundation
import CoreLocation

#if canImport(UIKit)
import UIKit
#endif

class AIContextBuilder {
    
    static let shared = AIContextBuilder()
    
    private init() {}
    
    func buildContextForCurrentUser() -> AIContext {
        var context = AIContext()
        context.deviceContext = buildDeviceContext()
        context.seasonalContext = buildSeasonalContext()
        return context
    }
    
    private func buildSeasonalContext() -> SeasonalContext {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        
        let season: AIModelsSeason
        switch currentMonth {
        case 3...5:
            season = .spring
        case 6...8:
            season = .summer
        case 9...11:
            season = .fall
        default:
            season = .winter
        }
        
        return SeasonalContext(
            currentSeason: season,
            weekInSeason: calendar.component(.weekOfYear, from: Date()),
            cropCalendar: [],
            seasonalTips: [],
            commonIssues: []
        )
    }
    
    private func buildDeviceContext() -> DeviceContext {
        #if canImport(UIKit)
        let systemVersion = UIDevice.current.systemVersion
        #else
        let systemVersion = "Unknown"
        #endif
        
        return DeviceContext(
            platform: "iOS",
            version: systemVersion,
            language: Locale.current.languageCode ?? "en",
            timezone: TimeZone.current.identifier,
            connectivity: "Unknown",
            batteryLevel: nil,
            location: nil
        )
    }
    
    func buildContextWithHistory(_ history: [ChatMessage]) -> AIContext {
        var context = buildContextForCurrentUser()
        context.conversationHistory = history
        return context
    }
    
    func validateContext(_ context: AIContext) -> ContextValidationResult {
        var issues: [String] = []
        var suggestions: [String] = []
        
        if context.userProfile == nil {
            issues.append("User profile not available")
            suggestions.append("Please complete your profile setup")
        }
        
        return ContextValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            suggestions: suggestions
        )
    }
    
    func getContextualQuickActions(_ context: AIContext) -> [QuickAction] {
        var actions: [QuickAction] = []
        
        actions.append(QuickAction(
            id: "weather_check",
            title: "Check Weather",
            icon: "cloud.sun",
            prompt: "What's the weather forecast for my crops?",
            category: .weather
        ))
        
        actions.append(QuickAction(
            id: "general_help",
            title: "General Help",
            icon: "questionmark.circle",
            prompt: "I need help with farming",
            category: .general
        ))
        
        return actions
    }
}
