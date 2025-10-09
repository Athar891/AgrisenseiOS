import XCTest
import UIKit
@testable import Agrisense

final class EnhancedImageCompressionTests: XCTestCase {
    
    // Test fixture - Create test images of various sizes
    func createTestImage(width: CGFloat, height: CGFloat, color: UIColor) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func testCompressionUnder5MB() {
        // Create a large test image (4000x4000 px) filled with color
        let image = createTestImage(width: 4000, height: 4000, color: .systemGreen)

        let maxKB = 5 * 1024
        let data = ImageCompressor.compressImageData(image, maxSizeKB: maxKB)

        XCTAssertNotNil(data, "Compression should return data")
        if let count = data?.count {
            XCTAssertLessThanOrEqual(count, maxKB * 1024, "Compressed data should be <= 5 MB")
        }
    }
    
    func testCompressionQuality() {
        // Create a medium test image with detailed pattern
        let size = CGSize(width: 1200, height: 1200)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        
        // Create a more complex pattern to test compression quality
        let context = UIGraphicsGetCurrentContext()!
        
        // Fill with base color
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // Draw some shapes of different colors
        for i in 0..<20 {
            let randomColor = UIColor(
                hue: CGFloat.random(in: 0...1),
                saturation: CGFloat.random(in: 0.5...1),
                brightness: CGFloat.random(in: 0.5...1),
                alpha: 1.0
            )
            randomColor.setFill()
            
            let rect = CGRect(
                x: CGFloat.random(in: 0...size.width-100),
                y: CGFloat.random(in: 0...size.height-100),
                width: CGFloat.random(in: 50...300),
                height: CGFloat.random(in: 50...300)
            )
            
            context.fillEllipse(in: rect)
        }
        
        let complexImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Try different max sizes to test quality vs size tradeoff
        let maxSizes = [1024, 512, 256, 128] // KB
        var compressionResults = [(size: Int, quality: Double)]()
        
        for maxSize in maxSizes {
            guard let data = ImageCompressor.compressImageData(complexImage, maxSizeKB: maxSize) else {
                XCTFail("Compression failed for size \(maxSize)")
                continue
            }
            
            // Recreate image from compressed data
            guard let compressedImage = UIImage(data: data) else {
                XCTFail("Could not create image from compressed data for size \(maxSize)")
                continue
            }
            
            // Verify size constraint
            XCTAssertLessThanOrEqual(data.count, maxSize * 1024, "Compressed data should not exceed \(maxSize) KB")
            
            // Calculate image dimensions
            let originalPixels = size.width * size.height
            let compressedPixels = compressedImage.size.width * compressedImage.size.height
            
            // Calculate a crude quality metric based on dimensions
            let dimensionQuality = compressedPixels / originalPixels
            
            compressionResults.append((size: data.count, quality: dimensionQuality))
        }
        
        // Verify that smaller max sizes result in smaller files
        for i in 1..<compressionResults.count {
            XCTAssertLessThanOrEqual(
                compressionResults[i].size, 
                compressionResults[i-1].size,
                "Smaller max size should result in smaller file"
            )
        }
    }
    
    func testImageResizing() {
        // Create images of different sizes
        let testSizes: [(width: CGFloat, height: CGFloat)] = [
            (800, 600),    // Landscape
            (600, 800),    // Portrait
            (1000, 1000),  // Square
            (2000, 1000),  // Wide
            (1000, 2000)   // Tall
        ]
        
        for testSize in testSizes {
            let image = createTestImage(width: testSize.width, height: testSize.height, color: .systemBlue)
            
            // Test resizing to different max dimensions
            let maxDimensions: [CGFloat] = [500, 1000, 2000]
            
            for maxDimension in maxDimensions {
                let resized = ImageCompressor.resizeImage(image, maxDimension: maxDimension)
                
                // The larger dimension should not exceed maxDimension
                let largerDimension = max(resized.size.width, resized.size.height)
                
                // Allow for small rounding errors
                XCTAssertLessThanOrEqual(largerDimension, maxDimension + 1, "Resized image's larger dimension should not exceed maxDimension")
                
                // Check aspect ratio is preserved (with small tolerance for rounding)
                let originalRatio = testSize.width / testSize.height
                let resizedRatio = resized.size.width / resized.size.height
                XCTAssertEqual(originalRatio, resizedRatio, accuracy: 0.01, "Aspect ratio should be preserved")
                
                // If original is smaller than max dimension, size should be unchanged
                if max(testSize.width, testSize.height) <= maxDimension {
                    XCTAssertEqual(resized.size.width, testSize.width, accuracy: 1, "Width should be unchanged if smaller than maxDimension")
                    XCTAssertEqual(resized.size.height, testSize.height, accuracy: 1, "Height should be unchanged if smaller than maxDimension")
                }
            }
        }
    }
    
    func testProgressiveCompression() {
        // Create a large image that will require multiple compression passes
        let largeImage = createTestImage(width: 4000, height: 4000, color: .systemRed)
        
        // Set a very small max size to force multiple compression steps
        let maxKB = 100 // 100KB
        let data = ImageCompressor.compressImageData(largeImage, maxSizeKB: maxKB)
        
        XCTAssertNotNil(data, "Compression should return data even with aggressive size limit")
        if let count = data?.count {
            XCTAssertLessThanOrEqual(count, maxKB * 1024, "Compressed data should be <= specified max size")
        }
    }
    
    func testEdgeCases() {
        // Test very small image
        let smallImage = createTestImage(width: 50, height: 50, color: .systemGray)
        let smallData = ImageCompressor.compressImageData(smallImage, maxSizeKB: 100)
        XCTAssertNotNil(smallData, "Should handle small images")
        
        // Test single pixel image
        let pixelImage = createTestImage(width: 1, height: 1, color: .black)
        let pixelData = ImageCompressor.compressImageData(pixelImage, maxSizeKB: 10)
        XCTAssertNotNil(pixelData, "Should handle 1x1 pixel images")
        
        // Test extreme compression
        let mediumImage = createTestImage(width: 800, height: 600, color: .systemYellow)
        let tinyData = ImageCompressor.compressImageData(mediumImage, maxSizeKB: 1) // 1KB
        XCTAssertNotNil(tinyData, "Should not return nil even with extreme compression requirements")
    }
}