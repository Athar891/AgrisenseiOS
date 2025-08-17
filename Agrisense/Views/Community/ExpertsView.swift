//
//  ExpertsView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct ExpertsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sampleExperts) { expert in
                    ExpertCard(expert: expert)
                }
            }
            .padding()
        }
    }
}



struct ExpertCard: View {
    let expert: Expert
    @State private var showingProfile = false
    
    var body: some View {
        Button(action: { showingProfile = true }) {
            HStack(spacing: 16) {
                // Avatar
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(expert.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(expert.specialty)
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Text(expert.bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", expert.rating))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Text("(\(expert.reviews) reviews)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(expert.isAvailable ? "Available" : "Busy")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(expert.isAvailable ? .green : .orange)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingProfile) {
            ExpertProfileView(expert: expert)
        }
    }
}

struct ExpertProfileView: View {
    let expert: Expert
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 4) {
                            Text(expert.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(expert.specialty)
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text(String(format: "%.1f", expert.rating))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Rating")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(expert.reviews)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("Reviews")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Bio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(expert.bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Contact Button
                    Button(action: {}) {
                        Text("Contact Expert")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Expert Profile")
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

#Preview {
    ExpertsView()
}
