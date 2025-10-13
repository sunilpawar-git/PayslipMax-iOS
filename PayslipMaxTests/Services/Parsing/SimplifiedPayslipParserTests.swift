import XCTest
@testable import PayslipMax

/// Tests for SimplifiedPayslipParser
/// Validates extraction of essential components from military payslips
final class SimplifiedPayslipParserTests: XCTestCase {
    
    var parser: SimplifiedPayslipParser!
    
    override func setUp() {
        super.setUp()
        parser = SimplifiedPayslipParser()
    }
    
    override func tearDown() {
        parser = nil
        super.tearDown()
    }
    
    // MARK: - August 2025 Sample Tests
    
    func testAugust2025SampleExtraction() async {
        // Sample text from attached screenshot
        let sampleText = """
        रक्षा लेखा प्रधान नियंत्रक अफसर पुणे
        Principal Controller of Defence Accounts (Officers),Pune
        Ministry of Defence, Government of India
        
        08/2025 की लेखा विवरणी / STATEMENT OF ACCOUNT FOR 08/2025
        
        नाम/Name: Sunil Suresh Pawar
        लेखा संख्या /A/C No: 16/111/206718K
        स्थायी खाता संख्या/PAN No: AR*****90G
        
        आय / EARNINGS (₹)           कटौती / DEDUCTIONS (₹)
        
        विवरण         राशि          विवरण         राशि
        Description    Amount        Description    Amount
        
        BPAY (12A)     144700        DSOP          40000
        DA              88110        AGIF          12500
        MSP             15500        ITAX          47624
        RH12            21125        EHCESS         1905
        TPTA             3600
        TPTADA           1980
        
        कुल आय         275015        कुल कटौती     102029
        Gross Pay                    Total Deductions
        
        अगली वेतन वृद्धि की तारीख / Next Increment Date:01/01/2026
        
        निवल प्रेषित धन/Net Remittance : Rs.1,72,986 (One Lakh Seventy Two Thousand Nine Hundred Eighty Six only)
        """
        
        let pdfData = Data()
        let payslip = await parser.parse(sampleText, pdfData: pdfData)
        
        // Test core earnings
        XCTAssertEqual(payslip.basicPay, 144700, accuracy: 1.0, "BPAY should be extracted correctly")
        XCTAssertEqual(payslip.dearnessAllowance, 88110, accuracy: 1.0, "DA should be extracted correctly")
        XCTAssertEqual(payslip.militaryServicePay, 15500, accuracy: 1.0, "MSP should be extracted correctly")
        XCTAssertEqual(payslip.grossPay, 275015, accuracy: 1.0, "Gross Pay should be extracted correctly")
        
        // Test core deductions
        XCTAssertEqual(payslip.dsop, 40000, accuracy: 1.0, "DSOP should be extracted correctly")
        XCTAssertEqual(payslip.agif, 12500, accuracy: 1.0, "AGIF should be extracted correctly")
        XCTAssertEqual(payslip.incomeTax, 47624, accuracy: 1.0, "Income Tax should be extracted correctly")
        XCTAssertEqual(payslip.totalDeductions, 102029, accuracy: 1.0, "Total Deductions should be extracted correctly")
        
        // Test calculated fields
        let expectedOtherEarnings = 275015.0 - (144700.0 + 88110.0 + 15500.0)
        XCTAssertEqual(payslip.otherEarnings, expectedOtherEarnings, accuracy: 1.0, "Other Earnings should be calculated correctly")
        
        let expectedOtherDeductions = 102029.0 - (40000.0 + 12500.0 + 47624.0)
        XCTAssertEqual(payslip.otherDeductions, expectedOtherDeductions, accuracy: 1.0, "Other Deductions should be calculated correctly")
        
        // Test net remittance
        XCTAssertEqual(payslip.netRemittance, 172986, accuracy: 1.0, "Net Remittance should be extracted correctly")
        
        // Test confidence score
        XCTAssertGreaterThan(payslip.parsingConfidence, 0.7, "Confidence should be > 70% for valid data")
    }
    
    // MARK: - Confidence Calculation Tests
    
    func testHighConfidenceForValidData() async {
        let validText = """
        BPAY 144700
        DA 88110
        MSP 15500
        Gross Pay 248310
        DSOP 40000
        AGIF 12500
        ITAX 47624
        Total Deductions 100124
        Net Remittance 148186
        """
        
        let pdfData = Data()
        let payslip = await parser.parse(validText, pdfData: pdfData)
        
        XCTAssertGreaterThan(payslip.parsingConfidence, 0.85, "Valid data should have high confidence")
    }
    
    func testLowConfidenceForMissingData() async {
        let incompleteText = """
        BPAY 144700
        Gross Pay 248310
        Total Deductions 100124
        """
        
        let pdfData = Data()
        let payslip = await parser.parse(incompleteText, pdfData: pdfData)
        
        XCTAssertLessThan(payslip.parsingConfidence, 0.6, "Missing core fields should lower confidence")
    }
    
    // MARK: - Edge Cases
    
    func testGradeSpecificBPAY() async {
        let text = """
        BPAY (12A) 144700
        """
        
        let pdfData = Data()
        let payslip = await parser.parse(text, pdfData: pdfData)
        
        XCTAssertEqual(payslip.basicPay, 144700, accuracy: 1.0, "Should extract BPAY with grade")
    }
    
    func testHindiLabels() async {
        let text = """
        BPAY 144700
        DA 88110
        कुल आय 232810
        कुल कटौती 80000
        निवल 152810
        """
        
        let pdfData = Data()
        let payslip = await parser.parse(text, pdfData: pdfData)
        
        XCTAssertEqual(payslip.grossPay, 232810, accuracy: 1.0, "Should extract Hindi 'Gross Pay'")
        XCTAssertEqual(payslip.totalDeductions, 80000, accuracy: 1.0, "Should extract Hindi 'Total Deductions'")
        XCTAssertEqual(payslip.netRemittance, 152810, accuracy: 1.0, "Should extract Hindi 'Net Remittance'")
    }
}

