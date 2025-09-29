//
//  EnhancedUserManager.swift
//  Agrisense
//
//  Created by Kiro on 29/09/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

// MARK: - Enhanced User Manager with Error Handling

@MainActor
class EnhancedUserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isUpdatingProfile = false
    @Published var profileUpdateError: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    private let errorHandler = ErrorHandlingMiddleware.shared
    
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
        let context = ErrorContext(
            feature: .authentication,
            userAction: "sign_up",
            additionalInfo: ["email": email, "userType": userType.rawValue]
        )
        
        do {
            // Validate input
            try validateSignUpInput(email: email, password: password, fullName: fullName)
            
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = fullName
            try await changeRequest.commitChanges()
            
            // Create Firestore user document
            let userData: [String: Any] = [
                "name": fullName,
                "email": email,
                "userType": userType.rawValue,
                "profileImage": NSNull(),
                "location": "",
                "phoneNumber": "",
                "crops": []
            ]

            try await db.collection("users").document(authResult.user.uid).setData(userData)
            
        } catch {
            let agriSenseError = convertAuthError(error)
            let errorResponse = errorHandler.handle(agriSenseError, context: context)
            throw agriSenseError
        }
    }

    func signIn(email: String, password: String) async throws {
        let context = ErrorContext(
            feature: .authentication,
            userAction: "sign_in",
            additionalInfo: ["email": email]
        )
        
        do {
            // Validate input
            try validateSignInInput(email: email, password: password)
            
            try await Auth.auth().signIn(withEmail: email, password: password)
            
        } catch {
            let agriSenseError = convertAuthError(error)
            let errorResponse = errorHandler.handle(agriSenseError, context: context)
            throw agriSenseError
        }
    }

    func signOut() {
        let context = ErrorContext(
            feature: .authentication,
            userAction: "sign_out"
        )
        
        do {
            try Auth.auth().signOut()
        } catch {
            let agriSenseError = convertAuthError(error)
            let _ = errorHandler.handle(agriSenseError, context: context)
            // Don't throw for sign out errors, just log them
        }
    }

    // MARK: - Profile Update Functions
    
    func clearProfileUpdateError() {
        profileUpdateError = nil
    }
    
    func updateUserProfile(name: String, phoneNumber: String, location: String) async throws {
        let context = ErrorContext(
            feature: .profile,
            userAction: "update_profile",
            additionalInfo: ["name": name, "location": location]
        )
        
        guard let user = currentUser else {
            let error = AgriSenseError.authenticationFailed
            let _ = errorHandler.handle(error, context: context)
            throw error
        }
        
        isUpdatingProfile = true
        
        do {
            // Validate input
            try validateProfileInput(name: name, phoneNumber: phoneNumber)
            
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
            let agriSenseError = convertFirestoreError(error)
            let _ = errorHandler.handle(agriSenseError, context: context)
            throw agriSenseError
        }
        
        isUpdatingProfile = false
    }
    
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        let context = ErrorContext(
            feature: .profile,
            userAction: "upload_profile_image"
        )
        
        // Clear any previous errors
        profileUpdateError = nil
        
        guard let imageData = flattenImageForUpload(image) else {
            let error = AgriSenseError.imageProcessingError
            let _ = errorHandler.handle(error, context: context)
            throw error
        }
        
        guard let user = currentUser else {
            let error = AgriSenseError.authenticationFailed
            let _ = errorHandler.handle(error, context: context)
            throw error
        }
        
        // Check if image data is valid and within size limits
        guard imageData.count > 0 else {
            let error = AgriSenseError.imageProcessingError
            let _ = errorHandler.handle(error, context: context)
            throw error
        }
        
        // Check if compressed image is still too large
        let sizeInKB = imageData.count / 1024
        let maxAllowedKB = 5 * 1024
        guard sizeInKB <= maxAllowedKB else {
            let error = AgriSenseError.validationError("Image is too large (\(sizeInKB)KB). Please choose an image under 5 MB.")
            let _ = errorHandler.handle(error, context: context)
            throw error
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
            let agriSenseError = convertCloudinaryError(error)
            let _ = errorHandler.handle(agriSenseError, context: context)
            throw agriSenseError
        }
    }
    
    func loadUserFromFirestore(_ userId: String) async {
        let context = ErrorContext(
            feature: .profile,
            userAction: "load_user_data",
            additionalInfo: ["userId": userId]
        )
        
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
            let agriSenseError = convertFirestoreError(error)
            let _ = errorHandler.handle(agriSenseError, context: context)
            // Don't throw here as this is called automatically
        }
    }

    // MARK: - Private Helper Methods
    
    private func validateSignUpInput(email: String, password: String, fullName: String) throws {
        if email.isEmpty {
            throw AgriSenseError.invalidInput("Email")
        }
        if password.isEmpty {
            throw AgriSenseError.invalidInput("Password")
        }
        if fullName.isEmpty {
            throw AgriSenseError.invalidInput("Full Name")
        }
        if !email.contains("@") {
            throw AgriSenseError.validationError("Please enter a valid email address")
        }
        if password.count < 6 {
            throw AgriSenseError.validationError("Password must be at least 6 characters long")
        }
    }
    
    private func validateSignInInput(email: String, password: String) throws {
        if email.isEmpty {
            throw AgriSenseError.invalidInput("Email")
        }
        if password.isEmpty {
            throw AgriSenseError.invalidInput("Password")
        }
    }
    
    private func validateProfileInput(name: String, phoneNumber: String) throws {
        if name.isEmpty {
            throw AgriSenseError.invalidInput("Name")
        }
        if !phoneNumber.isEmpty && phoneNumber.count < 10 {
            throw AgriSenseError.validationError("Please enter a valid phone number")
        }
    }
    
    private func convertAuthError(_ error: Error) -> AgriSenseError {
        let nsError = error as NSError
        
        if nsError.domain == "FIRAuthErrorDomain" {
            switch nsError.code {
            case 17007: // Email already in use
                return .validationError("This email is already registered")
            case 17008: // Invalid email
                return .validationError("Please enter a valid email address")
            case 17026: // Weak password
                return .validationError("Password is too weak")
            case 17009: // Wrong password
                return .authenticationFailed
            case 17011: // User not found
                return .authenticationFailed
            default:
                return .authenticationFailed
            }
        }
        
        return error.asAgriSenseError
    }
    
    private func convertFirestoreError(_ error: Error) -> AgriSenseError {
        let nsError = error as NSError
        
        if nsError.domain == "FIRFirestoreErrorDomain" {
            switch nsError.code {
            case 7: // Permission denied
                return .insufficientPermissions
            case 14: // Unavailable
                return .networkUnavailable
            default:
                return .serverError(nsError.code)
            }
        }
        
        return error.asAgriSenseError
    }
    
    private func convertCloudinaryError(_ error: Error) -> AgriSenseError {
        let nsError = error as NSError
        
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return .networkUnavailable
            case NSURLErrorTimedOut:
                return .operationTimeout
            default:
                return .serverError(nsError.code)
            }
        }
        
        return .imageProcessingError
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
            throw AgriSenseError.serverError(statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let secureUrl = json["secure_url"] as? String else {
            throw AgriSenseError.dataCorrupted
        }
        
        return secureUrl
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}