//
//  ProductManager.swift
//  Agrisense
//
//  Created by Athar Reza on 31/08/25.
//

import Foundation
import FirebaseFirestore
import UIKit

@MainActor
class ProductManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var uploadProgress: Double = 0
    @Published var isUploading = false
    
    private let db = Firestore.firestore()
    
    // Cloudinary Configuration for product images
    private let cloudinaryCloudName = Secrets.cloudinaryCloudName
    private let cloudinaryProductImagesPreset = Secrets.cloudinaryProductImagesPreset
    
    /// Upload a product image to Cloudinary using the product_images preset
    func uploadProductImage(_ image: UIImage) async throws -> String {
        // Compress and prepare image for upload
        guard let compressedImage = compressImage(image, maxSizeKB: 1024), // 1MB max for product images
              let imageData = compressedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageProcessingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to process image for upload."])
        }

        #if DEBUG
        print("[ProductManager] Uploading product image to Cloudinary")
        print("[ProductManager] Cloud: \(cloudinaryCloudName), Preset: \(cloudinaryProductImagesPreset)")
        print("[ProductManager] Image size: \(imageData.count / 1024)KB")
        #endif

        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        
        let boundary = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add upload preset for unsigned upload
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(cloudinaryProductImagesPreset)\r\n".data(using: .utf8)!)
        
        // Add image data
        let fileName = "product_\(UUID().uuidString)_\(Int(Date().timeIntervalSince1970))"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName).jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Update upload state
        isUploading = true
        uploadProgress = 0.1
        
        // Retry logic for network requests
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                uploadProgress = 0.3 + (Double(attempt - 1) * 0.2) // Progress simulation
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
                }
                
                if httpResponse.statusCode == 200 {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let secureUrl = json["secure_url"] as? String else {
                        throw NSError(domain: "CloudinaryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Cloudinary."])
                    }
                    
                    uploadProgress = 1.0
                    isUploading = false
                    
                    #if DEBUG
                    print("[ProductManager] Upload successful: \(secureUrl)")
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
                        isUploading = false
                        uploadProgress = 0
                        throw error
                    }
                    
                    lastError = error
                }
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                let nsError = error as NSError
                if nsError.domain == "CloudinaryError" && nsError.code >= 400 && nsError.code < 500 {
                    isUploading = false
                    uploadProgress = 0
                    throw error
                }
            }
            
            // Wait before retry (exponential backoff)
            if attempt < maxRetries {
                let delay = pow(2.0, Double(attempt - 1)) // 1s, 2s, 4s
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        isUploading = false
        uploadProgress = 0
        
        // If all retries failed, throw the last error
        throw lastError ?? NSError(domain: "CloudinaryError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Upload failed after \(maxRetries) attempts"])
    }
    
    /// Upload multiple product images to Cloudinary
    func uploadProductImages(_ images: [UIImage]) async throws -> [String] {
        var imageUrls: [String] = []
        
        for (index, image) in images.enumerated() {
            uploadProgress = Double(index) / Double(images.count)
            let imageUrl = try await uploadProductImage(image)
            imageUrls.append(imageUrl)
        }
        
        uploadProgress = 1.0
        return imageUrls
    }
    
    // MARK: - Product Management
    
    /// Save a new product to Firestore
    func saveProduct(
        name: String,
        description: String,
        price: Double,
        unit: String,
        category: String,
        stock: Int,
        location: String,
        imageUrls: [String],
        sellerId: String,
        sellerName: String
    ) async throws -> String {
        let productData: [String: Any] = [
            "name": name,
            "description": description,
            "price": price,
            "unit": unit,
            "category": category,
            "stock": stock,
            "location": location,
            "imageUrls": imageUrls,
            "sellerId": sellerId,
            "sellerName": sellerName,
            "rating": 0.0,
            "reviewCount": 0,
            "createdAt": Timestamp(),
            "updatedAt": Timestamp(),
            "isActive": true
        ]
        
        let docRef = try await db.collection("products").addDocument(data: productData)
        
        #if DEBUG
        print("[ProductManager] Product saved with ID: \(docRef.documentID)")
        #endif
        
        return docRef.documentID
    }
    
    /// Update an existing product in Firestore
    func updateProduct(
        productId: String,
        name: String,
        description: String,
        price: Double,
        unit: String,
        category: String,
        stock: Int,
        location: String,
        imageUrls: [String]? = nil
    ) async throws {
        var updateData: [String: Any] = [
            "name": name,
            "description": description,
            "price": price,
            "unit": unit,
            "category": category,
            "stock": stock,
            "location": location,
            "updatedAt": Timestamp()
        ]
        
        // Only update imageUrls if provided
        if let imageUrls = imageUrls {
            updateData["imageUrls"] = imageUrls
        }
        
        try await db.collection("products").document(productId).updateData(updateData)
        
        #if DEBUG
        print("[ProductManager] Product updated: \(productId)")
        #endif
    }
    
    /// Delete a product from Firestore
    func deleteProduct(productId: String) async throws {
        try await db.collection("products").document(productId).updateData([
            "isActive": false,
            "updatedAt": Timestamp()
        ])
        
        #if DEBUG
        print("[ProductManager] Product deactivated: \(productId)")
        #endif
    }
    
    /// Fetch products from Firestore
    func fetchProducts() async throws {
        let snapshot = try await db.collection("products")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let fetchedProducts = snapshot.documents.compactMap { doc -> Product? in
            let data = doc.data()
            
            // Filter out inactive products in the app since we can't do compound query without index
            let isActive = data["isActive"] as? Bool ?? true
            guard isActive else { return nil }
            
            guard let name = data["name"] as? String,
                  let description = data["description"] as? String,
                  let price = data["price"] as? Double,
                  let unit = data["unit"] as? String,
                  let categoryString = data["category"] as? String,
                  let category = ProductCategory(rawValue: categoryString),
                  let stock = data["stock"] as? Int,
                  let location = data["location"] as? String,
                  let sellerId = data["sellerId"] as? String,
                  let sellerName = data["sellerName"] as? String else {
                return nil
            }
            
            let rating = data["rating"] as? Double ?? 0.0
            let imageUrls = data["imageUrls"] as? [String] ?? []
            
            // Convert image URLs to ProductImage objects
            let productImages = imageUrls.map { url in
                ProductImage(url: url, description: nil)
            }
            
            return Product(
                id: doc.documentID,
                name: name,
                description: description,
                price: price,
                unit: unit,
                category: category,
                seller: sellerName,
                sellerId: sellerId,
                rating: rating,
                stock: stock,
                location: location,
                images: productImages,
                mainImage: productImages.first
            )
        }
        
        await MainActor.run {
            self.products = fetchedProducts
        }
        
        #if DEBUG
        print("[ProductManager] Fetched \(fetchedProducts.count) products")
        #endif
    }
    
    /// Fetch products by seller
    func fetchProductsBySeller(sellerId: String) async throws -> [Product] {
        let snapshot = try await db.collection("products")
            .whereField("sellerId", isEqualTo: sellerId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        let sellerProducts = snapshot.documents.compactMap { doc -> Product? in
            let data = doc.data()
            
            guard let name = data["name"] as? String,
                  let description = data["description"] as? String,
                  let price = data["price"] as? Double,
                  let unit = data["unit"] as? String,
                  let categoryString = data["category"] as? String,
                  let category = ProductCategory(rawValue: categoryString),
                  let stock = data["stock"] as? Int,
                  let location = data["location"] as? String,
                  let sellerId = data["sellerId"] as? String,
                  let sellerName = data["sellerName"] as? String else {
                return nil
            }
            
            let rating = data["rating"] as? Double ?? 0.0
            let imageUrls = data["imageUrls"] as? [String] ?? []
            
            // Convert image URLs to ProductImage objects
            let productImages = imageUrls.map { url in
                ProductImage(url: url, description: nil)
            }
            
            return Product(
                id: doc.documentID,
                name: name,
                description: description,
                price: price,
                unit: unit,
                category: category,
                seller: sellerName,
                sellerId: sellerId,
                rating: rating,
                stock: stock,
                location: location,
                images: productImages,
                mainImage: productImages.first
            )
        }
        
        #if DEBUG
        print("[ProductManager] Fetched \(sellerProducts.count) products for seller: \(sellerId)")
        #endif
        
        return sellerProducts
    }

    // MARK: - Image Processing Helpers
    
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> UIImage? {
        let maxBytes = maxSizeKB * 1024
        
        // Start with a reasonable max dimension
        var maxDimension: CGFloat = 1200 // Suitable for product images
        var currentImage = resizeImage(image, maxDimension: maxDimension)
        
        var quality: CGFloat = 0.9
        let minQuality: CGFloat = 0.3 // Higher minimum quality for product images
        
        guard var data = currentImage.jpegData(compressionQuality: quality) else {
            return nil
        }
        
        // Reduce quality first
        while data.count > maxBytes && quality > minQuality {
            quality -= 0.1
            if let newData = currentImage.jpegData(compressionQuality: quality) {
                data = newData
            } else {
                break
            }
        }
        
        // If still too large, reduce dimensions
        while data.count > maxBytes && maxDimension > 400 {
            maxDimension *= 0.8
            currentImage = resizeImage(image, maxDimension: maxDimension)
            if let newData = currentImage.jpegData(compressionQuality: quality) {
                data = newData
            } else {
                break
            }
        }
        
        return UIImage(data: data)
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        guard size.width > maxDimension || size.height > maxDimension else {
            return image // No need to resize
        }
        
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}