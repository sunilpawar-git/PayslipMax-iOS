import Foundation

/// Mock implementation of ContactInfoSectionParserProtocol for testing purposes.
///
/// This mock service simulates contact information parsing functionality without
/// requiring actual regex processing. It provides controllable behavior
/// for testing contact extraction scenarios including military roles, emails, and websites.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockContactInfoSectionParser: ContactInfoSectionParserProtocol {
    
    // MARK: - Properties
    
    /// The contact information to return from parsing operations
    var mockContactInfo: [String: String] = [:]
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    // MARK: - Initialization
    
    init() {
        setupDefaultMockContactInfo()
    }
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        setupDefaultMockContactInfo()
        shouldFail = false
    }
    
    /// Mock implementation of contact information parsing
    /// - Parameter section: The document section (ignored in mock)
    /// - Returns: The configured mock contact information
    func parseContactSection(_ section: DocumentSection) -> [String: String] {
        if shouldFail {
            return [:]
        }
        
        return mockContactInfo
    }
    
    // MARK: - Private Methods
    
    /// Sets up default mock contact information for testing
    private func setupDefaultMockContactInfo() {
        mockContactInfo = [
            // Military contact roles
            "SAOLW": "SAO (LW): 011-26717823",
            "AAOLW": "AAO (LW): 011-26717824", 
            "SAOTW": "SAO (TW): 011-26717825",
            "AAOTW": "AAO (TW): 011-26717826",
            "ProCivil": "PRO CIVIL: 011-26717827",
            "ProArmy": "PRO ARMY: 011-26717828",
            "HelpDesk": "HELP DESK: 011-26717829",
            
            // General phones
            "phone1": "011-26717830",
            "phone2": "011-26717831",
            
            // Categorized emails
            "emailTADA": "tada@indianarmy.nic.in",
            "emailLedger": "ledger@indianarmy.nic.in",
            "emailRankPay": "rankpay@indianarmy.nic.in",
            "emailGeneral": "general@indianarmy.nic.in",
            "email1": "contact@indianarmy.nic.in",
            
            // Website
            "website": "www.indianarmy.nic.in"
        ]
    }
}