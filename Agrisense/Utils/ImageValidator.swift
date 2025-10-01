//
//  ImageValidator.swift
//  Agrisense
//
//  Created by Security Audit on 01/10/25.
//

import UIKit
import Foundation

// MARK: - Image Validation Errors

enum ImageValidationError: LocalizedError {
    case invalidFormat
    case tooSmall
    case tooLarge
    case invalidDimensions
    case invalidAspectRatio
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid image format. Please use JPEG, PNG, or HEIC"
        case .tooSmall:
            return "Image is too small. Minimum size is 100x100 pixels"
        case .tooLarge:
            return "Image is too large. Maximum size is 4096x4096 pixels"
        case .invalidDimensions:
            return "Invalid image dimensions"
        case .invalidAspectRatio:
            return "Image aspect ratio is not supported"
        case .processingFailed:
            return "Failed to process image"
        }
    }
}

// MARK: - Image Validator

class ImageValidator {
    
    // MARK: - Configuration
    
    struct ValidationConfig {
        let minWidth: CGFloat
        let minHeight: CGFloat
        let maxWidth: CGFloat
        let maxHeight: CGFloat
        let maxFileSizeBytes: Int
        let allowedAspectRatioRange: ClosedRange<CGFloat>?
        
        static let profile = ValidationConfig(
            minWidth: 100,
            minHeight: 100,
            maxWidth: 2048,
            maxHeight: 2048,
            maxFileSizeBytes: 5 * 1024 * 1024, // 5MB
            allowedAspectRatioRange: 0.75...1.33 // Near square (4:3 to 3:4)
        )
        
        static let product = ValidationConfig(
            minWidth: 200,
            minHeight: 200,
            maxWidth: 4096,
            maxHeight: 4096,
            maxFileSizeBytes: 10 * 1024 * 1024, // 10MB
            allowedAspectRatioRange: 0.5...2.0 // 2:1 to 1:2
        )
        
        static let post = ValidationConfig(
            minWidth: 200,
            minHeight: 200,
            maxWidth: 4096,
            maxHeight: 4096,
            maxFileSizeBytes: 10 * 1024 * 1024, // 10MB
            allowedAspectRatioRange: nil // Any aspect ratio
        )
    }
    
    // MARK: - Validation Methods
    
    /// Validate image data and return UIImage if valid
    static func validate(imageData: Data, config: ValidationConfig) throws -> UIImage {
        // Check file size
        guard imageData.count <= config.maxFileSizeBytes else {
            throw ImageValidationError.tooLarge
        }
        
        guard imageData.count > 100 else {
            throw ImageValidationError.tooSmall
        }
        
        // Validate magic bytes (file signature)
        try validateFileSignature(imageData)
        
        // Create UIImage
        guard let image = UIImage(data: imageData) else {
            throw ImageValidationError.invalidFormat
        }
        
        // Validate dimensions
        try validateDimensions(image: image, config: config)
        
        return image
    }
    
    /// Validate UIImage
    static func validate(image: UIImage, config: ValidationConfig) throws {
        try validateDimensions(image: image, config: config)
    }
    
    /// Validate file signature (magic bytes) to ensure it's a real image
    private static func validateFileSignature(_ data: Data) throws {
        guard data.count >= 12 else {
            throw ImageValidationError.tooSmall
        }
        
        let bytes = [UInt8](data.prefix(12))
        
        // JPEG: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return
        }
        
        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if bytes[0] == 0x89 && bytes[1] == 0x50 && 
           bytes[2] == 0x4E && bytes[3] == 0x47 &&
           bytes[4] == 0x0D && bytes[5] == 0x0A &&
           bytes[6] == 0x1A && bytes[7] == 0x0A {
            return
        }
        
        // HEIC/HEIF: Check for 'ftyp' box at bytes 4-7
        if bytes[4] == 0x66 && bytes[5] == 0x74 && 
           bytes[6] == 0x79 && bytes[7] == 0x70 {
            return
        }
        
        // GIF: 47 49 46 38
        if bytes[0] == 0x47 && bytes[1] == 0x49 && 
           bytes[2] == 0x46 && bytes[3] == 0x38 {
            return
        }
        
        throw ImageValidationError.invalidFormat
    }
    
    /// Validate image dimensions and aspect ratio
    private static func validateDimensions(image: UIImage, config: ValidationConfig) throws {
        let size = image.size
        
        // Check minimum dimensions
        guard size.width >= config.minWidth && size.height >= config.minHeight else {
            throw ImageValidationError.tooSmall
        }
        
        // Check maximum dimensions
        guard size.width <= config.maxWidth && size.height <= config.maxHeight else {
            throw ImageValidationError.tooLarge
        }
        
        // Check aspect ratio if specified
        if let allowedRange = config.allowedAspectRatioRange {
            let aspectRatio = size.width / size.height
            guard allowedRange.contains(aspectRatio) else {
                throw ImageValidationError.invalidAspectRatio
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get image metadata for logging/debugging
    static func getImageInfo(_ image: UIImage) -> [String: Any] {
        let size = image.size
        let scale = image.scale
        let aspectRatio = size.width / size.height
        
        return [
            "width": size.width * scale,
            "height": size.height * scale,
            "aspectRatio": aspectRatio,
            "scale": scale
        ]
    }
    
    /// Check if image data is likely to be a valid image without full decoding
    static func quickValidate(_ data: Data) -> Bool {
        guard data.count >= 12 else {
            return false
        }
        
        do {
            try validateFileSignature(data)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - UIImage Extension for Validation

extension UIImage {
    
    /// Validate this image against configuration
    func validate(config: ImageValidator.ValidationConfig) throws {
        try ImageValidator.validate(image: self, config: config)
    }
    
    /// Check if image meets minimum requirements
    var meetsMinimumRequirements: Bool {
        let size = self.size
        return size.width >= 100 && size.height >= 100
    }
    
    /// Get a safe, validated copy of the image with constraints
    func validated(config: ImageValidator.ValidationConfig) -> UIImage? {
        do {
            try ImageValidator.validate(image: self, config: config)
            return self
        } catch {
            return nil
        }
    }
}
