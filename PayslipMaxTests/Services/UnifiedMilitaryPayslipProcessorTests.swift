import XCTest
@testable import PayslipMax

/// Tests for the UnifiedMilitaryPayslipProcessor
final class UnifiedMilitaryPayslipProcessorTests: XCTestCase {
    
    var processor: UnifiedMilitaryPayslipProcessor!
    var mockPatternMatchingService: PatternMatchingService!
    
    override func setUp() {
        super.setUp()
        mockPatternMatchingService = PatternMatchingService()
        processor = UnifiedMilitaryPayslipProcessor(patternMatchingService: mockPatternMatchingService)
    }
    
    override func tearDown() {
        processor = nil
        mockPatternMatchingService = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testProcessorHandlesFormat() {
        // Test that the processor handles military format
        XCTAssertEqual(processor.handlesFormat, PayslipFormat.military)
    }
    
    func testCanProcessMilitaryPayslip() {
        // Test confidence scoring for military payslips
        let militaryText = """
        MINISTRY OF DEFENCE
        INDIAN ARMY
        STATEMENT OF ACCOUNT
        FOR THE MONTH OF APRIL 2025
        
        SERVICE NO & NAME: 1234567 CAPT JOHN DOE
        RANK: CAPTAIN
        UNIT: 1 GORKHA RIFLES
        
        EARNINGS:
        BASIC PAY: 56100.00
        MSP: 15500.00
        DA: 3366.00
        HRA: 8415.00
        
        DEDUCTIONS:
        DSOP: 5610.00
        ITAX: 12000.00
        AGIF: 300.00
        """
        
        let confidence = processor.canProcess(text: militaryText)
        XCTAssertGreaterThan(confidence, 0.8, "Should have high confidence for military payslip")
    }
    
    func testCanProcessPCDAPayslip() {
        // Test confidence scoring for PCDA payslips
        let pcdaText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        STATEMENT OF ACCOUNT FOR APRIL 2025
        
        DEFENCE ACCOUNTS DEPARTMENT
        PCDA PENSION MUMBAI
        
        SERVICE NO: 9876543
        NAME: MAJOR SMITH
        
        EARNINGS:
        BPAY: 67700.00
        MILITARY SERVICE PAY: 15500.00
        DEARNESS ALLOWANCE: 4062.00
        
        DEDUCTIONS:
        DSOP FUND: 6770.00
        INCOME TAX: 15000.00
        """
        
        let confidence = processor.canProcess(text: pcdaText)
        XCTAssertGreaterThan(confidence, 0.8, "Should have high confidence for PCDA payslip")
    }
    
    func testCanProcessNavyPayslip() {
        // Test confidence scoring for Navy payslips
        let navyText = """
        INDIAN NAVY
        NAVAL ACCOUNTS OFFICE
        MONTH: MAY 2025
        
        SERVICE NO: IN-12345
        RANK: LIEUTENANT
        NAME: OFFICER KUMAR
        
        BASIC PAY: 56100.00
        MSP: 15500.00
        DSOP: 5610.00
        """
        
        let confidence = processor.canProcess(text: navyText)
        XCTAssertGreaterThan(confidence, 0.7, "Should have good confidence for Navy payslip")
    }
    
    func testCanProcessAirForcePayslip() {
        // Test confidence scoring for Air Force payslips
        let airForceText = """
        INDIAN AIR FORCE
        AIR FORCE STATION
        PAYSLIP FOR APRIL 2025
        
        SERVICE NO: IAF789
        RANK: FLIGHT LIEUTENANT
        
        BASIC PAY: 56100.00
        MILITARY SERVICE PAY: 15500.00
        DSOP: 5610.00
        """
        
        let confidence = processor.canProcess(text: airForceText)
        XCTAssertGreaterThan(confidence, 0.7, "Should have good confidence for Air Force payslip")
    }
    
    func testRejectsNonMilitaryPayslip() {
        // Test that non-military payslips get low confidence
        let civilianText = """
        XYZ TECHNOLOGY LTD
        SALARY SLIP FOR APRIL 2025
        
        EMPLOYEE ID: EMP123
        DESIGNATION: SOFTWARE ENGINEER
        
        BASIC SALARY: 50000.00
        HRA: 20000.00
        PROVIDENT FUND: 6000.00
        TDS: 8000.00
        """
        
        let confidence = processor.canProcess(text: civilianText)
        XCTAssertLessThan(confidence, 0.3, "Should have low confidence for civilian payslip")
    }
    
    // MARK: - Processing Tests
    
    func testProcessMilitaryPayslipBasicExtraction() throws {
        // Test basic military payslip processing
        let militaryText = """
        INDIAN ARMY PAYSLIP
        FOR THE MONTH OF APRIL 2025
        
        SERVICE NO & NAME: 123456 CAPT JOHN DOE
        ACCOUNT NUMBER: 12345678901
        PAN: ABCDE1234F
        
        EARNINGS:
        BASIC PAY: 56100.00
        MSP: 15500.00
        DA: 3366.00
        HRA: 8415.00
        TOTAL EARNINGS: 83381.00
        
        DEDUCTIONS:
        DSOP: 5610.00
        ITAX: 12000.00
        AGIF: 300.00
        TOTAL DEDUCTIONS: 17910.00
        """
        
        let result = try processor.processPayslip(from: militaryText)
        
        // Test basic properties
        XCTAssertEqual(result.month, "April")
        XCTAssertEqual(result.year, 2025)
        XCTAssertEqual(result.name, "CAPT JOHN DOE")
        XCTAssertEqual(result.accountNumber, "12345678901")
        XCTAssertEqual(result.panNumber, "ABCDE1234F")
        
        // Test that military components are extracted
        XCTAssertTrue(result.earnings.count > 0, "Should extract earnings")
        XCTAssertTrue(result.deductions.count > 0, "Should extract deductions")
        
        // Test DSOP extraction (military-specific)
        XCTAssertGreaterThan(result.dsop, 0, "Should extract DSOP amount")
        
        print("✅ Extracted Earnings: \(result.earnings)")
        print("✅ Extracted Deductions: \(result.deductions)")
        print("✅ DSOP: ₹\(result.dsop)")
        print("✅ Credits: ₹\(result.credits)")
        print("✅ Debits: ₹\(result.debits)")
    }
    
    func testProcessPCDAPayslipBasicExtraction() throws {
        // Test PCDA payslip processing
        let pcdaText = """
        PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS
        STATEMENT OF ACCOUNT FOR MAY 2025
        
        NAME: MAJOR SMITH KUMAR
        ACCOUNT NO: 98765432101
        PAN: XYZ4567890
        
        BPAY: 67700.00
        MILITARY SERVICE PAY: 15500.00
        DEARNESS ALLOWANCE: 4062.00
        GROSS EARNINGS: 87262.00
        
        DSOP FUND: 6770.00
        INCOME TAX: 15000.00
        TOTAL DEDUCTIONS: 21770.00
        """
        
        let result = try processor.processPayslip(from: pcdaText)
        
        // Test basic properties
        XCTAssertEqual(result.month, "May")
        XCTAssertEqual(result.year, 2025)
        XCTAssertEqual(result.name, "MAJOR SMITH KUMAR")
        XCTAssertEqual(result.accountNumber, "98765432101")
        XCTAssertEqual(result.panNumber, "XYZ4567890")
        
        // Test military-specific extractions
        XCTAssertGreaterThan(result.dsop, 0, "Should extract DSOP amount")
        XCTAssertGreaterThan(result.tax, 0, "Should extract tax amount")
        
        print("✅ PCDA Earnings: \(result.earnings)")
        print("✅ PCDA Deductions: \(result.deductions)")
    }
    
    func testProcessPayslipWithInsufficientData() {
        // Test error handling for insufficient data
        let shortText = "Too short"
        
        XCTAssertThrowsError(try processor.processPayslip(from: shortText)) { error in
            XCTAssertEqual(error as? PayslipError, PayslipError.invalidData)
        }
    }
    
    func testProcessPayslipWithMissingDate() throws {
        // Test fallback date handling
        let textWithoutDate = """
        INDIAN ARMY
        SERVICE NO: 123456
        NAME: TEST OFFICER
        
        BASIC PAY: 50000.00
        DSOP: 5000.00
        """
        
        let result = try processor.processPayslip(from: textWithoutDate)
        
        // Should use current month/year as fallback
        XCTAssertFalse(result.month.isEmpty, "Should have fallback month")
        XCTAssertGreaterThan(result.year, 2020, "Should have valid fallback year")
    }
    
    // MARK: - Integration Tests
    
    func testMultipleFormatsConfidence() {
        // Test that processor consistently gives high confidence to military formats
        let testCases = [
            ("ARMY", "INDIAN ARMY\nBASIC PAY: 50000\nDSOP: 5000"),
            ("NAVY", "INDIAN NAVY\nMSP: 15000\nDSOP: 5000"),
            ("AIR FORCE", "INDIAN AIR FORCE\nMILITARY SERVICE PAY: 15000"),
            ("PCDA", "PCDA\nDEFENCE ACCOUNTS\nDSOP FUND: 5000"),
            ("MILITARY", "MILITARY SERVICE\nAGIF: 300\nDSOP: 5000")
        ]
        
        for (format, text) in testCases {
            let confidence = processor.canProcess(text: text)
            XCTAssertGreaterThan(confidence, 0.5, "Should have good confidence for \(format) format")
        }
    }
}
