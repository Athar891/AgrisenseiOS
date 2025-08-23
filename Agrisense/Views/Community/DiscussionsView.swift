//
//  DiscussionsView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct DiscussionsView: View {
    let searchText: String
    let refreshTrigger: UUID
    @State private var selectedCategory: DiscussionCategory = .all
    @State private var discussions: [Discussion] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var filteredDiscussions: [Discussion] {
        var filtered = discussions
        
        // Filter by category
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { discussion in
                discussion.title.localizedCaseInsensitiveContains(searchText) ||
                discussion.content.localizedCaseInsensitiveContains(searchText) ||
                discussion.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
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

            // Discussions list
            ScrollView {
                LazyVStack(spacing: 12) {
                    if isLoading {
                        ProgressView("Loading discussions...")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Error loading discussions")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                fetchDiscussions()
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    } else if filteredDiscussions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text(searchText.isEmpty ? "No discussions yet" : "No discussions found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            if searchText.isEmpty {
                                Text("Be the first to start a discussion!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                    } else {
                        ForEach(filteredDiscussions) { discussion in
                            DiscussionCard(discussion: discussion)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .refreshable {
                await refreshDiscussions()
            }
        }
        .onAppear {
            if discussions.isEmpty {
                fetchDiscussions()
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            fetchDiscussions()
        }
    }
    
    private func fetchDiscussions() {
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        db.collection("community_posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        print("❌ Error fetching discussions: \(error)")
                        errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        errorMessage = "No data found"
                        return
                    }
                    
                    discussions = documents.compactMap { document in
                        let data = document.data()
                        
                        guard let title = data["title"] as? String,
                              let content = data["content"] as? String,
                              let author = data["author"] as? String,
                              let categoryRaw = data["category"] as? String,
                              let category = DiscussionCategory(rawValue: categoryRaw),
                              let timestamp = data["timestamp"] as? TimeInterval else {
                            print("⚠️ Invalid document format: \(document.documentID)")
                            // Instead of returning nil, we'll filter this out in a later step
                            return Discussion(
                                firestoreId: document.documentID,
                                title: "Invalid Post",
                                content: "This post could not be loaded",
                                author: "Unknown",
                                category: .other,
                                timestamp: Date(),
                                userId: ""
                            )
                        }
                        
                        let likes = data["likes"] as? Int ?? 0
                        let replies = data["replies"] as? Int ?? 0
                        let userId = data["userId"] as? String ?? ""
                        let imageUrl = data["imageUrl"] as? String
                        let likedByUsers = data["likedByUsers"] as? [String] ?? []
                        
                        // Check if current user has liked this post
                        let isLiked = Auth.auth().currentUser != nil && likedByUsers.contains(Auth.auth().currentUser!.uid)
                        
                        return Discussion(
                            firestoreId: document.documentID,
                            title: title,
                            content: content,
                            author: author,
                            category: category,
                            timestamp: Date(timeIntervalSince1970: timestamp),
                            replies: replies,
                            likes: likes,
                            isLiked: isLiked,
                            authorAvatar: nil,
                            userId: userId,
                            imageUrl: imageUrl,
                            likedByUsers: likedByUsers
                        )
                    }
                    
                    print("✅ Fetched \(discussions.count) discussions")
                }
            }
    }
    
    private func refreshDiscussions() async {
        await withCheckedContinuation { continuation in
            fetchDiscussions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                continuation.resume()
            }
        }
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
    @State private var isLiked: Bool = false
    @State private var likesCount: Int = 0
    @State private var repliesCount: Int = 0
    @State private var showCommentSheet = false
    @State private var newComment = ""
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @EnvironmentObject var userManager: UserManager
    
    // Function to handle deleting a post
    private func deletePost() {
        let db = Firestore.firestore()
        let postRef = db.collection("community_posts").document(discussion.firestoreId)
        
        postRef.delete { error in
            if let error = error {
                print("❌ Error deleting post: \(error)")
            } else {
                print("✅ Post deleted successfully")
                // The post will be removed from the list automatically via the snapshot listener
            }
        }
    }

    private func likePost() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        let postRef = db.collection("community_posts").document(discussion.firestoreId)
        
        // Add or remove the user from the likedByUsers array
        if isLiked {
            // User has already liked, so unlike
            postRef.setData([
                "likes": FieldValue.increment(Int64(-1)),
                "likedByUsers": FieldValue.arrayRemove([currentUserId])
            ], merge: true) { error in
                if let error = error {
                    print("❌ Error updating likes: \(error)")
                }
            }
            isLiked = false
            likesCount -= 1
        } else {
            // User hasn't liked, so like
            postRef.setData([
                "likes": FieldValue.increment(Int64(1)),
                "likedByUsers": FieldValue.arrayUnion([currentUserId])
            ], merge: true) { error in
                if let error = error {
                    print("❌ Error updating likes: \(error)")
                }
            }
            isLiked = true
            likesCount += 1
        }
    }

    private func addComment() {
        guard !newComment.isEmpty else { return }
        guard let currentUser = userManager.currentUser else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        let postRef = db.collection("community_posts").document(discussion.firestoreId)
        let comment: [String: Any] = [
            "author": currentUser.name,
            "userId": currentUser.id,
            "content": newComment,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        postRef.collection("comments").addDocument(data: comment) { error in
            if let error = error {
                print("❌ Error adding comment: \(error)")
            } else {
                // Update replies count in main document
                postRef.setData([
                    "replies": FieldValue.increment(Int64(1))
                ], merge: true)
                repliesCount += 1
            }
        }
        
        newComment = ""
        showCommentSheet = false
    }
    
    private func sharePost() {
        showShareSheet = true
    }
    
    // Format date to show only hours and minutes, not seconds
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short // This will show only hour and minute
        return formatter.string(from: date)
    }
    
    // Check if current user is the post author
    private var isCurrentUserAuthor: Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        return currentUser.uid == discussion.userId
    }
    
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
                        
                        // Custom time format
                        Text(formatDate(discussion.timestamp) + (Calendar.current.isDateInToday(discussion.timestamp) ? "" : " • " + discussion.timestamp.formatted(date: .abbreviated, time: .omitted)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isCurrentUserAuthor {
                        Menu {
                            Button(role: .destructive, action: { showDeleteAlert = true }) {
                                Label("Delete Post", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.secondary)
                                .padding(8)
                        }
                    }
                    
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
                    
                    // Post Image (if available)
                    if let imageUrl = discussion.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                    .frame(height: 200)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                
                // Actions
                HStack {
                    Button(action: { likePost() }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? .red : .secondary)
                            Text("\(likesCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { showCommentSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .foregroundColor(.secondary)
                            Text("\(repliesCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    Button(action: { sharePost() }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .sheet(isPresented: $showCommentSheet) {
                    VStack(spacing: 16) {
                        Text("Add a Comment")
                            .font(.headline)
                            .padding(.top)
                        
                        Divider()
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Commenting on:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(discussion.title)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                
                                Divider()
                                    .padding(.vertical, 8)
                                
                                TextField("Your comment", text: $newComment, axis: .vertical)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .lineLimit(3...5)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Button("Cancel") {
                                showCommentSheet = false
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Post Comment") {
                                addComment()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(newComment.isEmpty)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                    }
                }
                .sheet(isPresented: $showShareSheet) {
                    if let imageUrl = discussion.imageUrl, let url = URL(string: imageUrl) {
                        ShareSheet(items: [discussion.title, discussion.content, url])
                    } else {
                        ShareSheet(items: [discussion.title, discussion.content])
                    }
                }
                .alert("Delete Post", isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        deletePost()
                    }
                } message: {
                    Text("Are you sure you want to delete this post? This action cannot be undone.")
                }
                .onAppear {
                    isLiked = discussion.isLiked
                    likesCount = discussion.likes
                    repliesCount = discussion.replies
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
    @State private var isLiked: Bool
    @State private var likesCount: Int
    @State private var showDeleteAlert = false
    @State private var showCommentSheet = false
    @State private var newComment = ""
    @State private var showShareSheet = false
    @State private var comments: [Comment] = []
    @State private var loadingComments = false
    @EnvironmentObject var userManager: UserManager
    
    init(discussion: Discussion) {
        self.discussion = discussion
        // Initialize the state
        _isLiked = State(initialValue: discussion.isLiked)
        _likesCount = State(initialValue: discussion.likes)
    }
    
    private func deletePost() {
        let db = Firestore.firestore()
        let postRef = db.collection("community_posts").document(discussion.firestoreId)
        
        postRef.delete { error in
            if let error = error {
                print("❌ Error deleting post: \(error)")
            } else {
                print("✅ Post deleted successfully")
                dismiss()
            }
        }
    }
    
    private func likePost() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        let postRef = db.collection("community_posts").document(discussion.firestoreId)
        
        // Add or remove the user from the likedByUsers array
        if isLiked {
            // User has already liked, so unlike
            postRef.updateData([
                "likes": FieldValue.increment(Int64(-1)),
                "likedByUsers": FieldValue.arrayRemove([currentUserId])
            ]) { error in
                if let error = error {
                    print("❌ Error updating likes: \(error)")
                }
            }
            isLiked = false
            likesCount -= 1
        } else {
            // User hasn't liked, so like
            postRef.updateData([
                "likes": FieldValue.increment(Int64(1)),
                "likedByUsers": FieldValue.arrayUnion([currentUserId])
            ]) { error in
                if let error = error {
                    print("❌ Error updating likes: \(error)")
                }
            }
            isLiked = true
            likesCount += 1
        }
    }
    
    private func addComment() {
        guard !newComment.isEmpty else { return }
        guard let currentUser = userManager.currentUser else {
            print("User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        let postRef = db.collection("community_posts").document(discussion.firestoreId)
        let comment: [String: Any] = [
            "author": currentUser.name,
            "userId": currentUser.id,
            "content": newComment,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        postRef.collection("comments").addDocument(data: comment) { error in
            if let error = error {
                print("❌ Error adding comment: \(error)")
            } else {
                // Update replies count in main document
                postRef.updateData([
                    "replies": FieldValue.increment(Int64(1))
                ])
                // Append comment locally for immediate feedback
                let c = Comment(id: UUID().uuidString, author: currentUser.name, userId: currentUser.id, content: newComment, timestamp: Date())
                comments.insert(c, at: 0)
            }
        }
        
        newComment = ""
        showCommentSheet = false
    }
    
    private func sharePost() {
        showShareSheet = true
    }
    
    // Format date to show only hours and minutes, not seconds
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short // This will show only hour and minute
        return formatter.string(from: date)
    }
    
    // Check if current user is the post author
    private var isCurrentUserAuthor: Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        return currentUser.uid == discussion.userId
    }
    
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
                                
                                // Custom time format
                                Text(formatDate(discussion.timestamp) + (Calendar.current.isDateInToday(discussion.timestamp) ? "" : " • " + discussion.timestamp.formatted(date: .abbreviated, time: .omitted)))
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
                        
                        // Post Image (if available)
                        if let imageUrl = discussion.imageUrl, !imageUrl.isEmpty {
                            AsyncImage(url: URL(string: imageUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 200)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxHeight: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                        .frame(height: 200)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                        
                        // Action buttons
                        HStack {
                            Button(action: { likePost() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .foregroundColor(isLiked ? .red : .secondary)
                                    Text("\(likesCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: { showCommentSheet = true }) {
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
                            
                            Button(action: { sharePost() }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Replies / Comments
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comments")
                            .font(.headline)

                        if loadingComments {
                            ProgressView()
                        } else if comments.isEmpty {
                            Text("No comments yet. Be the first to comment.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(comments) { comment in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(comment.author)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text(comment.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Text(comment.content)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Discussion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isCurrentUserAuthor {
                        Button(action: { showDeleteAlert = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCommentSheet) {
                VStack(spacing: 16) {
                    Text("Add a Comment")
                        .font(.headline)
                        .padding(.top)
                    
                    Divider()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Commenting on:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(discussion.title)
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            TextField("Your comment", text: $newComment, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...5)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button("Cancel") {
                            showCommentSheet = false
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Post Comment") {
                            addComment()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(newComment.isEmpty)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let imageUrl = discussion.imageUrl, let url = URL(string: imageUrl) {
                    ShareSheet(items: [discussion.title, discussion.content, url])
                } else {
                    ShareSheet(items: [discussion.title, discussion.content])
                }
            }
            .alert("Delete Post", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deletePost()
                }
            } message: {
                Text("Are you sure you want to delete this post? This action cannot be undone.")
            }
            .onAppear { loadComments() }
        }
    }

    private func loadComments() {
        loadingComments = true
        let db = Firestore.firestore()
        db.collection("community_posts").document(discussion.firestoreId).collection("comments").order(by: "timestamp", descending: true).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                loadingComments = false
                if let error = error {
                    print("Error loading comments: \(error)")
                    return
                }

                guard let docs = snapshot?.documents else { return }
                comments = docs.compactMap { d in
                    let data = d.data()
                    let author = data["author"] as? String ?? "Unknown"
                    let userId = data["userId"] as? String ?? ""
                    let content = data["content"] as? String ?? ""
                    let ts = data["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970
                    return Comment(id: d.documentID, author: author, userId: userId, content: content, timestamp: Date(timeIntervalSince1970: ts))
                }
            }
        }
    }
}

#Preview {
    DiscussionsView(searchText: "", refreshTrigger: UUID())
}
