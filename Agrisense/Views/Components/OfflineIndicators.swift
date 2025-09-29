//
//  OfflineIndicators.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import SwiftUI

// MARK: - Offline Banner

struct OfflineBanner: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var isVisible = true
    @State private var showDetails = false
    
    var body: some View {
        if !networkMonitor.status.isConnected && isVisible {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: networkMonitor.status.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizationManager.localizedString(for: "offline_mode"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(localizationManager.localizedString(for: "offline_message"))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(showDetails ? nil : 1)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDetails.toggle()
                        }
                    }) {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                }
                .padding()
                .background(networkMonitor.status.color)
                
                if showDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Last connected:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            if let lastConnected = networkMonitor.lastConnectedTime {
                                Text(lastConnected, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.white)
                            } else {
                                Text("Never")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        HStack {
                            Text(localizationManager.localizedString(for: "offline_cached_data"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    let _ = await networkMonitor.retryConnection()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Retry")
                                }
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .background(networkMonitor.status.color.opacity(0.9))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Network Status Indicator

struct NetworkStatusIndicator: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    let showLabel: Bool
    let compact: Bool
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor.shared, showLabel: Bool = true, compact: Bool = false) {
        self.networkMonitor = networkMonitor
        self.showLabel = showLabel
        self.compact = compact
    }
    
    var body: some View {
        HStack(spacing: compact ? 4 : 8) {
            Image(systemName: networkMonitor.connectionQuality.icon)
                .foregroundColor(networkMonitor.connectionQuality.color)
                .font(.system(size: compact ? 12 : 14, weight: .medium))
            
            if showLabel {
                if compact {
                    Text(networkMonitor.status.isConnected ? "Online" : "Offline")
                        .font(.caption2)
                        .foregroundColor(networkMonitor.connectionQuality.color)
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(networkMonitor.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(networkMonitor.connectionQuality.color)
                        
                        if networkMonitor.status.isConnected {
                            Text(networkMonitor.connectionType.displayName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(networkMonitor.connectionQuality.color.opacity(0.1))
        .cornerRadius(compact ? 8 : 12)
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 8 : 12)
                .stroke(networkMonitor.connectionQuality.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Connection Quality Badge

struct ConnectionQualityBadge: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor.shared) {
        self.networkMonitor = networkMonitor
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Signal strength bars
            HStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(barColor(for: index))
                        .frame(width: 3, height: CGFloat(4 + index * 2))
                        .cornerRadius(1)
                }
            }
            
            Text(networkMonitor.connectionQuality.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(networkMonitor.connectionQuality.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(networkMonitor.connectionQuality.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func barColor(for index: Int) -> Color {
        let quality = networkMonitor.connectionQuality
        
        switch quality {
        case .none:
            return .gray.opacity(0.3)
        case .poor:
            return index == 0 ? .red : .gray.opacity(0.3)
        case .fair:
            return index <= 1 ? .orange : .gray.opacity(0.3)
        case .good:
            return index <= 2 ? .green : .gray.opacity(0.3)
        }
    }
}

// MARK: - Offline Mode Toggle

struct OfflineModeToggle: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var isOfflineModeEnabled = false
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor.shared) {
        self.networkMonitor = networkMonitor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizationManager.localizedString(for: "offline_mode"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(localizationManager.localizedString(for: "working_offline"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isOfflineModeEnabled)
                    .labelsHidden()
            }
            
            if isOfflineModeEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Offline features:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        OfflineFeatureRow(icon: "leaf.fill", title: "View saved crops", isAvailable: true)
                        OfflineFeatureRow(icon: "cart.fill", title: "Browse cached products", isAvailable: true)
                        OfflineFeatureRow(icon: "person.3.fill", title: "Read saved posts", isAvailable: true)
                        OfflineFeatureRow(icon: "sparkles", title: "AI Assistant", isAvailable: false)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.3), value: isOfflineModeEnabled)
    }
}

// MARK: - Offline Feature Row

struct OfflineFeatureRow: View {
    let icon: String
    let title: String
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(isAvailable ? .green : .gray)
                .font(.caption)
                .frame(width: 16)
            
            Text(title)
                .font(.caption)
                .foregroundColor(isAvailable ? .primary : .secondary)
            
            Spacer()
            
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isAvailable ? .green : .red)
                .font(.caption2)
        }
    }
}

// MARK: - Network History View

struct NetworkHistoryView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @Environment(\.dismiss) private var dismiss
    
    init(networkMonitor: NetworkMonitor = NetworkMonitor.shared) {
        self.networkMonitor = networkMonitor
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    NetworkStatusCard(networkMonitor: networkMonitor)
                } header: {
                    Text("Current Status")
                }
                
                Section {
                    if networkMonitor.connectionHistory.isEmpty {
                        Text("No connection events recorded")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .padding()
                    } else {
                        ForEach(networkMonitor.connectionHistory) { event in
                            NetworkEventRow(event: event)
                        }
                    }
                } header: {
                    Text("Connection History")
                }
            }
            .navigationTitle("Network Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Network Status Card

struct NetworkStatusCard: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: networkMonitor.status.icon)
                    .foregroundColor(networkMonitor.status.color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(networkMonitor.status.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(networkMonitor.getConnectionSummary())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ConnectionQualityBadge(networkMonitor: networkMonitor)
            }
            
            if networkMonitor.status.isConnected {
                VStack(spacing: 8) {
                    if networkMonitor.averageLatency > 0 {
                        HStack {
                            Text("Average Latency:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(networkMonitor.averageLatency * 1000))ms")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    
                    if let lastCheck = networkMonitor.lastLatencyCheck {
                        HStack {
                            Text("Last Check:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(lastCheck, style: .relative)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Network Event Row

struct NetworkEventRow: View {
    let event: NetworkEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.status.icon)
                .foregroundColor(event.status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.status.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(event.connectionType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if event.isExpensive {
                        Text("• Expensive")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if event.isConstrained {
                        Text("• Limited")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Text(event.timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Extensions

extension View {
    func offlineBanner() -> some View {
        VStack(spacing: 0) {
            OfflineBanner(networkMonitor: NetworkMonitor.shared)
            self
        }
    }
    
    func networkStatusIndicator(showLabel: Bool = true, compact: Bool = false) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Spacer()
                NetworkStatusIndicator(showLabel: showLabel, compact: compact)
            }
            self
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        OfflineBanner(networkMonitor: NetworkMonitor.shared)
        
        NetworkStatusIndicator()
        
        ConnectionQualityBadge()
        
        OfflineModeToggle()
    }
    .padding()
    .environmentObject(LocalizationManager.shared)
}