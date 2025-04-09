import XCTest
import PDFKit
@testable import Payslip_Max

final class PayslipParserRegistryTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: StandardPayslipParserRegistry!
    var mockMilitaryParser: MockMilitaryPayslipParser!
    var mockCorporateParser: MockCorporatePayslipParser!
    var mockGenericParser: MockPayslipParser!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        sut = StandardPayslipParserRegistry()
        mockMilitaryParser = MockMilitaryPayslipParser()
        mockCorporateParser = MockCorporatePayslipParser()
        mockGenericParser = MockPayslipParser(name: "GenericParser")
    }
    
    override func tearDown() {
        sut = nil
        mockMilitaryParser = nil
        mockCorporateParser = nil
        mockGenericParser = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testInitialization() {
        XCTAssertEqual(sut.parsers.count, 0, "Registry should start empty")
    }
    
    func testRegisterParser() {
        // Register a parser
        sut.register(parser: mockGenericParser)
        
        // Verify parser was registered
        XCTAssertEqual(sut.parsers.count, 1, "Registry should have one parser")
        XCTAssertEqual(sut.parsers[0].name, "GenericParser", "Registered parser should match")
    }
    
    func testRegisterMultipleParsers() {
        // Register multiple parsers
        sut.register(parsers: [mockGenericParser, mockMilitaryParser, mockCorporateParser])
        
        // Verify parsers were registered
        XCTAssertEqual(sut.parsers.count, 3, "Registry should have three parsers")
        
        // Verify parser names
        let parserNames = sut.parsers.map { $0.name }
        XCTAssertTrue(parserNames.contains("GenericParser"), "Registry should contain generic parser")
        XCTAssertTrue(parserNames.contains("MockMilitaryParser"), "Registry should contain military parser")
        XCTAssertTrue(parserNames.contains("MockCorporateParser"), "Registry should contain corporate parser")
    }
    
    func testReplaceExistingParser() {
        // Register a parser
        sut.register(parser: mockGenericParser)
        
        // Register another parser with the same name
        let replacementParser = MockPayslipParser(name: "GenericParser", confidenceToReturn: .high)
        sut.register(parser: replacementParser)
        
        // Verify only one parser exists and it's the replacement
        XCTAssertEqual(sut.parsers.count, 1, "Registry should still have one parser")
        
        // Get the parser and check it's the replacement (by checking its confidence behavior)
        let parser = sut.parsers[0] as! MockPayslipParser
        XCTAssertEqual(parser.evaluateConfidence(for: PayslipItem()), .high, "Registry should contain the replacement parser")
    }
    
    func testRemoveParser() {
        // Register parsers
        sut.register(parsers: [mockGenericParser, mockMilitaryParser])
        XCTAssertEqual(sut.parsers.count, 2, "Registry should have two parsers")
        
        // Remove a parser
        sut.removeParser(withName: "GenericParser")
        
        // Verify parser was removed
        XCTAssertEqual(sut.parsers.count, 1, "Registry should have one parser after removal")
        XCTAssertEqual(sut.parsers[0].name, "MockMilitaryParser", "Remaining parser should be the military parser")
    }
    
    func testRemoveNonExistentParser() {
        // Register a parser
        sut.register(parser: mockGenericParser)
        XCTAssertEqual(sut.parsers.count, 1, "Registry should have one parser")
        
        // Try to remove a parser that doesn't exist
        sut.removeParser(withName: "NonExistentParser")
        
        // Verify no parsers were removed
        XCTAssertEqual(sut.parsers.count, 1, "Registry should still have one parser")
    }
    
    func testGetParserByName() {
        // Register parsers
        sut.register(parsers: [mockGenericParser, mockMilitaryParser])
        
        // Get a parser by name
        let parser = sut.getParser(withName: "GenericParser")
        
        // Verify correct parser was returned
        XCTAssertNotNil(parser, "Parser should be found")
        XCTAssertEqual(parser?.name, "GenericParser", "Correct parser should be returned")
    }
    
    func testGetNonExistentParser() {
        // Register a parser
        sut.register(parser: mockGenericParser)
        
        // Try to get a parser that doesn't exist
        let parser = sut.getParser(withName: "NonExistentParser")
        
        // Verify nil was returned
        XCTAssertNil(parser, "Non-existent parser should return nil")
    }
    
    func testSelectBestParserForMilitaryFormat() {
        // Register parsers
        sut.register(parsers: [mockGenericParser, mockMilitaryParser, mockCorporateParser])
        
        // Create military format text
        let militaryText = "PCDA Military Payslip\nMINISTRY OF DEFENCE\nARMY NO: 123456\nDSOP FUND: 5000"
        
        // Select best parser
        let bestParser = sut.selectBestParser(for: militaryText)
        
        // Verify military parser was selected
        XCTAssertNotNil(bestParser, "Best parser should be found")
        XCTAssertEqual(bestParser?.name, "MockMilitaryParser", "Military parser should be selected for military format")
    }
    
    func testSelectBestParserForCorporateFormat() {
        // Register parsers
        sut.register(parsers: [mockGenericParser, mockMilitaryParser, mockCorporateParser])
        
        // Create corporate format text
        let corporateText = "SALARY SLIP\nEmployee ID: 12345\nEmployee Name: John Doe\nGross Salary: 50000\nDeductions: 10000\nNet Pay: 40000"
        
        // Select best parser
        let bestParser = sut.selectBestParser(for: corporateText)
        
        // Verify corporate parser was selected
        XCTAssertNotNil(bestParser, "Best parser should be found")
        XCTAssertEqual(bestParser?.name, "MockCorporateParser", "Corporate parser should be selected for corporate format")
    }
    
    func testSelectBestParserWithNoFormat() {
        // Register parsers
        sut.register(parsers: [mockGenericParser, mockMilitaryParser, mockCorporateParser])
        
        // Create generic text with no clear format
        let genericText = "Some generic text with no clear format indicators"
        
        // Select best parser
        let bestParser = sut.selectBestParser(for: genericText)
        
        // Verify a parser was selected (should be first parser as fallback)
        XCTAssertNotNil(bestParser, "A parser should be selected as fallback")
    }
    
    func testSelectBestParserWithEmptyRegistry() {
        // Don't register any parsers
        
        // Try to select a parser
        let bestParser = sut.selectBestParser(for: "Some text")
        
        // Verify no parser was selected
        XCTAssertNil(bestParser, "No parser should be selected from empty registry")
    }
}

