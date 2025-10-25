//
//  WebSearchService.swift
//  Agrisense
//
//  Created by GitHub Copilot on 25/10/25.
//  Real-time web search for agricultural information, product links, and research
//

import Foundation

// MARK: - Web Search Service

@MainActor
class WebSearchService: ObservableObject {
    @Published var isSearching = false
    @Published var lastSearchResults: [WebSearchResult] = []
    @Published var errorMessage: String?
    
    // Using DuckDuckGo Instant Answer API (free, no API key required)
    // For production, consider using Google Custom Search API or Bing Search API
    private let searchBaseURL = "https://api.duckduckgo.com/"
    
    /// Perform a web search for agricultural information
    func search(query: String) async -> [WebSearchResult] {
        guard !query.isEmpty else {
            print("⚠️ Empty search query")
            return []
        }
        
        isSearching = true
        errorMessage = nil
        
        print("🔍 Searching web for: \(query)")
        
        do {
            let results = try await performDuckDuckGoSearch(query: query)
            
            await MainActor.run {
                self.lastSearchResults = results
                self.isSearching = false
            }
            
            print("✅ Found \(results.count) search results")
            return results
            
        } catch {
            print("❌ Web search error: \(error)")
            await MainActor.run {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                self.isSearching = false
            }
            return []
        }
    }
    
    /// Search specifically for product purchase links
    func searchProducts(productName: String, category: String = "agriculture") async -> [WebSearchResult] {
        let query = "\(productName) \(category) buy online india"
        return await search(query: query)
    }
    
    /// Search for government schemes and programs
    func searchGovernmentSchemes(topic: String) async -> [WebSearchResult] {
        let query = "india government scheme \(topic) farmers agriculture"
        return await search(query: query)
    }
    
    /// Search for research articles and guides
    func searchResearch(topic: String) async -> [WebSearchResult] {
        let query = "\(topic) agriculture research guide best practices"
        return await search(query: query)
    }
    
    // MARK: - DuckDuckGo Search Implementation
    
    private func performDuckDuckGoSearch(query: String) async throws -> [WebSearchResult] {
        // DuckDuckGo Instant Answer API
        var components = URLComponents(string: searchBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "no_html", value: "1"),
            URLQueryItem(name: "skip_disambig", value: "1")
        ]
        
        guard let url = components?.url else {
            throw WebSearchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw WebSearchError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse DuckDuckGo response
        let ddgResponse = try JSONDecoder().decode(DuckDuckGoResponse.self, from: data)
        
        var results: [WebSearchResult] = []
        
        // Add abstract result if available
        if let abstract = ddgResponse.Abstract, !abstract.isEmpty,
           let abstractURL = ddgResponse.AbstractURL, !abstractURL.isEmpty {
            results.append(WebSearchResult(
                title: ddgResponse.Heading ?? "Search Result",
                url: abstractURL,
                snippet: abstract,
                source: "DuckDuckGo"
            ))
        }
        
        // Add related topics
        if let relatedTopics = ddgResponse.RelatedTopics {
            for topic in relatedTopics.prefix(5) {
                if let text = topic.Text, !text.isEmpty,
                   let firstURL = topic.FirstURL, !firstURL.isEmpty {
                    results.append(WebSearchResult(
                        title: extractTitle(from: text),
                        url: firstURL,
                        snippet: text,
                        source: "DuckDuckGo"
                    ))
                }
            }
        }
        
        return results
    }
    
    private func extractTitle(from text: String) -> String {
        // Extract title from text (usually first part before " - ")
        let components = text.components(separatedBy: " - ")
        return components.first ?? text
    }
}

// MARK: - Web Search Models

struct WebSearchResult: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let snippet: String
    let source: String
    
    init(title: String, url: String, snippet: String, source: String) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.snippet = snippet
        self.source = source
    }
}

// MARK: - DuckDuckGo API Response Models

struct DuckDuckGoResponse: Codable {
    let Abstract: String?
    let AbstractText: String?
    let AbstractSource: String?
    let AbstractURL: String?
    let Heading: String?
    let RelatedTopics: [DDGRelatedTopic]?
    let Results: [DDGResult]?
}

struct DDGRelatedTopic: Codable {
    let Text: String?
    let FirstURL: String?
    let Icon: DDGIcon?
}

struct DDGResult: Codable {
    let Text: String?
    let FirstURL: String?
}

struct DDGIcon: Codable {
    let URL: String?
    let Width: Int?
    let Height: Int?
}

// MARK: - Error Types

enum WebSearchError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noResults
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid search URL"
        case .invalidResponse:
            return "Invalid response from search service"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .noResults:
            return "No search results found"
        case .rateLimitExceeded:
            return "Search rate limit exceeded"
        }
    }
}
