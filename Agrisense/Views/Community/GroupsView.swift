//
//  GroupsView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct GroupsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sampleGroups) { group in
                    GroupCard(group: group)
                }
            }
            .padding()
        }
    }
}



struct GroupCard: View {
    let group: CommunityGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(group.category)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text("\(group.members) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Description
            Text(group.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Action Button
            Button(action: {}) {
                Text(group.isMember ? "Leave Group" : "Join Group")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(group.isMember ? .red : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(group.isMember ? Color.red.opacity(0.1) : Color.green)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    GroupsView()
}
