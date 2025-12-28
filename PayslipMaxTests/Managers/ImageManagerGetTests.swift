import XCTest
@testable import PayslipMax
import UIKit

/// Tests for ImageManager get/read operations
final class ImageManagerGetTests: XCTestCase {

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

    // MARK: - Get Image URL Tests

    func testGetImageURL_WhenImageExists_ReturnsURL() throws {
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)
        let url = imageManager.getImageURL(for: identifier)

        XCTAssertNotNil(url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
    }

    func testGetImageURL_WhenImageDoesNotExist_ReturnsNil() {
        let identifier = "nonexistent-image-id"
        let url = imageManager.getImageURL(for: identifier)

        XCTAssertNil(url)
    }

    func testGetImageURL_WithSuffix_ReturnsCorrectURL() throws {
        let identifier = testIdentifier!
        let suffix = "-original"
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)
        let url = imageManager.getImageURL(for: identifier, suffix: suffix)

        XCTAssertNotNil(url)
        XCTAssertTrue(url!.lastPathComponent.contains(suffix))
    }

    // MARK: - Get Image Data Tests

    func testGetImageData_WhenImageExists_ReturnsData() throws {
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)
        let data = imageManager.getImageData(for: identifier)

        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data!.count, 0)
    }

    func testGetImageData_WhenImageDoesNotExist_ReturnsNil() {
        let identifier = "nonexistent-image-id"
        let data = imageManager.getImageData(for: identifier)

        XCTAssertNil(data)
    }

    func testGetImageData_WithSuffix_ReturnsCorrectData() throws {
        let identifier = testIdentifier!
        let suffix = "-cropped"
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)
        let data = imageManager.getImageData(for: identifier, suffix: suffix)

        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data!.count, 0)
    }

    // MARK: - Get Image Tests

    func testGetImage_WhenImageExists_ReturnsUIImage() throws {
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)
        let loadedImage = imageManager.getImage(for: identifier)

        XCTAssertNotNil(loadedImage)
        let originalPixelWidth = testImage.size.width * testImage.scale
        let originalPixelHeight = testImage.size.height * testImage.scale
        let loadedPixelWidth = loadedImage!.size.width * loadedImage!.scale
        let loadedPixelHeight = loadedImage!.size.height * loadedImage!.scale

        XCTAssertEqual(loadedPixelWidth, originalPixelWidth, accuracy: 1.0)
        XCTAssertEqual(loadedPixelHeight, originalPixelHeight, accuracy: 1.0)
    }

    func testGetImage_WhenImageDoesNotExist_ReturnsNil() {
        let identifier = "nonexistent-image-id"
        let image = imageManager.getImage(for: identifier)

        XCTAssertNil(image)
    }

    func testGetImage_WithSuffix_ReturnsCorrectImage() throws {
        let identifier = testIdentifier!
        let suffix = "-test"
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)
        let image = imageManager.getImage(for: identifier, suffix: suffix)

        XCTAssertNotNil(image)
    }
}

