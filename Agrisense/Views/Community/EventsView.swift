//
//  EventsView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct EventsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sampleEvents) { event in
                    EventCard(event: event)
                }
            }
            .padding()
        }
    }
}



struct EventCard: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: event.type.icon)
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.type.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            
            // Description
            Text(event.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Details
            VStack(spacing: 8) {
                DetailRow(icon: "calendar", text: event.date, style: .date)
                DetailRow(icon: "location", text: event.location)
                DetailRow(icon: "person", text: "\(event.attendees)/\(event.maxAttendees) attending")
            }
            
            // Action Button
            Button(action: {}) {
                Text(event.isAttending ? "Attending" : "Join Event")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(event.isAttending ? .green : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(event.isAttending ? Color.green.opacity(0.1) : Color.green)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct DetailRow: View {
    let icon: String
    let text: Any
    let style: DetailStyle
    
    init(icon: String, text: Any, style: DetailStyle = .text) {
        self.icon = icon
        self.text = text
        self.style = style
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            switch style {
            case .text:
                Text(text as! String)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            case .date:
                Text(text as! Date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

enum DetailStyle {
    case text
    case date
}

#Preview {
    EventsView()
}
