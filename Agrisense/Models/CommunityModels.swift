//
//  CommunityModels.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import Foundation

enum DiscussionCategory: String, CaseIterable {
    case all = "all"
    case farming = "farming"
    case technology = "technology"
    case market = "market"
    case weather = "weather"
    case equipment = "equipment"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .farming:
            return "Farming"
        case .technology:
            return "Technology"
        case .market:
            return "Market"
        case .weather:
            return "Weather"
        case .equipment:
            return "Equipment"
        case .other:
            return "Other"
        }
    }
}

struct Discussion: Identifiable {
    var id = UUID()
    let firestoreId: String
    let title: String
    let content: String
    let author: String
    let category: DiscussionCategory
    let timestamp: Date
    let replies: Int
    let likes: Int
    let isLiked: Bool
    let authorAvatar: String?
    let userId: String
    let imageUrl: String?
    let likedByUsers: [String]
    
    init(id: UUID = UUID(), firestoreId: String = "", title: String, content: String, author: String, category: DiscussionCategory, timestamp: Date, replies: Int = 0, likes: Int = 0, isLiked: Bool = false, authorAvatar: String? = nil, userId: String = "", imageUrl: String? = nil, likedByUsers: [String] = []) {
        self.id = id
        self.firestoreId = firestoreId
        self.title = title
        self.content = content
        self.author = author
        self.category = category
        self.timestamp = timestamp
        self.replies = replies
        self.likes = likes
        self.isLiked = isLiked
        self.authorAvatar = authorAvatar
        self.userId = userId
        self.imageUrl = imageUrl
        self.likedByUsers = likedByUsers
    }
}

struct Event: Identifiable {
    var id = UUID()
    let firestoreId: String
    let title: String
    let description: String
    let date: Date
    let location: String
    let organizer: String
    let organizerId: String
    var attendees: Int
    var maxAttendees: Int
    var attendeesList: [String]
    var isAttending: Bool
    let type: EventType
    // New optional fields
    let registrationDeadline: Date?
    let isFree: Bool
    let price: Double?
    let currency: String?
    let tags: [String]
    let speakers: [String]

    init(firestoreId: String = "", id: UUID = UUID(), title: String, description: String, date: Date, location: String, organizer: String, organizerId: String = "", attendees: Int = 0, maxAttendees: Int = 0, attendeesList: [String] = [], isAttending: Bool = false, type: EventType, registrationDeadline: Date? = nil, isFree: Bool = true, price: Double? = nil, currency: String? = nil, tags: [String] = [], speakers: [String] = []) {
        self.id = id
        self.firestoreId = firestoreId
        self.title = title
        self.description = description
        self.date = date
        self.location = location
        self.organizer = organizer
        self.organizerId = organizerId
        self.attendees = attendees
        self.maxAttendees = maxAttendees
        self.attendeesList = attendeesList
        self.isAttending = isAttending
        self.type = type
        self.registrationDeadline = registrationDeadline
        self.isFree = isFree
        self.price = price
        self.currency = currency
        self.tags = tags
        self.speakers = speakers
    }
}

enum EventType: String, CaseIterable {
    case workshop = "workshop"
    case conference = "conference"
    case fieldDay = "field_day"
    case webinar = "webinar"
    
    var displayName: String {
        switch self {
        case .workshop:
            return "Workshop"
        case .conference:
            return "Conference"
        case .fieldDay:
            return "Field Day"
        case .webinar:
            return "Webinar"
        }
    }
    
    var icon: String {
        switch self {
        case .workshop:
            return "hammer.fill"
        case .conference:
            return "person.3.fill"
        case .fieldDay:
            return "leaf.fill"
        case .webinar:
            return "video.fill"
        }
    }
}

struct Expert: Identifiable {
    let id = UUID()
    let name: String
    let specialty: String
    let bio: String
    let rating: Double
    let reviews: Int
    let isAvailable: Bool
    let avatar: String?
}

struct CommunityGroup: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let members: Int
    let isMember: Bool
    let category: String
    let avatar: String?
}

struct Comment: Identifiable {
    let id: String
    let author: String
    let userId: String
    let content: String
    let timestamp: Date
}

// Sample Data
let sampleDiscussions = [
    Discussion(
        title: "Best practices for organic tomato farming",
        content: "I've been growing tomatoes for 5 years and wanted to share some tips that have worked well for me...",
        author: "Sarah Johnson",
        category: .farming,
        timestamp: Date().addingTimeInterval(-3600),
        replies: 12,
        likes: 24,
        isLiked: false,
        authorAvatar: nil
    ),
    Discussion(
        title: "Weather forecast for this week",
        content: "Heavy rain expected in the Midwest. How are you preparing your crops?",
        author: "Mike Chen",
        category: .weather,
        timestamp: Date().addingTimeInterval(-7200),
        replies: 8,
        likes: 15,
        isLiked: true,
        authorAvatar: nil
    ),
    Discussion(
        title: "New irrigation system recommendations",
        content: "Looking to upgrade my irrigation system. Any recommendations for smart irrigation solutions?",
        author: "David Wilson",
        category: .equipment,
        timestamp: Date().addingTimeInterval(-10800),
        replies: 6,
        likes: 9,
        isLiked: false,
        authorAvatar: nil
    )
]

let sampleEvents = [
    Event(
        title: "Organic Farming Workshop",
        description: "Learn the latest techniques in organic farming from industry experts.",
        date: Date().addingTimeInterval(86400),
        location: "Iowa State University",
        organizer: "Iowa Organic Association",
        attendees: 45,
        maxAttendees: 60,
        isAttending: false,
        type: .workshop
    ),
    Event(
        title: "Agricultural Technology Conference",
        description: "Discover cutting-edge technologies transforming modern agriculture.",
        date: Date().addingTimeInterval(172800),
        location: "Virtual Event",
        organizer: "AgTech Innovation",
        attendees: 120,
        maxAttendees: 200,
        isAttending: true,
        type: .conference
    )
]

let sampleExperts = [
    Expert(
        name: "Dr. Emily Rodriguez",
        specialty: "Soil Science",
        bio: "PhD in Agricultural Sciences with 15+ years of experience in soil health and crop management.",
        rating: 4.9,
        reviews: 127,
        isAvailable: true,
        avatar: nil
    ),
    Expert(
        name: "Mark Thompson",
        specialty: "Organic Farming",
        bio: "Certified organic farmer and consultant with expertise in sustainable agriculture practices.",
        rating: 4.8,
        reviews: 89,
        isAvailable: false,
        avatar: nil
    )
]

let sampleGroups = [
    CommunityGroup(
        name: "Organic Farmers Network",
        description: "Connect with fellow organic farmers, share experiences, and learn best practices.",
        members: 1_247,
        isMember: true,
        category: "Farming",
        avatar: nil
    ),
    CommunityGroup(
        name: "AgTech Enthusiasts",
        description: "Discuss the latest agricultural technologies and innovations.",
        members: 892,
        isMember: false,
        category: "Technology",
        avatar: nil
    )
]
