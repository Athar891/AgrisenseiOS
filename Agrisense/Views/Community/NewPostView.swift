//
//  NewPostView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var selectedCategory: DiscussionCategory = .farming
    @EnvironmentObject var userManager: UserManager
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    let onPostCreated: (() -> Void)?
    
    // Cloudinary configuration (centralized in Secrets)
    private let cloudinaryCloudName = Secrets.cloudinaryCloudName
    private let cloudinaryUploadPreset = Secrets.cloudinaryUploadPreset
    
    init(onPostCreated: (() -> Void)? = nil) {
        self.onPostCreated = onPostCreated
    }

    private func savePost() {
        guard let userId = userManager.currentUser?.id else {
            saveError = "User not logged in."
            return
        }
        
        // Check if user is authenticated with Firebase Auth
        guard let firebaseUser = Auth.auth().currentUser else {
            saveError = "Authentication required. Please sign in again."
            return
        }
        
        // Validate post data
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            saveError = "Title is required."
            return
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            saveError = "Content is required."
            return
        }
        
        isSaving = true
        
        // Check if we have an image to upload
        if let imageData = selectedImageData {
            // Upload image first, then save post with image URL
            uploadImage(imageData) { result in
                switch result {
                case .success(let imageUrl):
                    savePostToFirestore(userId: firebaseUser.uid, imageUrl: imageUrl)
                case .failure(let error):
                    DispatchQueue.main.async {
                        isSaving = false
                        saveError = "Failed to upload image: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            // No image, just save the post
            savePostToFirestore(userId: firebaseUser.uid, imageUrl: nil)
        }
    }
    
    private func savePostToFirestore(userId: String, imageUrl: String?) {
        var post: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "content": content.trimmingCharacters(in: .whitespacesAndNewlines),
            "category": selectedCategory.rawValue,
            "author": userManager.currentUser?.name ?? "Unknown",
            "userId": userId,
            "timestamp": Date().timeIntervalSince1970,
            "likedByUsers": []
        ]
        
        if let imageUrl = imageUrl {
            post["imageUrl"] = imageUrl
        }
        
        let db = FirebaseFirestore.Firestore.firestore()
        
        // Save post to community_posts collection
        
        db.collection("community_posts").addDocument(data: post) { error in
            DispatchQueue.main.async {
                isSaving = false
                if let error = error {
                    // Provide specific error messages based on error type
                    if error.localizedDescription.contains("permission") || error.localizedDescription.contains("PERMISSION_DENIED") {
                        saveError = "Permission denied. Please check your internet connection and try again. If the problem persists, contact support."
                    } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("offline") {
                        saveError = "Network error. Please check your internet connection and try again."
                    } else {
                        saveError = "Failed to save post: \(error.localizedDescription)"
                    }
                } else {
                    onPostCreated?()
                    dismiss()
                }
            }
        }
    }
    
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data? {
        let maxSizeBytes = maxSizeKB * 1024
        var compressionQuality: CGFloat = 0.8
        let minCompressionQuality: CGFloat = 0.1
        let compressionStep: CGFloat = 0.1
        
        // First, resize the image if it's too large
        let resizedImage = resizeImage(image, maxDimension: 1200)
        
        guard var imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        
        // Reduce compression quality until we reach the target size
        while imageData.count > maxSizeBytes && compressionQuality > minCompressionQuality {
            compressionQuality -= compressionStep
            guard let newImageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
                break
            }
            imageData = newImageData
        }
        
        return imageData
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            // Landscape
            newSize = CGSize(width: min(maxDimension, size.width), 
                           height: min(maxDimension, size.width) / aspectRatio)
        } else {
            // Portrait or square
            newSize = CGSize(width: min(maxDimension, size.height) * aspectRatio, 
                           height: min(maxDimension, size.height))
        }
        
        // Don't upscale
        if newSize.width >= size.width && newSize.height >= size.height {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    private func uploadImage(_ imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        isUploading = true
        uploadProgress = 0.1 // Start progress indicator
        
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/image/upload")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        let fileName = "post_\(UUID().uuidString)"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName).jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add upload preset
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(cloudinaryUploadPreset)\r\n".data(using: .utf8)!)
        
        // Add public_id for consistent naming
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"public_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(fileName)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isUploading = false
                self.uploadProgress = 1.0
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "CloudinaryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    var errorMessage = "Upload failed with status code: \(statusCode)"
                    if let responseString = String(data: data, encoding: .utf8) {
                        errorMessage += "\nResponse: \(responseString)"
                    }
                    completion(.failure(NSError(domain: "CloudinaryError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let secureUrl = json["secure_url"] as? String {
                        completion(.success(secureUrl))
                    } else {
                        completion(.failure(NSError(domain: "CloudinaryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Cloudinary"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
        
        // Simulate upload progress (since URLSession.shared doesn't provide progress updates for dataTask)
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            DispatchQueue.main.async {
                if self.isUploading && self.uploadProgress < 0.9 {
                    self.uploadProgress += 0.1
                } else {
                    timer.invalidate()
                }
            }
        }
        
        task.resume()
    }
    
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
                
                Section("Photo") {
                    VStack {
                        if let selectedImageData = selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                            
                            Button("Remove Photo") {
                                self.selectedImageData = nil
                                self.selectedItem = nil
                            }
                            .foregroundColor(.red)
                            .padding(.top, 8)
                        } else {
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Label("Add Photo", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                if let uiImage = UIImage(data: data), let compressedData = compressImage(uiImage, maxSizeKB: 500) {
                                    selectedImageData = compressedData
                                } else {
                                    selectedImageData = data
                                }
                            }
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
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        savePost()
                    }
                    .disabled(title.isEmpty || content.isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    VStack {
                        if isUploading {
                            ProgressView("Uploading Image...", value: uploadProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .padding()
                        } else {
                            ProgressView("Saving post...")
                        }
                    }
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
                }
            }
            .alert("Error Saving Post", isPresented: Binding<Bool>(get: { saveError != nil }, set: { _ in saveError = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "Unknown error")
            }
        }
    }
}

#Preview {
    NewPostView()
}
