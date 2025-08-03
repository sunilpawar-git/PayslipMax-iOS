import Foundation

/// Mock implementation of DocumentStructureIdentifierProtocol for testing purposes.
///
/// This mock service simulates document structure identification functionality without
/// requiring actual text analysis. It provides controllable behavior
/// for testing structure detection scenarios.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockDocumentStructureIdentifier: DocumentStructureIdentifierProtocol {
    
    // MARK: - Properties
    
    /// The document structure to return from identification operations
    var mockDocumentStructure: DocumentStructure = .armyFormat
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        mockDocumentStructure = .armyFormat
        shouldFail = false
    }
    
    /// Mock implementation of document structure identification
    /// - Parameter text: The full text of the document (ignored in mock)
    /// - Returns: The configured mock document structure
    func identifyDocumentStructure(from text: String) -> DocumentStructure {
        if shouldFail {
            return .unknown
        }
        
        return mockDocumentStructure
    }
}