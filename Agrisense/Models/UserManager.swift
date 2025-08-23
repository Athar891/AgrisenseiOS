//
//  UserManager.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

@MainActor
class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isUpdatingProfile = false
    @Published var profileUpdateError: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    let db = Firestore.firestore() // Made public for CropManager access
    
    // Cloudinary Configuration (centralized in Secrets)
    private let cloudinaryCloudName = Secrets.cloudinaryCloudName
    private let cloudinaryUploadPreset = Secrets.cloudinaryUploadPreset

    init() {
        listenToAuthState()
    }

    func listenToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.isAuthenticated = user != nil
            if let firebaseUser = user {
                // Load user details from Firestore
                Task {
                    await self.loadUserFromFirestore(firebaseUser.uid)
                }
            } else {
                self.currentUser = nil
            }
        }
    }

    func signUp(email: String, password: String, fullName: String, userType: UserType) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        
        // Here, you would typically save additional user info (like userType) to Firestore.
        // For now, the listener will update the currentUser.
        // Create a Firestore user document so other flows that call updateData won't fail.
        let userData: [String: Any] = [
            "name": fullName,
            "email": email,
            "userType": userType.rawValue,
            "profileImage": NSNull(),
            "location": "",
            "phoneNumber": "",
            "crops": []
        ]

        do {
            try await db.collection("users").document(authResult.user.uid).setData(userData)
        } catch {
            // Non-fatal: print for debugging but don't fail signup because auth succeeded.
            print("Warning: failed to create Firestore user document: \(error.localizedDescription)")
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // MARK: - Profile Update Functions
    
    func clearProfileUpdateError() {
        profileUpdateError = nil
    }
    
    func updateUserProfile(name: String, phoneNumber: String, location: String) async throws {
        guard let user = currentUser else {
            throw NSError(domain: "UserManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user"])
        }
        
        isUpdatingProfile = true
        
        do {
            // Update Firestore
            let userData: [String: Any] = [
                "name": name,
                "phoneNumber": phoneNumber,
                "location": location,
                "email": user.email,
                "userType": user.userType.rawValue
            ]
            
            try await db.collection("users").document(user.id).setData(userData, merge: true)
            
            // Update Firebase Auth display name
            if let authUser = Auth.auth().currentUser {
                let changeRequest = authUser.createProfileChangeRequest()
                changeRequest.displayName = name
                try await changeRequest.commitChanges()
            }
            
            // Update local user object
            let updatedUser = User(
                id: user.id,
                name: name,
                email: user.email,
                userType: user.userType,
                profileImage: user.profileImage,
                location: location,
                phoneNumber: phoneNumber
            )
            
            self.currentUser = updatedUser
            
        } catch {
            print("Error updating profile: \(error.localizedDescription)")
            throw error
        }
        
        isUpdatingProfile = false
    }
    
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        // Clear any previous errors
        profileUpdateError = nil
        
    guard let imageData = flattenImageForUpload(image) else {
            let errorMessage = "Failed to process image for upload. Please try a different image."
            profileUpdateError = errorMessage
            throw NSError(domain: "ImageProcessingError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let user = currentUser else {
            let errorMessage = "No current user found. Please sign in again."
            profileUpdateError = errorMessage
            throw NSError(domain: "UserManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Check if image data is valid and within size limits
        guard imageData.count > 0 else {
            let errorMessage = "Image data is empty. Please try a different image."
            profileUpdateError = errorMessage
            throw NSError(domain: "UserManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Check if compressed image is still too large (shouldn't happen, but just in case)
        // Allow up to 5 MB profile images (5120 KB)
        let sizeInKB = imageData.count / 1024
        let maxAllowedKB = 5 * 1024
        guard sizeInKB <= maxAllowedKB else {
            let errorMessage = "Image is too large (\(sizeInKB)KB). Please choose an image under 5 MB."
            profileUpdateError = errorMessage
            throw NSError(domain: "UserManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        do {
            // Upload image to Cloudinary with timestamp to ensure unique URL
            let timestamp = Int(Date().timeIntervalSince1970)
            let imageUrl = try await uploadToCloudinary(imageData: imageData, fileName: "profile_\(user.id)_\(timestamp)")
            
            // Update Firestore with new profile image URL
            try await db.collection("users").document(user.id).setData([
                "profileImage": imageUrl
            ], merge: true)
            
            // Update local user object
            let updatedUser = User(
                id: user.id,
                name: user.name,
                email: user.email,
                userType: user.userType,
                profileImage: imageUrl,
                location: user.location,
                phoneNumber: user.phoneNumber
            )
            
            self.currentUser = updatedUser
            
            // Clear URLSession cache to ensure AsyncImage loads the new image
            URLCache.shared.removeAllCachedResponses()
            
            return imageUrl
            
        } catch {
            let errorMessage = "Failed to upload image: \(error.localizedDescription)"
            profileUpdateError = errorMessage
            print("Error uploading profile image: \(error.localizedDescription)")
            throw NSError(domain: "UserManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
    
    private func flattenImageForUpload(_ image: UIImage) -> Data? {
        // Target up to 5 MB for profile images
        let maxKB = 5 * 1024
        guard let compressedData = ImageCompressor.compressImageData(image, maxSizeKB: maxKB) else {
            return nil
        }

        // Redraw to standard sRGB color space to avoid color/profile issues
        if let uiImage = UIImage(data: compressedData) {
            let renderer = UIGraphicsImageRenderer(size: uiImage.size)
            let flattenedImage = renderer.image { _ in
                uiImage.draw(in: CGRect(origin: .zero, size: uiImage.size))
            }
            // Return JPEG data (already compressed)
            return flattenedImage.jpegData(compressionQuality: 0.9) ?? compressedData
        }

        return compressedData
    }

    private func uploadToCloudinary(imageData: Data, fileName: String) async throws -> String {
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/image/upload")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            var errorMessage = "Upload failed with status code: \(statusCode)"
            if let responseData = String(data: data, encoding: .utf8) {
                errorMessage += "\nResponse: \(responseData)"
            }
            print(errorMessage) // Print detailed error to console
            throw NSError(domain: "CloudinaryError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let secureUrl = json["secure_url"] as? String else {
            throw NSError(domain: "CloudinaryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Cloudinary"])
        }
        
        return secureUrl
    }
    
    func loadUserFromFirestore(_ userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            if document.exists, let data = document.data() {
                // Load crops data
                var crops: [Crop] = []
                if let cropsData = data["crops"] as? [[String: Any]] {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    for cropDict in cropsData {
                        if let jsonData = try? JSONSerialization.data(withJSONObject: cropDict),
                           let crop = try? decoder.decode(Crop.self, from: jsonData) {
                            crops.append(crop)
                        }
                    }
                }
                
                let user = User(
                    id: userId,
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    userType: UserType(rawValue: data["userType"] as? String ?? "farmer") ?? .farmer,
                    profileImage: data["profileImage"] as? String,
                    location: data["location"] as? String,
                    phoneNumber: data["phoneNumber"] as? String,
                    crops: crops
                )
                
                self.currentUser = user
            }
        } catch {
            print("Error loading user from Firestore: \(error.localizedDescription)")
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

