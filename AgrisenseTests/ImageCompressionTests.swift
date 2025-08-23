import XCTest
@testable import Agrisense
import UIKit

final class ImageCompressionTests: XCTestCase {
    func testCompressionUnder5MB() {
        // Create a large test image (4000x4000 px) filled with color
        let size = CGSize(width: 4000, height: 4000)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        UIColor.systemGreen.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        let maxKB = 5 * 1024
        let data = ImageCompressor.compressImageData(image, maxSizeKB: maxKB)

        XCTAssertNotNil(data, "Compression should return data")
        if let count = data?.count {
            XCTAssertLessThanOrEqual(count, maxKB * 1024, "Compressed data should be <= 5 MB")
        }
    }
}
