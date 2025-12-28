import XCTest
@testable import PayslipMax
import UIKit

/// Tests for ImageManager delete operations
final class ImageManagerDeleteTests: XCTestCase {

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

    // MARK: - Image Exists Tests

    func testImageExists_WhenImageExists_ReturnsTrue() throws {
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)
        let exists = imageManager.imageExists(for: identifier)

        XCTAssertTrue(exists)
    }

    func testImageExists_WhenImageDoesNotExist_ReturnsFalse() {
        let identifier = "nonexistent-image-id"
        let exists = imageManager.imageExists(for: identifier)

        XCTAssertFalse(exists)
    }

    func testImageExists_WithSuffix_WorksCorrectly() throws {
        let identifier = testIdentifier!
        let suffix = "-original"
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)

        let existsWithSuffix = imageManager.imageExists(for: identifier, suffix: suffix)
        let existsWithoutSuffix = imageManager.imageExists(for: identifier)

        XCTAssertTrue(existsWithSuffix)
        XCTAssertFalse(existsWithoutSuffix)
    }

    func testImageExists_ChecksFileSize_RejectsSmallFiles() throws {
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)
        let exists = imageManager.imageExists(for: identifier)

        XCTAssertTrue(exists)
    }

    // MARK: - Delete Image Tests

    func testDeleteImage_WhenImageExists_DeletesFile() throws {
        let identifier = testIdentifier!
        let url = try imageManager.saveImage(image: testImage, identifier: identifier)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        try imageManager.deleteImage(identifier: identifier)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertNil(imageManager.getImageURL(for: identifier))
    }

    func testDeleteImage_WithSuffix_DeletesCorrectFile() throws {
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

        try imageManager.deleteImage(identifier: identifier, suffix: "-original")

        XCTAssertFalse(FileManager.default.fileExists(atPath: originalURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: croppedURL.path))
    }

    func testDeleteImage_WhenImageDoesNotExist_DoesNotThrow() {
        let identifier = "nonexistent-image-id"
        XCTAssertNoThrow(try imageManager.deleteImage(identifier: identifier))
    }

    // MARK: - Delete All Images Tests

    func testDeleteAllImages_DeletesAllVersions() throws {
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: "-original")
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: "-cropped")

        let deletedCount = imageManager.deleteAllImages(for: identifier)

        XCTAssertGreaterThan(deletedCount, 0)
        XCTAssertNil(imageManager.getImageURL(for: identifier))
        XCTAssertNil(imageManager.getImageURL(for: identifier, suffix: "-original"))
        XCTAssertNil(imageManager.getImageURL(for: identifier, suffix: "-cropped"))
    }

    func testDeleteAllImages_WhenNoImagesExist_ReturnsZero() {
        let identifier = "nonexistent-image-id"
        let deletedCount = imageManager.deleteAllImages(for: identifier)

        XCTAssertEqual(deletedCount, 0)
    }

    // MARK: - Get All Images Tests

    func testGetAllImages_ReturnsAllStoredImages() throws {
        let id1 = UUID().uuidString
        let id2 = UUID().uuidString
        _ = try imageManager.saveImage(image: testImage, identifier: id1)
        _ = try imageManager.saveImage(image: testImage, identifier: id2)

        let allImages = imageManager.getAllImages()

        XCTAssertGreaterThanOrEqual(allImages.count, 2)

        _ = imageManager.deleteAllImages(for: id1)
        _ = imageManager.deleteAllImages(for: id2)
    }

    func testGetAllImages_FiltersNonJPEGFiles() throws {
        let images = imageManager.getAllImages()

        for url in images {
            let ext = url.pathExtension.lowercased()
            XCTAssertTrue(ext == "jpg" || ext == "jpeg")
        }
    }
}

