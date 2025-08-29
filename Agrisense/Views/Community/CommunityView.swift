//
//  CommunityView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localizationManager: LocalizationManager
    @State private var selectedTab: CommunityTab = .discussions
    @State private var showingNewPost = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, isFocused: $isSearchFocused)
                
                // Tab Selector
                TabSelector(selectedTab: $selectedTab, onTabChange: dismissKeyboard)
                
                // Content - Using conditional views instead of nested TabView
                Group {
                    switch selectedTab {
                    case .discussions:
                        DiscussionsView(searchText: searchText, refreshTrigger: refreshTrigger)
                    case .events:
                        EventsView()
                    case .experts:
                        ExpertsView()
                    case .groups:
                        GroupsView()
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                .onTapGesture {
                    dismissKeyboard()
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "community_title"))
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
                NewPostView(onPostCreated: {
                    refreshTrigger = UUID()
                })
            }
            .onChange(of: appState.selectedTab) { _, newTab in
                if newTab != .community {
                    dismissKeyboard()
                }
            }
            .onDisappear {
                dismissKeyboard()
            }
        }
    }
    
    private func dismissKeyboard() {
        isSearchFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

enum CommunityTab: String, CaseIterable {
    case discussions = "discussions"
    case events = "events"
    case experts = "experts"
    case groups = "groups"
    
    func title(localizationManager: LocalizationManager) -> String {
        switch self {
        case .discussions:
            return localizationManager.localizedString(for: "community_discussions")
        case .events:
            return localizationManager.localizedString(for: "community_events")
        case .experts:
            return localizationManager.localizedString(for: "community_experts")
        case .groups:
            return localizationManager.localizedString(for: "community_groups")
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
    @EnvironmentObject var localizationManager: LocalizationManager
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(localizationManager.localizedString(for: "search_community"), text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .onSubmit {
                    isFocused = false
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    isFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
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
    let onTabChange: () -> Void
    
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
                            onTabChange()
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
    @EnvironmentObject var localizationManager: LocalizationManager
    let tab: CommunityTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .secondary)
                
                Text(tab.title(localizationManager: localizationManager))
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
