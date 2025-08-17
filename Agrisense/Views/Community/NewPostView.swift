//
//  NewPostView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI

struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: DiscussionCategory = .farming
    
    var body: some View {
        NavigationView {
            Form {
                Section("Post Details") {
                    TextField("Title", text: $title)
                    
                    TextField("What's on your mind?", text: $content, axis: .vertical)
                        .lineLimit(5...10)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(DiscussionCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        // Post logic here
                        dismiss()
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NewPostView()
}
