import XCTest
@testable import PayslipMax
import UIKit

/// Tests for ImageManager save operations
final class ImageManagerSaveTests: XCTestCase {

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
        try? imageManager.deleteAllImages(for: testIdentifier)
        testIdentifier = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - Save Image Tests

    func testSaveImage_WhenSuccessful_ReturnsURL() throws {
        let identifier = testIdentifier!
        let url = try imageManager.saveImage(image: testImage, identifier: identifier)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.path.contains(identifier))
        XCTAssertTrue(url.pathExtension == "jpg")
    }

    func testSaveImage_WithSuffix_CreatesFileWithSuffix() throws {
        let identifier = testIdentifier!
        let suffix = "-original"
        let url = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.lastPathComponent.contains(suffix))
    }

    func testSaveImage_MultipleSuffixes_CreatesSeparateFiles() throws {
        let identifier = testIdentifier!
        let originalURL = try imageManager.saveImage(
            image: testImage,
            identifier: identifier,
            suffix: "-original"
        )
        let croppedURL = try imageManager.saveImage(
            image: testImage,
            identifier: identifier,
            suffix: "-cropped"
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: originalURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: croppedURL.path))
        XCTAssertNotEqual(originalURL, croppedURL)
    }

    func testSaveImage_OverwritesExisting_WhenCalledTwice() throws {
        let identifier = testIdentifier!
        let firstImage = testImage!
        let secondImage = ImageManagerTestHelpers.createTestImage(color: .blue)

        let firstURL = try imageManager.saveImage(image: firstImage, identifier: identifier)
        let secondURL = try imageManager.saveImage(image: secondImage, identifier: identifier)

        XCTAssertEqual(firstURL, secondURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondURL.path))

        let savedData = try Data(contentsOf: secondURL)
        XCTAssertGreaterThan(savedData.count, 100)
    }

    // MARK: - Save with Retry Tests

    func testSaveWithRetry_WhenSuccessful_ReturnsURL() throws {
        let identifier = testIdentifier!
        let url = try imageManager.saveWithRetry(
            image: testImage,
            identifier: identifier,
            maxRetries: 3
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testSaveWithRetry_WithSuffix_WorksCorrectly() throws {
        let identifier = testIdentifier!
        let suffix = "-test"
        let url = try imageManager.saveWithRetry(
            image: testImage,
            identifier: identifier,
            suffix: suffix,
            maxRetries: 2
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.lastPathComponent.contains(suffix))
    }
}

