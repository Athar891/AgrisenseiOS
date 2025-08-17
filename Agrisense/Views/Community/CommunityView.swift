//
//  CommunityView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var selectedTab: CommunityTab = .discussions
    @State private var showingNewPost = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                
                // Tab Selector
                TabSelector(selectedTab: $selectedTab)
                
                // Content - Using conditional views instead of nested TabView
                Group {
                    switch selectedTab {
                    case .discussions:
                        DiscussionsView(searchText: searchText)
                    case .events:
                        EventsView()
                    case .experts:
                        ExpertsView()
                    case .groups:
                        GroupsView()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewPost = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showingNewPost) {
                NewPostView()
            }
        }
    }
}

enum CommunityTab: String, CaseIterable {
    case discussions = "discussions"
    case events = "events"
    case experts = "experts"
    case groups = "groups"
    
    var title: String {
        switch self {
        case .discussions:
            return "Discussions"
        case .events:
            return "Events"
        case .experts:
            return "Experts"
        case .groups:
            return "Groups"
        }
    }
    
    var icon: String {
        switch self {
        case .discussions:
            return "bubble.left.and.bubble.right.fill"
        case .events:
            return "calendar"
        case .experts:
            return "person.badge.plus"
        case .groups:
            return "person.3.fill"
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search community...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct TabSelector: View {
    @Binding var selectedTab: CommunityTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(CommunityTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct TabButton: View {
    let tab: CommunityTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .secondary)
                
                Text(tab.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .green : .secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CommunityView()
        .environmentObject(UserManager())
}
