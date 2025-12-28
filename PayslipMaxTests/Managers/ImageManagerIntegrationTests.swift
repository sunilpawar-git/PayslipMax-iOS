import XCTest
@testable import PayslipMax
import UIKit

/// Integration and performance tests for ImageManager
final class ImageManagerIntegrationTests: XCTestCase {

    var imageManager: ImageManager!
    var testIdentifier: String!
    var testImage: UIImage!

    override func setUp() {
        super.setUp()
        imageManager = ImageManager.shared
        testIdentifier = UUID().uuidString
        testImage = ImageManagerTestHelpers.createTestImage()
    }

    override func tearDown() {
        _ = imageManager.deleteAllImages(for: testIdentifier)
        testIdentifier = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - Integration Tests

    func testFullLifecycle_SaveLoadDelete() throws {
        let identifier = testIdentifier!
        let originalImage = ImageManagerTestHelpers.createTestImage(
            size: CGSize(width: 200, height: 200),
            color: .blue
        )

        let saveURL = try imageManager.saveImage(
            image: originalImage,
            identifier: identifier,
            suffix: "-original"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path))

        guard let loadedImage = imageManager.getImage(
            for: identifier,
            suffix: "-original"
        ) else {
            XCTFail("Failed to load saved image")
            return
        }

        let originalPixelWidth = originalImage.size.width * originalImage.scale
        let originalPixelHeight = originalImage.size.height * originalImage.scale
        let loadedPixelWidth = loadedImage.size.width * loadedImage.scale
        let loadedPixelHeight = loadedImage.size.height * loadedImage.scale

        XCTAssertEqual(loadedPixelWidth, originalPixelWidth, accuracy: 1.0)
        XCTAssertEqual(loadedPixelHeight, originalPixelHeight, accuracy: 1.0)

        XCTAssertTrue(imageManager.imageExists(for: identifier, suffix: "-original"))

        try imageManager.deleteImage(identifier: identifier, suffix: "-original")
        XCTAssertFalse(imageManager.imageExists(for: identifier, suffix: "-original"))
        XCTAssertNil(imageManager.getImage(for: identifier, suffix: "-original"))
    }

    func testMultipleImages_SameIdentifier_DifferentSuffixes() throws {
        let identifier = testIdentifier!
        let originalImage = ImageManagerTestHelpers.createTestImage(
            size: CGSize(width: 300, height: 300),
            color: .green
        )
        let croppedImage = ImageManagerTestHelpers.createTestImage(
            size: CGSize(width: 200, height: 200),
            color: .yellow
        )

        _ = try imageManager.saveImage(
            image: originalImage,
            identifier: identifier,
            suffix: "-original"
        )
        _ = try imageManager.saveImage(
            image: croppedImage,
            identifier: identifier,
            suffix: "-cropped"
        )

        XCTAssertTrue(imageManager.imageExists(for: identifier, suffix: "-original"))
        XCTAssertTrue(imageManager.imageExists(for: identifier, suffix: "-cropped"))

        let loadedOriginal = imageManager.getImage(for: identifier, suffix: "-original")
        let loadedCropped = imageManager.getImage(for: identifier, suffix: "-cropped")

        XCTAssertNotNil(loadedOriginal)
        XCTAssertNotNil(loadedCropped)

        let originalPixelWidth = originalImage.size.width * originalImage.scale
        let loadedPixelWidth = loadedOriginal!.size.width * loadedOriginal!.scale

        XCTAssertEqual(loadedPixelWidth, originalPixelWidth, accuracy: 1.0)
        XCTAssertGreaterThan(
            loadedOriginal!.size.width,
            loadedCropped!.size.width
        )
    }

    // MARK: - Performance Tests

    func testSaveImage_Performance() throws {
        let identifier = UUID().uuidString
        let image = ImageManagerTestHelpers.createTestImage(
            size: CGSize(width: 1000, height: 1000)
        )

        measure {
            _ = try? imageManager.saveImage(image: image, identifier: identifier)
        }

        _ = try? imageManager.deleteImage(identifier: identifier)
    }

    func testLoadImage_Performance() throws {
        let identifier = UUID().uuidString
        let image = ImageManagerTestHelpers.createTestImage(
            size: CGSize(width: 1000, height: 1000)
        )
        _ = try imageManager.saveImage(image: image, identifier: identifier)

        measure {
            _ = imageManager.getImage(for: identifier)
        }

        _ = try? imageManager.deleteImage(identifier: identifier)
    }
}

