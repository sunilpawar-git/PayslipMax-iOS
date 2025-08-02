import Foundation

/// Mock implementation of DocumentMetadataExtractorProtocol for testing purposes.
///
/// This mock service simulates document metadata extraction functionality without
/// requiring actual regex processing. It provides controllable behavior
/// for testing metadata extraction scenarios including dates, periods, and document info.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockDocumentMetadataExtractor: DocumentMetadataExtractorProtocol {
    
    // MARK: - Properties
    
    /// The metadata to return from extraction operations
    var mockMetadata: [String: String] = [:]
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    // MARK: - Initialization
    
    init() {
        setupDefaultMockMetadata()
    }
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        setupDefaultMockMetadata()
        shouldFail = false
    }
    
    /// Mock implementation of metadata extraction
    /// - Parameter text: The document text (ignored in mock)
    /// - Returns: The configured mock metadata
    func extractMetadata(from text: String) -> [String: String] {
        if shouldFail {
            return [:]
        }
        
        return mockMetadata
    }
    
    // MARK: - Private Methods
    
    /// Sets up default mock metadata for testing
    private func setupDefaultMockMetadata() {
        mockMetadata = [
            // Basic document date
            "documentDate": "15/06/2024",
            
            // Month and year information
            "month": "June",
            "year": "2024",
            
            // Statement period information
            "periodStart": "01/06/2024",
            "periodEnd": "30/06/2024"
        ]
    }
}