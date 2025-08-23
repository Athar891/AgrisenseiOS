import UIKit

/// Utility for compressing and resizing images for upload.
struct ImageCompressor {
    /// Compress image data by iteratively reducing JPEG quality and then resizing if necessary.
    /// Returns JPEG Data or nil on failure.
    static func compressImageData(_ image: UIImage, maxSizeKB: Int) -> Data? {
        let maxBytes = maxSizeKB * 1024

        // Start with a reasonable max dimension (do not upscale)
        var maxDimension: CGFloat = 1600
        var currentImage = resizeImage(image, maxDimension: maxDimension)

        var quality: CGFloat = 0.9
        let minQuality: CGFloat = 0.1

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

        // If still too large, progressively reduce dimensions and retry quality loop
        while data.count > maxBytes {
            // Reduce target dimension
            maxDimension = max(200, maxDimension * 0.8)
            currentImage = resizeImage(image, maxDimension: maxDimension)

            quality = 0.9
            guard var newData = currentImage.jpegData(compressionQuality: quality) else { break }

            while newData.count > maxBytes && quality > minQuality {
                quality -= 0.1
                if let tmp = currentImage.jpegData(compressionQuality: quality) {
                    newData = tmp
                } else { break }
            }

            data = newData

            // If we've reached a very small dimension, stop to avoid bad results
            if maxDimension <= 200 { break }
        }

        return data.count > 0 ? data : nil
    }

    static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If the image is already within the bounds, return original
        if max(size.width, size.height) <= maxDimension {
            return image
        }

        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}
