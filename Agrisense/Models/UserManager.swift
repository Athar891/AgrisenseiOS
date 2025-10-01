//
//  UserManager.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
//

import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isUpdatingProfile = false
    @Published var profileUpdateError: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    let db = Firestore.firestore() // Made public for CropManager access
    
    // Cloudinary Configuration - using values from Secrets
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
        // Rate limiting - prevent spam signups
        let rateLimitKey = "signup_\(email)"
        guard RateLimiter.shared.checkLimit(
            key: rateLimitKey,
            maxRequests: RateLimitConfig.signupMaxAttempts,
            timeWindow: RateLimitConfig.signupTimeWindow
        ) else {
            if let retryAfter = RateLimiter.shared.timeUntilReset(key: rateLimitKey, timeWindow: RateLimitConfig.signupTimeWindow) {
                throw RateLimitError.exceeded(retryAfter: retryAfter)
            }
            throw NSError(domain: "RateLimitError", code: 429, userInfo: [NSLocalizedDescriptionKey: "Too many signup attempts. Please try again later."])
        }
        
        // Enhanced input validation
        do {
            try InputValidator.validateEmail(email)
            try InputValidator.validatePassword(password)
            try InputValidator.validateName(fullName, fieldName: "Full Name")
        } catch {
            throw error
        }
        
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        
        // Create a Firestore user document
        let userData: [String: Any] = [
            "name": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
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
            #if DEBUG
            print("DEBUG: Failed to create Firestore user document: \(error.localizedDescription)")
            #endif
        }
    }

    func signIn(email: String, password: String) async throws {
        // Rate limiting - prevent brute force attacks
        let rateLimitKey = "login_\(email)"
        guard RateLimiter.shared.checkLimit(
            key: rateLimitKey,
            maxRequests: RateLimitConfig.loginMaxAttempts,
            timeWindow: RateLimitConfig.loginTimeWindow
        ) else {
            if let retryAfter = RateLimiter.shared.timeUntilReset(key: rateLimitKey, timeWindow: RateLimitConfig.loginTimeWindow) {
                throw RateLimitError.exceeded(retryAfter: retryAfter)
            }
            throw NSError(domain: "RateLimitError", code: 429, userInfo: [NSLocalizedDescriptionKey: "Too many login attempts. Please try again later."])
        }
        
        // Enhanced input validation
        do {
            try InputValidator.validateEmail(email)
        } catch {
            throw error
        }
        
        guard !password.isEmpty else {
            throw NSError(domain: "ValidationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password is required"])
        }
        
        try await Auth.auth().signIn(withEmail: email, password: password)
        
        // Clear rate limit on successful login
        RateLimiter.shared.reset(key: "login_\(email)")
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
        
        // Rate limiting
        let rateLimitKey = "profile_update_\(user.id)"
        guard RateLimiter.shared.checkLimit(
            key: rateLimitKey,
            maxRequests: RateLimitConfig.profileUpdateMaxAttempts,
            timeWindow: RateLimitConfig.profileUpdateTimeWindow
        ) else {
            if let retryAfter = RateLimiter.shared.timeUntilReset(key: rateLimitKey, timeWindow: RateLimitConfig.profileUpdateTimeWindow) {
                throw RateLimitError.exceeded(retryAfter: retryAfter)
            }
            throw NSError(domain: "RateLimitError", code: 429, userInfo: [NSLocalizedDescriptionKey: "Too many update attempts. Please try again later."])
        }
        
        isUpdatingProfile = true
        
        do {
            // Enhanced input validation
            try InputValidator.validateName(name)
            try InputValidator.validatePhoneNumber(phoneNumber, required: false)
            
            // Update Firestore
            let userData: [String: Any] = [
                "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                "phoneNumber": phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                "location": location.trimmingCharacters(in: .whitespacesAndNewlines),
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
            #if DEBUG
            print("DEBUG: Error updating profile: \(error.localizedDescription)")
            #endif
            throw error
        }
        
        isUpdatingProfile = false
    }
    
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        // Clear any previous errors
        profileUpdateError = nil
        
        guard let user = currentUser else {
            let errorMessage = "No current user found. Please sign in again."
            profileUpdateError = errorMessage
            throw NSError(domain: "UserManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Rate limiting - prevent spam uploads
        let rateLimitKey = "profile_image_upload_\(user.id)"
        guard RateLimiter.shared.checkLimit(
            key: rateLimitKey,
            maxRequests: RateLimitConfig.imageUploadMaxAttempts,
            timeWindow: RateLimitConfig.imageUploadTimeWindow
        ) else {
            if let retryAfter = RateLimiter.shared.timeUntilReset(key: rateLimitKey, timeWindow: RateLimitConfig.imageUploadTimeWindow) {
                let errorMessage = "Too many upload attempts. Please try again in \(Int(retryAfter / 60) + 1) minute(s)."
                profileUpdateError = errorMessage
                throw NSError(domain: "RateLimitError", code: 429, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            let errorMessage = "Too many upload attempts. Please try again later."
            profileUpdateError = errorMessage
            throw NSError(domain: "RateLimitError", code: 429, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        guard let imageData = flattenImageForUpload(image) else {
            let errorMessage = "Failed to process image for upload. Please try a different image."
            profileUpdateError = errorMessage
            throw NSError(domain: "ImageProcessingError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Validate image with security checks
        do {
            _ = try ImageValidator.validate(imageData: imageData, config: .profile)
        } catch {
            let errorMessage = "Invalid image. Please use a valid JPEG or PNG file."
            profileUpdateError = errorMessage
            throw NSError(domain: "ImageValidationError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
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

