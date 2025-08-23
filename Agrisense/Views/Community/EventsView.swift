//
//  EventsView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct EventsView: View {
    @State private var events: [Event] = sampleEvents
    @State private var isLoading = false
    @State private var showNewEvent = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading events...")
                            .padding(.top, 40)
                    } else if events.isEmpty {
                        Text("No events yet")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(events) { event in
                            EventCard(event: event) { updatedEvent in
                                // Update local copy
                                if let idx = events.firstIndex(where: { $0.id == updatedEvent.id }) {
                                    events[idx] = updatedEvent
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            Button(action: { showNewEvent = true }) {
                Text("Create Event")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding()
            }
        }
        .onAppear { fetchEvents() }
        .sheet(isPresented: $showNewEvent) {
            NewEventView(onCreated: { fetchEvents() })
        }
    }

    private func fetchEvents() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("events").order(by: "date", descending: false).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("Error fetching events: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                events = documents.compactMap { doc in
                    let data = doc.data()
                    let title = data["title"] as? String ?? "Untitled"
                    let description = data["description"] as? String ?? ""
                    let timestamp = data["date"] as? TimeInterval ?? Date().timeIntervalSince1970
                    let location = data["location"] as? String ?? ""
                    let organizer = data["organizer"] as? String ?? ""
                    let organizerId = data["organizerId"] as? String ?? ""
                    let attendees = data["attendees"] as? Int ?? 0
                    let maxAttendees = data["maxAttendees"] as? Int ?? 0
                    let attendeesList = data["attendeesList"] as? [String] ?? []
                    let typeRaw = data["type"] as? String ?? "webinar"
                    let type = EventType(rawValue: typeRaw) ?? .webinar
                    let isAttending = Auth.auth().currentUser != nil && attendeesList.contains(Auth.auth().currentUser!.uid)

                    return Event(firestoreId: doc.documentID, title: title, description: description, date: Date(timeIntervalSince1970: timestamp), location: location, organizer: organizer, organizerId: organizerId, attendees: attendees, maxAttendees: maxAttendees, attendeesList: attendeesList, isAttending: isAttending, type: type)
                }
            }
        }
    }
}



struct EventCard: View {
    @State var event: Event
    var onChange: ((Event) -> Void)? = nil

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
            Button(action: { toggleAttendance() }) {
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

    private func toggleAttendance() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let postRef = db.collection("events").document(event.firestoreId)

        if event.attendeesList.contains(uid) {
            // Leave
            postRef.setData([
                "attendees": FieldValue.increment(Int64(-1)),
                "attendeesList": FieldValue.arrayRemove([uid])
            ], merge: true) { error in
                if let error = error { print("Error leaving event: \(error)") }
            }
            event.attendees = max(0, event.attendees - 1)
            event.attendeesList.removeAll(where: { $0 == uid })
            event.isAttending = false
        } else {
            // Join
            guard event.maxAttendees == 0 || event.attendees < event.maxAttendees else { return }
            postRef.setData([
                "attendees": FieldValue.increment(Int64(1)),
                "attendeesList": FieldValue.arrayUnion([uid])
            ], merge: true) { error in
                if let error = error { print("Error joining event: \(error)") }
            }
            event.attendees += 1
            event.attendeesList.append(uid)
            event.isAttending = true
        }

        onChange?(event)
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

struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var maxAttendees = ""
    @State private var type: EventType = .workshop
    @EnvironmentObject var userManager: UserManager
    let onCreated: (() -> Void)?

    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Location", text: $location)
                    TextField("Max Attendees (optional)", text: $maxAttendees)
                        .keyboardType(.numberPad)
                    Picker("Type", selection: $type) {
                        ForEach(EventType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createEvent() }
                        .disabled(title.isEmpty || description.isEmpty)
                }
            }
        }
    }

    private func createEvent() {
        guard let user = userManager.currentUser else { return }
        let db = Firestore.firestore()
        let attendeesInt = Int(maxAttendees) ?? 0
        let docRef = db.collection("events").document()
        let data: [String: Any] = [
            "title": title,
            "description": description,
            "date": date.timeIntervalSince1970,
            "location": location,
            "organizer": user.name,
            "organizerId": user.id,
            "attendees": 0,
            "maxAttendees": attendeesInt,
            "attendeesList": [],
            "type": type.rawValue
        ]

        docRef.setData(data) { error in
            if let error = error {
                print("Error creating event: \(error)")
            } else {
                onCreated?()
                dismiss()
            }
        }
    }
}

#Preview {
    EventsView()
}
