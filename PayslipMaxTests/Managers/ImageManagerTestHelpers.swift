import UIKit

/// Helper methods for ImageManager tests
enum ImageManagerTestHelpers {

    /// Creates a simple test image with the specified size and color
    static func createTestImage(
        size: CGSize = CGSize(width: 100, height: 100),
        color: UIColor = .red
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

