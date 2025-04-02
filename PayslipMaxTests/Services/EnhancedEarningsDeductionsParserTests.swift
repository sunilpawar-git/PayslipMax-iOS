import XCTest
@testable import Payslip_Max

final class EnhancedEarningsDeductionsParserTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: EnhancedEarningsDeductionsParser!
    var mockAbbreviationManager: MockAbbreviationManager!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        mockAbbreviationManager = MockAbbreviationManager()
        sut = EnhancedEarningsDeductionsParser(abbreviationManager: mockAbbreviationManager)
    }
    
    override func tearDown() {
        sut = nil
        mockAbbreviationManager = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testExtractEarningsDeductions_StandardFormat() {
        // Given: A sample payslip text with standard format
        let payslipText = """
        EARNINGS
        Description Amount
        BPAY 30000
        DA 15000
        MSP 5000
        HRA 7000
        Gross Pay 57000
        
        DEDUCTIONS
        Description Amount
        DSOP 5000
        AGIF 1000
        ITAX 10000
        CGHS 2000
        Total Deductions 18000
        """
        
        // When: We extract earnings and deductions from this text
        let result = sut.extractEarningsDeductions(from: payslipText)
        
        // Then: The standard fields should be correctly extracted
        XCTAssertEqual(result.bpay, 30000)
        XCTAssertEqual(result.da, 15000)
        XCTAssertEqual(result.msp, 5000)
        XCTAssertEqual(result.knownEarnings["HRA"], 7000)
        XCTAssertEqual(result.grossPay, 57000)
        
        XCTAssertEqual(result.dsop, 5000)
        XCTAssertEqual(result.agif, 1000)
        XCTAssertEqual(result.itax, 10000)
        XCTAssertEqual(result.knownDeductions["CGHS"], 2000)
        XCTAssertEqual(result.totalDeductions, 18000)
        
        // Verify raw data is captured
        XCTAssertEqual(result.rawEarnings.count, 4)
        XCTAssertEqual(result.rawDeductions.count, 4)
    }
    
    func testExtractEarningsDeductions_NoStandardFields() {
        // Given: A sample payslip text with no standard fields
        let payslipText = """
        EARNINGS
        Description Amount
        ALLOWANCE1 10000
        ALLOWANCE2 15000
        BONUS 5000
        Gross Pay 30000
        
        DEDUCTIONS
        Description Amount
        DEDUCTION1 3000
        DEDUCTION2 2000
        LOAN 5000
        Total Deductions 10000
        """
        
        // When: We extract earnings and deductions from this text
        let result = sut.extractEarningsDeductions(from: payslipText)
        
        // Then: The values should be classified as either known or miscellaneous
        // Standard fields should be zero
        XCTAssertEqual(result.bpay, 0)
        XCTAssertEqual(result.da, 0)
        XCTAssertEqual(result.msp, 0)
        XCTAssertEqual(result.dsop, 0)
        XCTAssertEqual(result.agif, 0)
        XCTAssertEqual(result.itax, 0)
        
        // Check overall totals are correct
        XCTAssertEqual(result.grossPay, 30000)
        XCTAssertEqual(result.totalDeductions, 10000)
        
        // Check that the raw data was captured
        XCTAssertEqual(result.rawEarnings.count, 3)
        XCTAssertEqual(result.rawDeductions.count, 3)
    }
    
    func testExtractEarningsDeductions_MissingTotals() {
        // Given: A sample payslip text with missing total fields
        let payslipText = """
        EARNINGS
        Description Amount
        BPAY 30000
        DA 15000
        MSP 5000
        
        DEDUCTIONS
        Description Amount
        DSOP 5000
        AGIF 1000
        ITAX 10000
        """
        
        // When: We extract earnings and deductions from this text
        let result = sut.extractEarningsDeductions(from: payslipText)
        
        // Then: The standard fields should be correctly extracted
        // And the total fields should be zero
        XCTAssertEqual(result.bpay, 30000)
        XCTAssertEqual(result.da, 15000)
        XCTAssertEqual(result.msp, 5000)
        XCTAssertEqual(result.grossPay, 0)
        
        XCTAssertEqual(result.dsop, 5000)
        XCTAssertEqual(result.agif, 1000)
        XCTAssertEqual(result.itax, 10000)
        XCTAssertEqual(result.totalDeductions, 0)
        
        // Verify raw data is captured
        XCTAssertEqual(result.rawEarnings.count, 3)
        XCTAssertEqual(result.rawDeductions.count, 3)
    }
    
    func testExtractEarningsDeductions_MixedCategories() {
        // Given: A sample payslip text with items in wrong categories
        let payslipText = """
        EARNINGS
        Description Amount
        BPAY 30000
        DA 15000
        DSOP 5000
        
        DEDUCTIONS
        Description Amount
        MSP 5000
        AGIF 1000
        ITAX 10000
        """
        
        // When: We extract earnings and deductions from this text
        let result = sut.extractEarningsDeductions(from: payslipText)
        
        // Then: Items should be classified by their known type, not by section
        XCTAssertEqual(result.bpay, 30000)
        XCTAssertEqual(result.da, 15000)
        XCTAssertEqual(result.msp, 5000)
        XCTAssertEqual(result.dsop, 5000)
        XCTAssertEqual(result.agif, 1000)
        XCTAssertEqual(result.itax, 10000)
        
        // Verify raw data is captured
        XCTAssertEqual(result.rawEarnings.count, 3)
        XCTAssertEqual(result.rawDeductions.count, 3)
    }
    
    func testExtractEarningsDeductions_UnknownAbbreviations() {
        // Given: A sample payslip text with unknown abbreviations
        let payslipText = """
        EARNINGS
        Description Amount
        BPAY 30000
        UNKNOWN1 5000
        UNKNOWN2 3000
        
        DEDUCTIONS
        Description Amount
        DSOP 5000
        UNKNOWN3 2000
        UNKNOWN4 1000
        """
        
        // When: We extract earnings and deductions from this text
        let result = sut.extractEarningsDeductions(from: payslipText)
        
        // Then: Unknown items should be added to miscCredits and miscDebits
        XCTAssertEqual(result.bpay, 30000)
        XCTAssertEqual(result.dsop, 5000)
        XCTAssertEqual(result.miscCredits, 8000)  // UNKNOWN1 (5000) + UNKNOWN2 (3000)
        XCTAssertEqual(result.miscDebits, 3000)   // UNKNOWN3 (2000) + UNKNOWN4 (1000)
        
        // Verify raw data is captured
        XCTAssertEqual(result.rawEarnings.count, 3)
        XCTAssertEqual(result.rawDeductions.count, 3)
        
        // Verify unknown items are tracked
        XCTAssertEqual(result.unknownEarnings.count, 2)
        XCTAssertEqual(result.unknownDeductions.count, 2)
    }
    
    func testGetLearningSystem() {
        // Test that we can get the learning system
        let learningSystem = sut.getLearningSystem()
        XCTAssertNotNil(learningSystem)
    }
} 