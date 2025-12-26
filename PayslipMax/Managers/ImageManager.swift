import Foundation
import UIKit

/// Errors that can occur during image storage and management operations.
enum ImageStorageError: Error {
    /// An error occurred while attempting to save the image file to disk.
    case failedToSave
    /// The requested image file could not be found at the expected location.
    case fileNotFound
    /// The provided image data could not be converted to JPEG format.
    case conversionFailed
    /// The necessary directory for storing images could not be created.
    case failedToCreateDirectory
}

/// Manages the storage, retrieval, and deletion of image files.
/// Provides a centralized interface for handling image documents within the application's sandboxed storage.
///
/// **Usage**:
/// ```swift
/// let manager = ImageManager.shared
/// try manager.saveImage(image: myImage, identifier: "uuid", suffix: "-original")
/// let url = manager.getImageURL(for: "uuid", suffix: "-original")
/// ```
///
/// **Storage Location**: `Documents/Images/`
/// **Format**: JPEG with 0.85 compression quality
/// **Thread Safety**: Singleton pattern with thread-safe file operations
final class ImageManager {
    /// Shared singleton instance of the ImageManager.
    static let shared = ImageManager()

    /// Standard file manager instance.
    private let fileManager = FileManager.default

    /// Logging category for this manager.
    private let logCategory = "ImageManager"

    /// JPEG compression quality (0.0 - 1.0). 0.85 provides good balance between quality and file size.
    private let compressionQuality: CGFloat = 0.85

    /// Private initializer to ensure singleton usage. Creates the image directory if it doesn't exist.
    private init() {
        checkAndCreateImageDirectory()
    }

    // MARK: - Image Directory Management

    /// Checks if the image storage directory exists, creates it if necessary, and verifies writability.
    private func checkAndCreateImageDirectory() {
        let directoryPath = getImageDirectoryPath().path
        if !fileManager.fileExists(atPath: directoryPath) {
            do {
                try fileManager.createDirectory(at: getImageDirectoryPath(), withIntermediateDirectories: true)
                Logger.info("Image directory created successfully", category: logCategory)
            } catch {
                Logger.error("Error creating image directory: \(error)", category: logCategory)
            }
        }

        // Verify the directory is writable
        if fileManager.fileExists(atPath: directoryPath) {
            // Try to create a test file to verify write access
            let testFilePath = getImageDirectoryPath().appendingPathComponent("write_test.txt")
            do {
                try "Test write access".write(to: testFilePath, atomically: true, encoding: .utf8)
                try fileManager.removeItem(at: testFilePath) // Clean up test file
                Logger.info("Image directory is writable", category: logCategory)
            } catch {
                Logger.error("Image directory is not writable: \(error)", category: logCategory)
            }
        } else {
            Logger.error("Image directory does not exist and could not be created", category: logCategory)
        }
    }

    /// Gets the URL for the directory where images are stored within the app's documents directory.
    /// - Returns: A `URL` pointing to the `Documents/Images/` directory.
    private func getImageDirectoryPath() -> URL {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentDirectory.appendingPathComponent("Images", isDirectory: true)
    }

    /// Constructs the file URL for an image with a specific identifier and suffix.
    /// - Parameters:
    ///   - identifier: A unique string identifying the image file (e.g., a UUID).
    ///   - suffix: Optional suffix to append to the filename (e.g., "-original", "-cropped").
    /// - Returns: A `URL` pointing to the potential location of the image file.
    private func getFileURL(for identifier: String, suffix: String = "") -> URL {
        return getImageDirectoryPath().appendingPathComponent("\(identifier)\(suffix).jpg")
    }

    // MARK: - Image Storage Methods

    /// Saves an image to disk as JPEG with the specified identifier and optional suffix.
    /// - Parameters:
    ///   - image: The `UIImage` to save.
    ///   - identifier: A unique string to name the image file (typically a UUID string).
    ///   - suffix: Optional suffix to append to the filename (default: empty). Use "-original" or "-cropped" for multi-version storage.
    /// - Returns: The `URL` where the image was saved.
    /// - Throws: `ImageStorageError.conversionFailed` if JPEG conversion fails, or other errors if writing fails.
    func saveImage(image: UIImage, identifier: String, suffix: String = "") throws -> URL {
        // Convert UIImage to JPEG data
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            Logger.error("Failed to convert image to JPEG data", category: logCategory)
            throw ImageStorageError.conversionFailed
        }

        let fileURL = getFileURL(for: identifier, suffix: suffix)

