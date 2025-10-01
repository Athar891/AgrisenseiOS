//
//  CropManager.swift
//  Agrisense
//
//  Created by Athar Reza on 13/08/25.
//

import Foundation
import SwiftUI
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

@MainActor
class CropManager: ObservableObject {
    @Published var crops: [Crop] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    // Cloudinary Configuration (centralized in Secrets)
    private let cloudinaryCloudName = Secrets.cloudinaryCloudName
    private let cloudinaryUploadPreset = Secrets.cloudinaryUploadPreset
    
    func addCrop(_ crop: Crop, for userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Add to local array
        crops.append(crop)
        
        // Save to Firestore
        try await saveCropsToFirestore(userId: userId)
    }
    
    func updateCrop(_ crop: Crop, for userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Update local array
        if let index = crops.firstIndex(where: { $0.id == crop.id }) {
            var updatedCrop = crop
            updatedCrop.updatedAt = Date()
            crops[index] = updatedCrop
        }
        
        // Save to Firestore
        try await saveCropsToFirestore(userId: userId)
    }
    
    func deleteCrop(withId cropId: String, for userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Remove from local array
        crops.removeAll { $0.id == cropId }
        
        // Save to Firestore
        try await saveCropsToFirestore(userId: userId)
    }
    
    func loadCrops(for userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let document = try await db.collection("users").document(userId).getDocument()
        
        if document.exists, let data = document.data() {
            if let cropsData = data["crops"] as? [[String: Any]] {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                var loadedCrops: [Crop] = []
                for cropDict in cropsData {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: cropDict),
                       let crop = try? decoder.decode(Crop.self, from: jsonData) {
                        loadedCrops.append(crop)
                    }
                }
                self.crops = loadedCrops
            }
        }
    }
    
    private func saveCropsToFirestore(userId: String) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        var cropsData: [[String: Any]] = []
        for crop in crops {
            if let jsonData = try? encoder.encode(crop),
               let cropDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                cropsData.append(cropDict)
            }
        }
        
        try await db.collection("users").document(userId).setData([
            "crops": cropsData
        ], merge: true)
    }
    
    func uploadCropImage(_ image: UIImage) async throws -> String {
        let cloudinaryCloudName = Secrets.cloudinaryCloudName
        let cloudinaryUploadPreset = Secrets.cloudinaryUploadPreset
        
        // Compress and convert image to WebP format
        guard let compressedImage = compressImage(image, maxSizeKB: 500),
              let imageData = convertToWebP(compressedImage) else {
            throw NSError(domain: "ImageProcessingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to process image for upload."])
        }

    #if DEBUG
    print("[Cloudinary] Using unsigned upload")
    print("[Cloudinary] Cloud: \(cloudinaryCloudName), Preset: \(cloudinaryUploadPreset)")
    print("[Cloudinary] Request URL: https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/image/upload")
    #endif

        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        
        let boundary = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // For unsigned uploads, only include upload_preset and file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(cloudinaryUploadPreset)\r\n".data(using: .utf8)!)
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"crop_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
    #if DEBUG
    print("[Cloudinary] About to send unsigned upload request")
    #endif
        
        // Retry logic for network requests
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                }
                
                if httpResponse.statusCode == 200 {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let secureUrl = json["secure_url"] as? String else {
                        throw NSError(domain: "CloudinaryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Cloudinary."])
                    }
                    
                    #if DEBUG
                    print("[Cloudinary] Upload successful: \(secureUrl)")
                    #endif
                    
                    return secureUrl
                } else {
                    // Parse error response
                    var errorMessage = "Upload failed with status code: \(httpResponse.statusCode)"
                    
                    if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = errorJson["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        errorMessage = message
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        errorMessage = errorString
                    }
                    
                    let error = NSError(domain: "CloudinaryError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    
                    // Don't retry on client errors (4xx)
                    if httpResponse.statusCode >= 400 && httpResponse.statusCode < 500 {
                        throw error
                    }
                    
                    lastError = error
                }
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                let nsError = error as NSError
                if nsError.domain == "CloudinaryError" && nsError.code >= 400 && nsError.code < 500 {
                    throw error
                }
            }
            
            // Wait before retry (exponential backoff)
            if attempt < maxRetries {
                let delay = pow(2.0, Double(attempt - 1)) // 1s, 2s, 4s
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // If all retries failed, throw the last error
        throw lastError ?? NSError(domain: "CloudinaryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload failed after \(maxRetries) attempts"])
    }
    
    // Helper methods for dashboard
    func getActiveCrops() -> [Crop] {
        return crops.filter { !$0.isOverdue }
    }
    
    func getCropsNearHarvest(days: Int = 7) -> [Crop] {
        return crops.filter { $0.daysUntilHarvest <= days && $0.daysUntilHarvest > 0 }
    }
    
    func getCropsByHealthStatus(_ status: CropHealthStatus) -> [Crop] {
        return crops.filter { $0.healthStatus == status }
    }
    
    // MARK: - Image Processing Helper Methods
    
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> UIImage? {
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
        
        return UIImage(data: imageData)
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
    
    private func convertToWebP(_ image: UIImage) -> Data? {
        // Since iOS doesn't natively support WebP encoding, we'll use high-quality JPEG
        // with optimized compression as a fallback. For true WebP support, you'd need
        // to add the WebP library (like libwebp or SDWebImage)
        
        // For now, return optimized JPEG data
        return image.jpegData(compressionQuality: 0.85)
    }
}
