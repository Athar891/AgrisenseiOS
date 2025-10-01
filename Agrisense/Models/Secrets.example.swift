import Foundation

// Copy this file to `Secrets.swift` and fill in your real values.
// IMPORTANT: `Secrets.swift` is ignored by git to prevent leaking secrets.

enum Secrets {
    static let openWeatherAPIKey = "YOUR_OPENWEATHER_API_KEY"
    static let geminiAPIKey = "YOUR_GEMINI_API_KEY"

    // Cloudinary (avoid committing API secrets; prefer unsigned uploads or server-side signing)
    static let cloudinaryCloudName = "YOUR_CLOUD_NAME"
    static let cloudinaryApiKey = "YOUR_CLOUDINARY_API_KEY"
    static let cloudinaryApiSecret = "DO_NOT_PUT_SECRETS_IN_CLIENT_APPS"
    static let cloudinaryUploadPreset = "post_images"
    static let cloudinaryProductImagesPreset = "product_images"
}
