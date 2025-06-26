import Foundation
import PDFKit

/// Mock implementation of PDFTextExtractionServiceProtocol for testing purposes.
///
/// This mock service simulates PDF text extraction functionality with
/// controllable success/failure modes and customizable text output.
/// It includes memory usage simulation for testing resource management.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockPDFTextExtractionService: PDFTextExtractionServiceProtocol {
    
    // MARK: - Properties
    
    /// Controls whether operations should succeed
    var shouldSucceed = true
    
    /// The text to return from extraction operations
    var textToReturn = "Mock PDF content for testing purposes"
    
    // MARK: - Initialization
    
    /// Creates a mock service with configurable behavior.
    /// - Parameters:
    ///   - shouldSucceed: Whether operations should succeed (default: true)
    ///   - textToReturn: Custom text to return (optional)
    init(shouldSucceed: Bool = true, textToReturn: String? = nil) {
        self.shouldSucceed = shouldSucceed
        if let text = textToReturn {
            self.textToReturn = text
        }
    }
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        shouldSucceed = true
        textToReturn = "Mock PDF content for testing purposes"
    }
    
    // MARK: - PDFTextExtractionServiceProtocol Implementation
    
    func extractText(from data: Data) throws -> String {
        if !shouldSucceed {
            throw PDFProcessingError.textExtractionFailed
        }
        return textToReturn
    }
    
    func extractText(from document: PDFDocument, callback: ((String, Int, Int) -> Void)? = nil) -> String? {
        if !shouldSucceed {
            return nil
        }
        
        // Simulate callback if provided
        if let callback = callback {
            callback(textToReturn, 1, 1)
        }
        
        return textToReturn
    }
    
    func extractTextFromPage(at pageIndex: Int, in document: PDFDocument) -> String? {
        if !shouldSucceed {
            return nil
        }
        return textToReturn
    }
    
    func extractText(from document: PDFDocument, in range: ClosedRange<Int>) -> String? {
        if !shouldSucceed {
            return nil
        }
        return textToReturn
    }
    
    func currentMemoryUsage() -> UInt64 {
        return 1024 * 1024 // Return 1MB as mock memory usage
    }
} 