// MARK: - Mock Classes

class MockPayslipParser: PayslipParser {
    let name: String
    let confidenceToReturn: ParsingConfidence
    var parsePayslipCalled = false
    var evaluateConfidenceCalled = false
    
    init(name: String, confidenceToReturn: ParsingConfidence = .medium) {
        self.name = name
        self.confidenceToReturn = confidenceToReturn
    }
    
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        parsePayslipCalled = true
        return PayslipItem()
    }
    
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        evaluateConfidenceCalled = true
        return confidenceToReturn
    }
}

class MockMilitaryPayslipParser: MockPayslipParser, MilitaryPayslipParser {
    let abbreviationManager = MockAbbreviationManager()
    var canHandleMilitaryFormatCalled = false
    var extractMilitaryDetailsCalled = false
    var parseMilitaryAbbreviationsCalled = false
    
    init() {
        super.init(name: "MockMilitaryParser")
    }
    
    func canHandleMilitaryFormat(text: String) -> Bool {
        canHandleMilitaryFormatCalled = true
        return text.contains("MINISTRY OF DEFENCE") || 
               text.contains("ARMY") || 
               text.contains("PCDA") ||
               text.contains("DSOP FUND")
    }
    
    func extractMilitaryDetails(from text: String) -> [String : String] {
        extractMilitaryDetailsCalled = true
        return ["name": "Military Person", "rank": "Captain"]
    }
    
    func parseMilitaryAbbreviations(in text: String) -> [String : String] {
        parseMilitaryAbbreviationsCalled = true
        return ["DSOP": "Defence Services Officers Provident"]
    }
}

class MockCorporatePayslipParser: MockPayslipParser, CorporatePayslipParser {
    var canHandleCorporateFormatCalled = false
    var extractEmployeeDetailsCalled = false
    var extractCompanyDetailsCalled = false
    var extractTaxInformationCalled = false
    
    init() {
        super.init(name: "MockCorporateParser")
    }
    
    func canHandleCorporateFormat(text: String) -> Bool {
        canHandleCorporateFormatCalled = true
        return text.contains("SALARY SLIP") ||
               text.contains("Employee ID") ||
               text.contains("Gross Salary") ||
               text.contains("Net Pay")
    }
    
    func extractEmployeeDetails(from text: String) -> [String : String] {
        extractEmployeeDetailsCalled = true
        return ["name": "Corporate Employee", "id": "12345"]
    }
    
    func extractCompanyDetails(from text: String) -> [String : String] {
        extractCompanyDetailsCalled = true
        return ["company": "Corp Ltd", "department": "IT"]
    }
    
    func extractTaxInformation(from text: String) -> [String : Double] {
        extractTaxInformationCalled = true
        return ["tax": 5000.0, "cess": 200.0]
    }
} 