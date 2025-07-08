import XCTest
@testable import PayslipMax

class ContactInfoExtractorTests: XCTestCase {
    
    var extractor: ContactInfoExtractor!
    
    override func setUp() {
        super.setUp()
        extractor = ContactInfoExtractor.shared
    }
    
    func testExtractEmails() {
        let testText = """
        CONTACT US
        
        YOUR CONTACT POINTS IN PCDA(O) :
        
        SAO(LW) TARUN KUMAR VERMA (020-26401236)
        AAO(LW) MUKESH KUMAR NAGAR (020-26401236)
        SAO(TW) SAMADHAN CHINTAMAN BIRARE (020-26401311)
        AAO(TW) DEEPAK MALIK (020-26401328)
        PRO CIVIL :((020) 2640- 1111/1333/1353/1356)
        PRO ARMY : (6512/6528/7761/7709)
        Visit us : https://pcdaopune.gov.in
        
        EMAIL US AT:
        
        For TA/DA related matter:
        tada-pcdaopune@nic.in
        For Ledger Section matter:
        ledger-pcdaopune@nic.in
        For rank pay related matter:
        rankpay-pcdaopune@nic.in
        For other grievances :
        generalquery-pcdaopune@nic.in
        """
        
        let contactInfo = extractor.extractContactInfo(from: testText)
        
        // Test that emails were extracted
        XCTAssertEqual(contactInfo.emails.count, 4)
        XCTAssertTrue(contactInfo.emails.contains("tada-pcdaopune@nic.in"))
        XCTAssertTrue(contactInfo.emails.contains("ledger-pcdaopune@nic.in"))
        XCTAssertTrue(contactInfo.emails.contains("rankpay-pcdaopune@nic.in"))
        XCTAssertTrue(contactInfo.emails.contains("generalquery-pcdaopune@nic.in"))
        
        // Test that phone numbers were extracted
        XCTAssertEqual(contactInfo.phoneNumbers.count, 4)
        XCTAssertTrue(contactInfo.phoneNumbers.contains("(020-26401236)"))
        XCTAssertTrue(contactInfo.phoneNumbers.contains("(020-26401311)"))
        XCTAssertTrue(contactInfo.phoneNumbers.contains("(020-26401328)"))
        XCTAssertTrue(contactInfo.phoneNumbers.contains("((020) 2640- 1111/1333/1353/1356)") || 
                      contactInfo.phoneNumbers.contains("(020) 2640- 1111/1333/1353/1356"))
        
        // Test that websites were extracted
        XCTAssertEqual(contactInfo.websites.count, 1)
        XCTAssertTrue(contactInfo.websites.contains("https://pcdaopune.gov.in"))
    }
    
    func testExtractContactSection() {
        let testText = """
        This is some random text before the contact section.
        
        CONTACT US
        
        This is the contact section with important information.
        Email: test@example.com
        Phone: (123) 456-7890
        Website: www.example.com
        
        This is some text after the contact section.
        """
        
        let contactInfo = extractor.extractContactInfo(from: testText)
        
        // Test that contact section was extracted correctly
        XCTAssertEqual(contactInfo.emails.count, 1)
        XCTAssertEqual(contactInfo.emails[0], "test@example.com")
        
        XCTAssertEqual(contactInfo.phoneNumbers.count, 1)
        XCTAssertEqual(contactInfo.phoneNumbers[0], "(123) 456-7890")
        
        XCTAssertEqual(contactInfo.websites.count, 1)
        XCTAssertEqual(contactInfo.websites[0], "www.example.com")
    }
    
    func testEmptyText() {
        let contactInfo = extractor.extractContactInfo(from: "")
        
        // Test that empty text results in empty contact info
        XCTAssertTrue(contactInfo.isEmpty)
        XCTAssertEqual(contactInfo.emails.count, 0)
        XCTAssertEqual(contactInfo.phoneNumbers.count, 0)
        XCTAssertEqual(contactInfo.websites.count, 0)
    }
    
    func testComplexPhoneNumbers() {
        let testText = """
        Phone numbers in different formats:
        Standard: (123) 456-7890
        Dashed: 123-456-7890
        International: +1-123-456-7890
        With Extension: (123) 456-7890 ext. 123
        Military: 6512/6528
        Military range: 6512/6528/7761/7709
        Office: (020-26401236)
        Parentheses: ((020) 2640- 1111/1333/1353/1356)
        """
        
        let contactInfo = extractor.extractContactInfo(from: testText)
        
        // Test that different phone formats were recognized
        XCTAssertTrue(contactInfo.phoneNumbers.count >= 5, "Expected at least 5 phone numbers, got \(contactInfo.phoneNumbers.count)")
        XCTAssertTrue(contactInfo.phoneNumbers.contains { $0.contains("(123) 456-7890") })
        XCTAssertTrue(contactInfo.phoneNumbers.contains { $0.contains("123-456-7890") })
        XCTAssertTrue(contactInfo.phoneNumbers.contains { $0.contains("6512/6528") })
        XCTAssertTrue(contactInfo.phoneNumbers.contains { $0.contains("(020-26401236)") })
    }
} 