        do {
            try imageData.write(to: fileURL, options: .atomic)
            Logger.info("Image saved successfully to \(fileURL.path)", category: logCategory)
            return fileURL
        } catch {
            Logger.error("Failed to save image to \(fileURL.path): \(error)", category: logCategory)
            throw error
        }
    }

    /// Saves an image with automatic retries on failure.
    /// - Parameters:
    ///   - image: The `UIImage` to save.
    ///   - identifier: A unique string to name the image file.
    ///   - suffix: Optional suffix to append to the filename (default: empty).
    ///   - maxRetries: The maximum number of times to retry saving upon failure (default: 3).
    /// - Returns: The `URL` where the image was saved.
    /// - Throws: The last error encountered if saving fails after all retries.
    func saveWithRetry(image: UIImage, identifier: String, suffix: String = "", maxRetries: Int = 3) throws -> URL {
        var lastError: Error?

        for attempt in 1...maxRetries {
            do {
                let url = try saveImage(image: image, identifier: identifier, suffix: suffix)
                Logger.info("Image saved successfully on attempt \(attempt)", category: logCategory)
                return url
            } catch {
                lastError = error
                Logger.warning("Error saving image (attempt \(attempt)): \(error)", category: logCategory)

                // Wait a bit before retrying
                if attempt < maxRetries {
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }
        }

        throw lastError ?? NSError(domain: "ImageManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to save image after \(maxRetries) attempts"])
    }

    /// Gets the URL for a stored image if it exists.
    /// - Parameters:
    ///   - identifier: The unique identifier of the image.
    ///   - suffix: Optional suffix used when the image was saved (default: empty).
    /// - Returns: The `URL` of the image file, or `nil` if it doesn't exist.
    func getImageURL(for identifier: String, suffix: String = "") -> URL? {
        let fileURL = getFileURL(for: identifier, suffix: suffix)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    /// Retrieves the data for a stored image if it exists.
    /// - Parameters:
    ///   - identifier: The unique identifier of the image.
    ///   - suffix: Optional suffix used when the image was saved (default: empty).
    /// - Returns: The `Data` of the image file, or `nil` if it doesn't exist or cannot be read.
    func getImageData(for identifier: String, suffix: String = "") -> Data? {
        guard let fileURL = getImageURL(for: identifier, suffix: suffix) else {
            Logger.warning("Image not found for identifier: \(identifier)\(suffix)", category: logCategory)
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            Logger.info("Image data loaded successfully for \(identifier)\(suffix)", category: logCategory)
            return data
        } catch {
            Logger.error("Failed to load image data: \(error)", category: logCategory)
            return nil
        }
    }

    /// Loads a UIImage from disk if it exists.
    /// - Parameters:
    ///   - identifier: The unique identifier of the image.
    ///   - suffix: Optional suffix used when the image was saved (default: empty).
    /// - Returns: The `UIImage` if it exists and can be loaded, or `nil` otherwise.
    func getImage(for identifier: String, suffix: String = "") -> UIImage? {
        guard let imageData = getImageData(for: identifier, suffix: suffix) else {
            return nil
        }

        return UIImage(data: imageData)
    }

    /// Checks if an image file exists for the given identifier and suffix, and has a reasonable size.
    /// - Parameters:
    ///   - identifier: The unique identifier of the image.
    ///   - suffix: Optional suffix used when the image was saved (default: empty).
    /// - Returns: `true` if an image file exists and is larger than 100 bytes, `false` otherwise.
    func imageExists(for identifier: String, suffix: String = "") -> Bool {
        let fileURL = getFileURL(for: identifier, suffix: suffix)
        let exists = fileManager.fileExists(atPath: fileURL.path)

        // Additional check for file size to ensure it's a valid image
        if exists {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let size = attributes[FileAttributeKey.size] as? Int, size > 100 {
                    return true
                }
            } catch {
                Logger.error("Error checking image file size: \(error)", category: logCategory)
            }
        }

        return false
    }

    // MARK: - Image Deletion

    /// Deletes the image file associated with the given identifier and suffix.
    /// - Parameters:
    ///   - identifier: The unique identifier of the image to delete.
    ///   - suffix: Optional suffix used when the image was saved (default: empty).
    /// - Throws: An error if the file exists but cannot be removed.
    func deleteImage(identifier: String, suffix: String = "") throws {
        if let imageURL = getImageURL(for: identifier, suffix: suffix) {
            try fileManager.removeItem(at: imageURL)
            Logger.info("Deleted image for ID \(identifier)\(suffix)", category: logCategory)
        } else {
            Logger.info("No image found to delete for ID \(identifier)\(suffix)", category: logCategory)
        }
    }

    /// Deletes all images associated with a given identifier (all suffixes).
    /// Attempts to delete both "-original" and "-cropped" versions.
    /// - Parameter identifier: The unique identifier of the images to delete.
    /// - Returns: Number of images successfully deleted.
    func deleteAllImages(for identifier: String) -> Int {
        var deletedCount = 0
        let suffixes = ["-original", "-cropped", ""] // Cover all variations

        for suffix in suffixes {
            do {
                try deleteImage(identifier: identifier, suffix: suffix)
                deletedCount += 1
            } catch {
                // Silently continue - file may not exist for this suffix
            }
        }

        if deletedCount > 0 {
            Logger.info("Deleted \(deletedCount) image(s) for ID \(identifier)", category: logCategory)
        }

        return deletedCount
    }

    /// Retrieves URLs for all image files currently stored in the image directory.
    /// - Returns: An array of `URL`s, each pointing to a stored image file.
    func getAllImages() -> [URL] {
        do {
            let files = try fileManager.contentsOfDirectory(at: getImageDirectoryPath(), includingPropertiesForKeys: nil)
            let imageFiles = files.filter { $0.pathExtension == "jpg" || $0.pathExtension == "jpeg" }
            Logger.info("Found \(imageFiles.count) image files", category: logCategory)
            return imageFiles
        } catch {
            Logger.error("Failed to get image files: \(error)", category: logCategory)
            return []
        }
    }
}
