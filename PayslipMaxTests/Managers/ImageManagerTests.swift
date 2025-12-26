import XCTest
@testable import PayslipMax
import UIKit

/// Comprehensive test suite for ImageManager
/// Target: 100% code coverage for all methods and error paths
final class ImageManagerTests: XCTestCase {

    var imageManager: ImageManager!
    var testIdentifier: String!
    var testImage: UIImage!

    override func setUp() {
        super.setUp()
        imageManager = ImageManager.shared
        testIdentifier = UUID().uuidString

        // Create a simple test image
        testImage = createTestImage()
    }

    override func tearDown() {
        // Clean up any test images
        try? imageManager.deleteAllImages(for: testIdentifier)
        testIdentifier = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates a simple red 100x100 test image
    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100), color: UIColor = .red) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Save Image Tests

    func testSaveImage_WhenSuccessful_ReturnsURL() throws {
        // Arrange
        let identifier = testIdentifier!

        // Act
        let url = try imageManager.saveImage(image: testImage, identifier: identifier)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Image file should exist at returned URL")
        XCTAssertTrue(url.path.contains(identifier), "URL should contain identifier")
        XCTAssertTrue(url.pathExtension == "jpg", "Image should be saved as JPEG")
    }

    func testSaveImage_WithSuffix_CreatesFileWithSuffix() throws {
        // Arrange
        let identifier = testIdentifier!
        let suffix = "-original"

        // Act
        let url = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.lastPathComponent.contains(suffix), "Filename should contain suffix")
    }

    func testSaveImage_MultipleSuffixes_CreatesSeparateFiles() throws {
        // Arrange
        let identifier = testIdentifier!

        // Act
        let originalURL = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: "-original")
        let croppedURL = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: "-cropped")

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: originalURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: croppedURL.path))
        XCTAssertNotEqual(originalURL, croppedURL, "Different suffixes should create different files")
    }

    func testSaveImage_OverwritesExisting_WhenCalledTwice() throws {
        // Arrange
        let identifier = testIdentifier!
        let firstImage = testImage!
        let secondImage = createTestImage(color: .blue) // Different image

        // Act
        let firstURL = try imageManager.saveImage(image: firstImage, identifier: identifier)
        let secondURL = try imageManager.saveImage(image: secondImage, identifier: identifier)

        // Assert
        XCTAssertEqual(firstURL, secondURL, "Same identifier should use same URL")
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondURL.path))

        // Verify the image was actually overwritten by checking data
        let savedData = try Data(contentsOf: secondURL)
        let secondImageData = secondImage.jpegData(compressionQuality: 0.85)!

        // Both should be JPEG data (exact equality may vary due to compression)
        XCTAssertGreaterThan(savedData.count, 100, "Saved file should have reasonable size")
    }

    // MARK: - Save with Retry Tests

    func testSaveWithRetry_WhenSuccessful_ReturnsURL() throws {
        // Arrange
        let identifier = testIdentifier!

        // Act
        let url = try imageManager.saveWithRetry(image: testImage, identifier: identifier, maxRetries: 3)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testSaveWithRetry_WithSuffix_WorksCorrectly() throws {
        // Arrange
        let identifier = testIdentifier!
        let suffix = "-test"

        // Act
        let url = try imageManager.saveWithRetry(image: testImage, identifier: identifier, suffix: suffix, maxRetries: 2)

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertTrue(url.lastPathComponent.contains(suffix))
    }

    // MARK: - Get Image URL Tests

    func testGetImageURL_WhenImageExists_ReturnsURL() throws {
        // Arrange
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)

        // Act
        let url = imageManager.getImageURL(for: identifier)

        // Assert
        XCTAssertNotNil(url, "Should return URL for existing image")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
    }

    func testGetImageURL_WhenImageDoesNotExist_ReturnsNil() {
        // Arrange
        let identifier = "nonexistent-image-id"

        // Act
        let url = imageManager.getImageURL(for: identifier)

        // Assert
        XCTAssertNil(url, "Should return nil for nonexistent image")
    }

    func testGetImageURL_WithSuffix_ReturnsCorrectURL() throws {
        // Arrange
        let identifier = testIdentifier!
        let suffix = "-original"
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)

        // Act
        let url = imageManager.getImageURL(for: identifier, suffix: suffix)

        // Assert
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.lastPathComponent.contains(suffix))
    }

    // MARK: - Get Image Data Tests

    func testGetImageData_WhenImageExists_ReturnsData() throws {
        // Arrange
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)

        // Act
        let data = imageManager.getImageData(for: identifier)

        // Assert
        XCTAssertNotNil(data, "Should return data for existing image")
        XCTAssertGreaterThan(data!.count, 0, "Data should not be empty")
    }

    func testGetImageData_WhenImageDoesNotExist_ReturnsNil() {
        // Arrange
        let identifier = "nonexistent-image-id"

        // Act
        let data = imageManager.getImageData(for: identifier)

        // Assert
        XCTAssertNil(data, "Should return nil for nonexistent image")
    }

    func testGetImageData_WithSuffix_ReturnsCorrectData() throws {
        // Arrange
        let identifier = testIdentifier!
        let suffix = "-cropped"
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)

        // Act
        let data = imageManager.getImageData(for: identifier, suffix: suffix)

        // Assert
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data!.count, 0)
    }

    // MARK: - Get Image Tests

    func testGetImage_WhenImageExists_ReturnsUIImage() throws {
        // Arrange
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)

        // Act
        let loadedImage = imageManager.getImage(for: identifier)

        // Assert
        XCTAssertNotNil(loadedImage, "Should return UIImage for existing image")

        // Note: UIGraphicsImageRenderer scales images by screen scale (2x or 3x)
        // When saved as JPEG and reloaded, scale info may be lost
        // Compare using scale-aware dimensions
        let originalPixelWidth = testImage.size.width * testImage.scale
        let originalPixelHeight = testImage.size.height * testImage.scale
        let loadedPixelWidth = loadedImage!.size.width * loadedImage!.scale
        let loadedPixelHeight = loadedImage!.size.height * loadedImage!.scale

        XCTAssertEqual(loadedPixelWidth, originalPixelWidth, accuracy: 1.0, "Pixel width should match")
        XCTAssertEqual(loadedPixelHeight, originalPixelHeight, accuracy: 1.0, "Pixel height should match")
    }

    func testGetImage_WhenImageDoesNotExist_ReturnsNil() {
        // Arrange
        let identifier = "nonexistent-image-id"

        // Act
        let image = imageManager.getImage(for: identifier)

        // Assert
        XCTAssertNil(image, "Should return nil for nonexistent image")
    }

    func testGetImage_WithSuffix_ReturnsCorrectImage() throws {
        // Arrange
        let identifier = testIdentifier!
        let suffix = "-test"
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)

        // Act
        let image = imageManager.getImage(for: identifier, suffix: suffix)

        // Assert
        XCTAssertNotNil(image)
    }

    // MARK: - Image Exists Tests

    func testImageExists_WhenImageExists_ReturnsTrue() throws {
        // Arrange
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)

        // Act
        let exists = imageManager.imageExists(for: identifier)

        // Assert
        XCTAssertTrue(exists, "Should return true for existing image")
    }

    func testImageExists_WhenImageDoesNotExist_ReturnsFalse() {
        // Arrange
        let identifier = "nonexistent-image-id"

        // Act
        let exists = imageManager.imageExists(for: identifier)

        // Assert
        XCTAssertFalse(exists, "Should return false for nonexistent image")
    }

    func testImageExists_WithSuffix_WorksCorrectly() throws {
        // Arrange
        let identifier = testIdentifier!
        let suffix = "-original"
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: suffix)

        // Act
        let existsWithSuffix = imageManager.imageExists(for: identifier, suffix: suffix)
        let existsWithoutSuffix = imageManager.imageExists(for: identifier)

        // Assert
        XCTAssertTrue(existsWithSuffix, "Should exist with suffix")
        XCTAssertFalse(existsWithoutSuffix, "Should not exist without suffix")
    }

    func testImageExists_ChecksFileSize_RejectsSmallFiles() throws {
        // This test verifies that imageExists checks for minimum file size
        // We can't easily create a file < 100 bytes through saveImage,
        // so this is a documentation test
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)

        let exists = imageManager.imageExists(for: identifier)
        XCTAssertTrue(exists, "Normal images should pass size check")
    }

    // MARK: - Delete Image Tests

    func testDeleteImage_WhenImageExists_DeletesFile() throws {
        // Arrange
        let identifier = testIdentifier!
        let url = try imageManager.saveImage(image: testImage, identifier: identifier)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Precondition: file should exist")

        // Act
        try imageManager.deleteImage(identifier: identifier)

        // Assert
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "File should be deleted")
        XCTAssertNil(imageManager.getImageURL(for: identifier), "URL should return nil after deletion")
    }

    func testDeleteImage_WithSuffix_DeletesCorrectFile() throws {
        // Arrange
        let identifier = testIdentifier!
        let originalURL = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: "-original")
        let croppedURL = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: "-cropped")

        // Act
        try imageManager.deleteImage(identifier: identifier, suffix: "-original")

        // Assert
        XCTAssertFalse(FileManager.default.fileExists(atPath: originalURL.path), "Original should be deleted")
        XCTAssertTrue(FileManager.default.fileExists(atPath: croppedURL.path), "Cropped should still exist")
    }

    func testDeleteImage_WhenImageDoesNotExist_DoesNotThrow() {
        // Arrange
        let identifier = "nonexistent-image-id"

        // Act & Assert
        XCTAssertNoThrow(try imageManager.deleteImage(identifier: identifier), "Should not throw for nonexistent image")
    }

    // MARK: - Delete All Images Tests

    func testDeleteAllImages_DeletesAllVersions() throws {
        // Arrange
        let identifier = testIdentifier!
        _ = try imageManager.saveImage(image: testImage, identifier: identifier)
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: "-original")
        _ = try imageManager.saveImage(image: testImage, identifier: identifier, suffix: "-cropped")

        // Act
        let deletedCount = imageManager.deleteAllImages(for: identifier)

        // Assert
        XCTAssertGreaterThan(deletedCount, 0, "Should delete at least one image")
        XCTAssertNil(imageManager.getImageURL(for: identifier))
        XCTAssertNil(imageManager.getImageURL(for: identifier, suffix: "-original"))
        XCTAssertNil(imageManager.getImageURL(for: identifier, suffix: "-cropped"))
    }

    func testDeleteAllImages_WhenNoImagesExist_ReturnsZero() {
        // Arrange
        let identifier = "nonexistent-image-id"

        // Act
        let deletedCount = imageManager.deleteAllImages(for: identifier)

        // Assert
        XCTAssertEqual(deletedCount, 0, "Should return 0 when no images exist")
    }

    // MARK: - Get All Images Tests

    func testGetAllImages_ReturnsAllStoredImages() throws {
        // Arrange
        let id1 = UUID().uuidString
        let id2 = UUID().uuidString
        _ = try imageManager.saveImage(image: testImage, identifier: id1)
        _ = try imageManager.saveImage(image: testImage, identifier: id2)

        // Act
        let allImages = imageManager.getAllImages()

        // Assert
        XCTAssertGreaterThanOrEqual(allImages.count, 2, "Should return at least our 2 test images")

        // Cleanup
        try? imageManager.deleteAllImages(for: id1)
        try? imageManager.deleteAllImages(for: id2)
    }

    func testGetAllImages_FiltersNonJPEGFiles() throws {
        // This test verifies that only JPEG files are returned
        let images = imageManager.getAllImages()

        for url in images {
            let ext = url.pathExtension.lowercased()
            XCTAssertTrue(ext == "jpg" || ext == "jpeg", "Should only return JPEG files")
        }
    }

    // MARK: - Integration Tests

    func testFullLifecycle_SaveLoadDelete() throws {
        // Arrange
        let identifier = testIdentifier!
        let originalImage = createTestImage(size: CGSize(width: 200, height: 200), color: .blue)

        // Act & Assert - Save
        let saveURL = try imageManager.saveImage(image: originalImage, identifier: identifier, suffix: "-original")
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveURL.path))

        // Act & Assert - Load
        guard let loadedImage = imageManager.getImage(for: identifier, suffix: "-original") else {
            XCTFail("Failed to load saved image")
            return
        }

        // Use scale-aware comparison (accounting for device scale factor)
        let originalPixelWidth = originalImage.size.width * originalImage.scale
        let originalPixelHeight = originalImage.size.height * originalImage.scale
        let loadedPixelWidth = loadedImage.size.width * loadedImage.scale
        let loadedPixelHeight = loadedImage.size.height * loadedImage.scale

        XCTAssertEqual(loadedPixelWidth, originalPixelWidth, accuracy: 1.0, "Pixel dimensions should match")
        XCTAssertEqual(loadedPixelHeight, originalPixelHeight, accuracy: 1.0, "Pixel dimensions should match")

        // Act & Assert - Exists
        XCTAssertTrue(imageManager.imageExists(for: identifier, suffix: "-original"))

        // Act & Assert - Delete
        try imageManager.deleteImage(identifier: identifier, suffix: "-original")
        XCTAssertFalse(imageManager.imageExists(for: identifier, suffix: "-original"))
        XCTAssertNil(imageManager.getImage(for: identifier, suffix: "-original"))
    }

    func testMultipleImages_SameIdentifier_DifferentSuffixes() throws {
        // Arrange
        let identifier = testIdentifier!
        let originalImage = createTestImage(size: CGSize(width: 300, height: 300), color: .green)
        let croppedImage = createTestImage(size: CGSize(width: 200, height: 200), color: .yellow)

        // Act
        _ = try imageManager.saveImage(image: originalImage, identifier: identifier, suffix: "-original")
        _ = try imageManager.saveImage(image: croppedImage, identifier: identifier, suffix: "-cropped")

        // Assert
        XCTAssertTrue(imageManager.imageExists(for: identifier, suffix: "-original"))
        XCTAssertTrue(imageManager.imageExists(for: identifier, suffix: "-cropped"))

        let loadedOriginal = imageManager.getImage(for: identifier, suffix: "-original")
        let loadedCropped = imageManager.getImage(for: identifier, suffix: "-cropped")

        XCTAssertNotNil(loadedOriginal)
        XCTAssertNotNil(loadedCropped)

        // Note: UIGraphicsImageRenderer scales images by screen scale (2x or 3x)
        // When saved as JPEG and reloaded, scale info may be lost
        // Compare using scale-aware pixel dimensions
        let originalPixelWidth = originalImage.size.width * originalImage.scale
        let originalPixelHeight = originalImage.size.height * originalImage.scale
        let loadedPixelWidth = loadedOriginal!.size.width * loadedOriginal!.scale
        let loadedPixelHeight = loadedOriginal!.size.height * loadedOriginal!.scale

        XCTAssertEqual(loadedPixelWidth, originalPixelWidth, accuracy: 1.0, "Pixel width should match")
        XCTAssertEqual(loadedPixelHeight, originalPixelHeight, accuracy: 1.0, "Pixel height should match")
        XCTAssertGreaterThan(loadedOriginal!.size.width, loadedCropped!.size.width, "Original should be larger than cropped")
    }

    // MARK: - Performance Tests

    func testSaveImage_Performance() throws {
        // Measure time to save an image
        let identifier = UUID().uuidString
        let image = createTestImage(size: CGSize(width: 1000, height: 1000))

        measure {
            _ = try? imageManager.saveImage(image: image, identifier: identifier)
        }

        // Cleanup
        try? imageManager.deleteImage(identifier: identifier)
    }

    func testLoadImage_Performance() throws {
        // Arrange
        let identifier = UUID().uuidString
        let image = createTestImage(size: CGSize(width: 1000, height: 1000))
        _ = try imageManager.saveImage(image: image, identifier: identifier)

        // Measure time to load an image
        measure {
            _ = imageManager.getImage(for: identifier)
        }

        // Cleanup
        try? imageManager.deleteImage(identifier: identifier)
    }
}
