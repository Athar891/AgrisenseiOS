//
//  NetworkMonitorDemoView.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import SwiftUI

// MARK: - Network Monitor Demo View

struct NetworkMonitorDemoView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var retryManager = RetryManager.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var showingNetworkHistory = false
    @State private var simulatedOffline = false
    @State private var testResults: [String] = []
    @State private var isTestingRetry = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Network Monitoring System Demo")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    
                    // Current Network Status
                    networkStatusSection
                    
                    // Offline Indicators Demo
                    offlineIndicatorsSection
                    
                    // Retry Mechanism Demo
                    retryMechanismSection
                    
                    // Network History
                    networkHistorySection
                    
                    // Test Controls
                    testControlsSection
                }
                .padding(.bottom, 100)
            }
            .navigationTitle("Network Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("History") {
                        showingNetworkHistory = true
                    }
                }
            }
            .sheet(isPresented: $showingNetworkHistory) {
                NetworkHistoryView(networkMonitor: networkMonitor)
            }
        }
        .offlineBanner() // Apply offline banner to entire view
    }
    
    // MARK: - Network Status Section
    
    private var networkStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Network Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            NetworkStatusCard(networkMonitor: networkMonitor)
            
            HStack(spacing: 12) {
                NetworkStatusIndicator(networkMonitor: networkMonitor, showLabel: true, compact: false)
                
                Spacer()
                
                ConnectionQualityBadge(networkMonitor: networkMonitor)
            }
            
            // Connection Details
            if networkMonitor.status.isConnected {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connection Details")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    NetworkDetailRow(label: "Type", value: networkMonitor.connectionType.displayName)
                    NetworkDetailRow(label: "Quality", value: networkMonitor.connectionQuality.displayName)
                    NetworkDetailRow(label: "Expensive", value: networkMonitor.isExpensive ? "Yes" : "No")
                    NetworkDetailRow(label: "Constrained", value: networkMonitor.isConstrained ? "Yes" : "No")
                    
                    if networkMonitor.averageLatency > 0 {
                        NetworkDetailRow(label: "Avg Latency", value: "\(Int(networkMonitor.averageLatency * 1000))ms")
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Offline Indicators Section
    
    private var offlineIndicatorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Offline Indicators")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("These components automatically show when the device goes offline.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                // Compact indicators
                HStack(spacing: 12) {
                    NetworkStatusIndicator(networkMonitor: networkMonitor, showLabel: true, compact: true)
                    NetworkStatusIndicator(networkMonitor: networkMonitor, showLabel: false, compact: true)
                    ConnectionQualityBadge(networkMonitor: networkMonitor)
                }
                
                // Offline mode toggle
                OfflineModeToggle(networkMonitor: networkMonitor)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Retry Mechanism Section
    
    private var retryMechanismSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Retry Mechanism")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Automatic retry with exponential backoff for failed network operations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                // Test buttons
                HStack(spacing: 12) {
                    LoadingButton(
                        title: "Test Retry",
                        state: isTestingRetry ? .loading : .idle
                    ) {
                        testRetryMechanism()
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button("Clear Results") {
                        testResults.removeAll()
                    }
                    .buttonStyle(.bordered)
                }
                
                // Active retries
                if !retryManager.activeRetries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active Retries:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(Array(retryManager.activeRetries.values), id: \.id) { operation in
                            RetryOperationRow(operation: operation) {
                                retryManager.cancelRetry(operationId: operation.id)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
                
                // Test results
                if !testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test Results:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(testResults.indices, id: \.self) { index in
                            Text(testResults[index])
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Network History Section
    
    private var networkHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Network Events")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingNetworkHistory = true
                }
                .font(.subheadline)
                .foregroundColor(.green)
            }
            
            if networkMonitor.connectionHistory.isEmpty {
                Text("No network events recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(networkMonitor.connectionHistory.prefix(3)) { event in
                        NetworkEventRow(event: event)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Test Controls Section
    
    private var testControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test Controls")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Simulate different network conditions for testing.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                DemoActionButton(
                    title: "Check Latency",
                    subtitle: "Test current connection speed",
                    color: .blue
                ) {
                    Task {
                        await networkMonitor.checkLatency()
                        testResults.append("Latency check completed: \(Int(networkMonitor.averageLatency * 1000))ms")
                    }
                }
                
                DemoActionButton(
                    title: "Simulate Network Error",
                    subtitle: "Test error handling",
                    color: .red
                ) {
                    simulateNetworkError()
                }
                
                DemoActionButton(
                    title: "Test Batch Retry",
                    subtitle: "Test multiple operations",
                    color: .orange
                ) {
                    testBatchRetry()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Test Methods
    
    private func testRetryMechanism() {
        isTestingRetry = true
        testResults.append("Starting retry test...")
        
        Task {
            let result = await retryManager.retry(
                operation: {
                    // Simulate a failing operation that eventually succeeds
                    if Bool.random() {
                        throw AgriSenseError.networkUnavailable
                    }
                    return "Operation succeeded!"
                },
                configuration: .default,
                operationId: "test_retry"
            )
            
            await MainActor.run {
                isTestingRetry = false
                
                switch result {
                case .success(let value):
                    testResults.append("✅ Retry succeeded: \(value)")
                case .failure(let error, let attempts):
                    testResults.append("❌ Retry failed after \(attempts) attempts: \(error.localizedDescription)")
                case .cancelled:
                    testResults.append("⏹️ Retry was cancelled")
                }
            }
        }
    }
    
    private func simulateNetworkError() {
        testResults.append("Simulating network error...")
        
        Task {
            let result = await retryManager.retryWhenOnline(
                operation: {
                    throw AgriSenseError.networkUnavailable
                },
                configuration: .conservative,
                operationId: "simulate_error"
            )
            
            await MainActor.run {
                switch result {
                case .success:
                    testResults.append("✅ Network error resolved")
                case .failure(let error, let attempts):
                    testResults.append("❌ Network error persisted after \(attempts) attempts: \(error.localizedDescription)")
                case .cancelled:
                    testResults.append("⏹️ Network error simulation cancelled")
                }
            }
        }
    }
    
    private func testBatchRetry() {
        testResults.append("Starting batch retry test...")
        
        Task {
            let operations = [
                ("op1", { () async throws -> String in
                    if Bool.random() { throw AgriSenseError.networkUnavailable }
                    return "Operation 1 success"
                }),
                ("op2", { () async throws -> String in
                    if Bool.random() { throw AgriSenseError.operationTimeout }
                    return "Operation 2 success"
                }),
                ("op3", { () async throws -> String in
                    return "Operation 3 success"
                })
            ]
            
            let results = await retryManager.retryBatch(
                operations: operations,
                configuration: .default,
                maxConcurrent: 2
            )
            
            await MainActor.run {
                for (id, result) in results {
                    switch result {
                    case .success(let value):
                        testResults.append("✅ \(id): \(value)")
                    case .failure(let error, let attempts):
                        testResults.append("❌ \(id): Failed after \(attempts) attempts - \(error.localizedDescription)")
                    case .cancelled:
                        testResults.append("⏹️ \(id): Cancelled")
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views

struct NetworkDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct RetryOperationRow: View {
    @ObservedObject var operation: RetryOperation
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Retry Operation")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Attempt \(operation.currentAttempt) of \(operation.configuration.maxAttempts)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ProgressView(value: operation.progress)
                    .frame(width: 100)
            }
            
            Spacer()
            
            if let timeUntilNext = operation.timeUntilNextRetry, timeUntilNext > 0 {
                Text("\(Int(timeUntilNext))s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button("Cancel") {
                onCancel()
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NetworkMonitorDemoView()
        .environmentObject(LocalizationManager.shared)
}