//
//  NetworkMonitor.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import Foundation
import Network
import SwiftUI

// MARK: - Network Status

enum NetworkStatus: String, CaseIterable {
    case connected = "connected"
    case disconnected = "disconnected"
    case slow = "slow"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .connected:
            return LocalizationManager.shared.localizedString(for: "network_connected")
        case .disconnected:
            return LocalizationManager.shared.localizedString(for: "network_disconnected")
        case .slow:
            return LocalizationManager.shared.localizedString(for: "network_slow")
        case .unknown:
            return LocalizationManager.shared.localizedString(for: "network_unknown")
        }
    }
    
    var icon: String {
        switch self {
        case .connected:
            return "wifi"
        case .disconnected:
            return "wifi.slash"
        case .slow:
            return "wifi.exclamationmark"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .connected:
            return .green
        case .disconnected:
            return .red
        case .slow:
            return .orange
        case .unknown:
            return .gray
        }
    }
    
    var isConnected: Bool {
        return self == .connected || self == .slow
    }
}

// MARK: - Connection Type

enum ConnectionType: String {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .ethernet:
            return "Ethernet"
        case .unknown:
            return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "cable.connector"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

// MARK: - Network Monitor

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var status: NetworkStatus = .unknown
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false
    @Published var isConstrained = false
    @Published var lastConnectedTime: Date?
    @Published var connectionHistory: [NetworkEvent] = []
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isMonitoring = false
    private let maxHistoryCount = 100
    
    // Network performance tracking
    @Published var averageLatency: TimeInterval = 0
    @Published var lastLatencyCheck: Date?
    private var latencyHistory: [TimeInterval] = []
    private let maxLatencyHistory = 10
    
    nonisolated private init() {
        Task { @MainActor in
            self.startMonitoring()
        }
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateNetworkStatus(path)
            }
        }
        
        monitor.start(queue: queue)
        isMonitoring = true
        
        // Start periodic latency checks
        startLatencyMonitoring()
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        monitor.cancel()
        isMonitoring = false
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        let previousStatus = status
        
        // Determine connection status
        if path.status == .satisfied {
            // Check if connection is constrained or expensive (might indicate slow connection)
            if path.isConstrained || path.isExpensive {
                status = .slow
            } else {
                status = .connected
            }
            lastConnectedTime = Date()
        } else {
            status = .disconnected
        }
        
        // Update connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
        
        // Update connection properties
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // Log network event if status changed
        if previousStatus != status {
            let event = NetworkEvent(
                status: status,
                connectionType: connectionType,
                timestamp: Date(),
                isExpensive: isExpensive,
                isConstrained: isConstrained
            )
            
            connectionHistory.insert(event, at: 0)
            
            // Keep only recent events
            if connectionHistory.count > maxHistoryCount {
                connectionHistory = Array(connectionHistory.prefix(maxHistoryCount))
            }
            
            // Log status change
            print("🌐 Network status changed: \(previousStatus.rawValue) → \(status.rawValue)")
        }
    }
    
    // MARK: - Latency Monitoring
    
    private func startLatencyMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.checkLatency()
            }
        }
    }
    
    func checkLatency() async {
        guard status.isConnected else { return }
        
        let startTime = Date()
        
        do {
            // Use a reliable endpoint for latency testing
            let url = URL(string: "https://www.google.com")!
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 10.0
            
            let (_, _) = try await URLSession.shared.data(for: request)
            
            let latency = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                updateLatency(latency)
            }
            
        } catch {
            // If latency check fails, it might indicate slow connection
            await MainActor.run {
                if status == .connected {
                    status = .slow
                }
            }
        }
    }
    
    private func updateLatency(_ latency: TimeInterval) {
        latencyHistory.append(latency)
        
        // Keep only recent latency measurements
        if latencyHistory.count > maxLatencyHistory {
            latencyHistory = Array(latencyHistory.suffix(maxLatencyHistory))
        }
        
        // Calculate average latency
        averageLatency = latencyHistory.reduce(0, +) / Double(latencyHistory.count)
        lastLatencyCheck = Date()
        
        // Update status based on latency
        if averageLatency > 2.0 && status == .connected {
            status = .slow
        } else if averageLatency <= 1.0 && status == .slow {
            status = .connected
        }
    }
    
    // MARK: - Retry Mechanism
    
    func retryConnection() async -> Bool {
        // Force a latency check to verify connection
        await checkLatency()
        return status.isConnected
    }
    
    // MARK: - Connection Quality
    
    var connectionQuality: ConnectionQuality {
        if !status.isConnected {
            return .none
        }
        
        if isConstrained || isExpensive {
            return .poor
        }
        
        if averageLatency > 2.0 {
            return .poor
        } else if averageLatency > 1.0 {
            return .fair
        } else {
            return .good
        }
    }
    
    // MARK: - Utility Methods
    
    func getConnectionSummary() -> String {
        if !status.isConnected {
            return LocalizationManager.shared.localizedString(for: "network_offline")
        }
        
        var summary = connectionType.displayName
        
        if isExpensive {
            summary += " • " + LocalizationManager.shared.localizedString(for: "network_expensive")
        }
        
        if isConstrained {
            summary += " • " + LocalizationManager.shared.localizedString(for: "network_limited")
        }
        
        if averageLatency > 0 {
            summary += " • \(Int(averageLatency * 1000))ms"
        }
        
        return summary
    }
    
    deinit {
        if isMonitoring {
            monitor.cancel()
            isMonitoring = false
        }
    }
}

// MARK: - Connection Quality

enum ConnectionQuality: String, CaseIterable {
    case none = "none"
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    
    var displayName: String {
        switch self {
        case .none:
            return LocalizationManager.shared.localizedString(for: "connection_none")
        case .poor:
            return LocalizationManager.shared.localizedString(for: "connection_poor")
        case .fair:
            return LocalizationManager.shared.localizedString(for: "connection_fair")
        case .good:
            return LocalizationManager.shared.localizedString(for: "connection_good")
        }
    }
    
    var color: Color {
        switch self {
        case .none:
            return .red
        case .poor:
            return .red
        case .fair:
            return .orange
        case .good:
            return .green
        }
    }
    
    var icon: String {
        switch self {
        case .none:
            return "wifi.slash"
        case .poor:
            return "wifi.exclamationmark"
        case .fair:
            return "wifi"
        case .good:
            return "wifi"
        }
    }
}

// MARK: - Network Event

struct NetworkEvent: Identifiable, Codable {
    let id: UUID
    let status: NetworkStatus
    let connectionType: ConnectionType
    let timestamp: Date
    let isExpensive: Bool
    let isConstrained: Bool
    
    init(status: NetworkStatus, connectionType: ConnectionType, timestamp: Date, isExpensive: Bool, isConstrained: Bool) {
        self.id = UUID()
        self.status = status
        self.connectionType = connectionType
        self.timestamp = timestamp
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Network Status Extensions

extension NetworkStatus: Codable {}
extension ConnectionType: Codable {}