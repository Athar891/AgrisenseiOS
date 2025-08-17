//
//  CropManager.swift
//  Agrisense
//
//  Created by Athar Reza on 13/08/25.
//

import Foundation
import FirebaseFirestore
import UIKit
import CryptoKit

@MainActor
class CropManager: ObservableObject {
    @Published var crops: [Crop] = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    
    // Cloudinary Configuration
    private let cloudinaryCloudName = "derhnhko0"
    private let cloudinaryUploadPreset = "crop_images"
    
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
        
        try await db.collection("users").document(userId).updateData([
            "crops": cropsData
        ])
    }
    
    func uploadCropImage(_ image: UIImage) async throws -> String {
        let cloudinaryCloudName = Secrets.cloudinaryCloudName
        let cloudinaryUploadPreset = Secrets.cloudinaryUploadPreset
        let apiKey = Secrets.cloudinaryApiKey
        let apiSecret = Secrets.cloudinaryApiSecret
        
        let timestamp = String(Int(Date().timeIntervalSince1970))
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageProcessingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to process image for upload."])
        }
        
        // Create signature
        let paramsToSign = [
            "timestamp": timestamp,
            "upload_preset": cloudinaryUploadPreset
        ]
        let signatureString = paramsToSign.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        let signatureInput = signatureString + apiSecret
        let signature = Insecure.SHA1.hash(data: Data(signatureInput.utf8)).map { String(format: "%02hhx", $0) }.joined()

    #if DEBUG
    print("[Cloudinary] String to sign: \(signatureString)")
    print("[Cloudinary] Computed signature: \(signature)")
    print("[Cloudinary] Signature length: \(signature.count)")
    print("[Cloudinary] Cloud: \(cloudinaryCloudName), API Key: \(apiKey.prefix(4))****, Preset: \(cloudinaryUploadPreset), Timestamp: \(timestamp)")
    print("[Cloudinary] Request URL: https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/image/upload")
    #endif

        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        
        let boundary = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add fields in a specific order
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(cloudinaryUploadPreset)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"api_key\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(apiKey)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"timestamp\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(timestamp)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"signature\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(signature)\r\n".data(using: .utf8)!)
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"crop_image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
    #if DEBUG
    print("[Cloudinary] About to send request with signature: \(signature)")
    if let bodyString = String(data: body, encoding: .utf8) {
        print("[Cloudinary] Request body contains signature: \(bodyString.contains(signature))")
    }
    #endif
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? [String: Any] {
                print("[Cloudinary] Error JSON: \(errorMessage)")
                throw NSError(domain: "CloudinaryError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(errorMessage)"])
            } else if let errorString = String(data: data, encoding: .utf8) {
                print("[Cloudinary] Error String: \(errorString)")
                throw NSError(domain: "CloudinaryError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString])
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let secureUrl = json["secure_url"] as? String else {
            throw NSError(domain: "CloudinaryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Cloudinary."])
        }
        
        return secureUrl
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
}
