//
//  DiscussionsView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct DiscussionsView: View {
    let searchText: String
    @State private var selectedCategory: DiscussionCategory = .all
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DiscussionCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Discussions List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredDiscussions) { discussion in
                        DiscussionCard(discussion: discussion)
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredDiscussions: [Discussion] {
        var discussions = sampleDiscussions
        
        if !searchText.isEmpty {
            discussions = discussions.filter { discussion in
                discussion.title.localizedCaseInsensitiveContains(searchText) ||
                discussion.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedCategory != .all {
            discussions = discussions.filter { $0.category == selectedCategory }
        }
        
        return discussions
    }
}

struct CategoryChip: View {
    let category: DiscussionCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.systemGray6))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DiscussionCard: View {
    let discussion: Discussion
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(discussion.author)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(discussion.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(discussion.category.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(discussion.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(discussion.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Actions
                HStack {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: discussion.isLiked ? "heart.fill" : "heart")
                                .foregroundColor(discussion.isLiked ? .red : .secondary)
                            Text("\(discussion.likes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .foregroundColor(.secondary)
                            Text("\(discussion.replies)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            DiscussionDetailView(discussion: discussion)
        }
    }
}

struct DiscussionDetailView: View {
    let discussion: Discussion
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Original post
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(discussion.author)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(discussion.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Text(discussion.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(discussion.content)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Replies would go here
                    Text("Replies coming soon...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("Discussion")
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
    DiscussionsView(searchText: "")
}
