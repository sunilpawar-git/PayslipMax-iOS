import Foundation

/// Mock implementation of PersonalInfoSectionParserProtocol for testing purposes.
///
/// This mock service simulates personal information parsing functionality without
/// requiring actual regex processing. It provides controllable behavior
/// for testing personal info extraction scenarios.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockPersonalInfoSectionParser: PersonalInfoSectionParserProtocol {
    
    // MARK: - Properties
    
    /// The personal information to return from parsing operations
    var mockPersonalInfo: [String: String] = [:]
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    // MARK: - Initialization
    
    init() {
        // Set up default mock personal info
        setupDefaultMockPersonalInfo()
    }
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        setupDefaultMockPersonalInfo()
        shouldFail = false
    }
    
    /// Mock implementation of personal information parsing
    /// - Parameter section: The document section (ignored in mock)
    /// - Returns: The configured mock personal information
    func parsePersonalInfoSection(_ section: DocumentSection) -> [String: String] {
        if shouldFail {
            return [:]
        }
        
        return mockPersonalInfo
    }
    
    // MARK: - Private Methods
    
    /// Sets up default mock personal information for testing
    private func setupDefaultMockPersonalInfo() {
        mockPersonalInfo = [
            "name": "John Doe",
            "rank": "Captain",
            "serviceNumber": "12345",
            "accountNumber": "1234567890",
            "panNumber": "ABCDE1234F"
        ]
    }
}