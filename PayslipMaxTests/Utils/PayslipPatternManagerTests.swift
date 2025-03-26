import XCTest
@testable import Payslip_Max

final class PayslipPatternManagerTests: XCTestCase {
    
    // MARK: - Test Data
    
    private let samplePayslipText = """
    Name: John Doe
    Account No: 1234567890
    PAN: ABCDE1234F
    Statement Period: January 2024
    Gross Pay: Rs. 50,000.00
    Total Deductions: Rs. 10,000.00
    Net Amount: Rs. 40,000.00
    
    Earnings:
    Basic Pay: Rs. 30,000.00
    DA: Rs. 15,000.00
    MSP: Rs. 5,000.00
    
    Deductions:
    DSOP: Rs. 5,000.00
    Income Tax: Rs. 8,000.00
    AGIF: Rs. 2,000.00
    """
    
    // MARK: - Tests
    
    func testExtractData() {
        // Given
        let text = samplePayslipText
        
        // When
        let extractedData = PayslipPatternManager.extractData(from: text)
        
        // Then
        XCTAssertEqual(extractedData["name"], "John Doe")
        XCTAssertEqual(extractedData["accountNumber"], "1234567890")
        XCTAssertEqual(extractedData["panNumber"], "ABCDE1234F")
        XCTAssertEqual(extractedData["month"], "January")
        XCTAssertEqual(extractedData["year"], "2024")
        XCTAssertEqual(extractedData["grossPay"], "50000.00")
        XCTAssertEqual(extractedData["totalDeductions"], "10000.00")
        XCTAssertEqual(extractedData["netRemittance"], "40000.00")
    }
    
    func testExtractTabularData() {
        // Given
        let text = samplePayslipText
        
        // When
        let (earnings, deductions) = PayslipPatternManager.extractTabularData(from: text)
        
        // Then
        XCTAssertEqual(earnings["BPAY"], 30000.00)
        XCTAssertEqual(earnings["DA"], 15000.00)
        XCTAssertEqual(earnings["MSP"], 5000.00)
        
        XCTAssertEqual(deductions["DSOP"], 5000.00)
        XCTAssertEqual(deductions["ITAX"], 8000.00)
        XCTAssertEqual(deductions["AGIF"], 2000.00)
    }
    
    func testExtractMonthAndYear() {
        // Given
        let text = "Statement Period: January 2024"
        
        // When
        let (month, year) = PayslipPatternManager.extractMonthAndYear(from: text)
        
        // Then
        XCTAssertEqual(month, "January")
        XCTAssertEqual(year, "2024")
    }
    
    func testExtractMonthAndYearWithDate() {
        // Given
        let text = "Pay Date: 15/01/2024"
        
        // When
        let (month, year) = PayslipPatternManager.extractMonthAndYear(from: text)
        
        // Then
        XCTAssertEqual(month, "January")
        XCTAssertEqual(year, "2024")
    }
    
    func testCleanNumericValue() {
        // Given
        let values = [
            "Rs. 1,234.56": "1234.56",
            "$1,234.56": "1234.56",
            "₹1,234.56": "1234.56",
            "(1,234.56)": "-1234.56",
            "1,234.56": "1234.56"
        ]
        
        // When/Then
        for (input, expected) in values {
            XCTAssertEqual(PayslipPatternManager.cleanNumericValue(input), expected)
        }
    }
    
    func testExtractNumericValue() {
        // Given
        let text = "Amount: Rs. 1,234.56"
        let pattern = "Amount:\\s*(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        
        // When
        let value = PayslipPatternManager.extractNumericValue(from: text, using: pattern)
        
        // Then
        XCTAssertEqual(value, 1234.56)
    }
    
    func testValidateFinancialData() {
        // Given
        let data: [String: Double] = [
            "valid": 1000.0,
            "tooSmall": 1.0,
            "tooLarge": 20_000_000.0
        ]
        
        // When
        let validated = PayslipPatternManager.validateFinancialData(data)
        
        // Then
        XCTAssertEqual(validated.count, 1)
        XCTAssertEqual(validated["valid"], 1000.0)
        XCTAssertNil(validated["tooSmall"])
        XCTAssertNil(validated["tooLarge"])
    }
    
    func testIsBlacklisted() {
        // Given
        let earningsContext = "earnings"
        let deductionsContext = "deductions"
        
        // When/Then
        XCTAssertTrue(PayslipPatternManager.isBlacklisted("STATEMENT", in: earningsContext))
        XCTAssertTrue(PayslipPatternManager.isBlacklisted("DSOP", in: earningsContext))
        XCTAssertTrue(PayslipPatternManager.isBlacklisted("BPAY", in: deductionsContext))
        XCTAssertFalse(PayslipPatternManager.isBlacklisted("BPAY", in: earningsContext))
        XCTAssertFalse(PayslipPatternManager.isBlacklisted("DSOP", in: deductionsContext))
    }
    
    func testExtractCleanCode() {
        // Given
        let codes = [
            "3600DSOP": ("DSOP", 3600.0),
            "ARR-RSHNA": ("ARR", 0.0),
            "BPAY": ("BPAY", nil)
        ]
        
        // When/Then
        for (input, expected) in codes {
            let result = PayslipPatternManager.extractCleanCode(from: input)
            XCTAssertEqual(result.cleanedCode, expected.0)
            XCTAssertEqual(result.extractedValue, expected.1)
        }
    }
    
    func testCreatePayslipItem() {
        // Given
        let extractedData: [String: String] = [
            "name": "John Doe",
            "accountNumber": "1234567890",
            "panNumber": "ABCDE1234F",
            "month": "January",
            "year": "2024"
        ]
        
        let earnings: [String: Double] = [
            "BPAY": 30000.00,
            "DA": 15000.00,
            "MSP": 5000.00
        ]
        
        let deductions: [String: Double] = [
            "DSOP": 5000.00,
            "ITAX": 8000.00,
            "AGIF": 2000.00
        ]
        
        // When
        let payslip = PayslipPatternManager.createPayslipItem(
            from: extractedData,
            earnings: earnings,
            deductions: deductions
        )
        
        // Then
        XCTAssertEqual(payslip.name, "John Doe")
        XCTAssertEqual(payslip.accountNumber, "1234567890")
        XCTAssertEqual(payslip.panNumber, "ABCDE1234F")
        XCTAssertEqual(payslip.month, "January")
        XCTAssertEqual(payslip.year, 2024)
        XCTAssertEqual(payslip.credits, 50000.00)
        XCTAssertEqual(payslip.debits, 15000.00)
        XCTAssertEqual(payslip.dsop, 5000.00)
        XCTAssertEqual(payslip.tax, 8000.00)
        XCTAssertEqual(payslip.earnings, earnings)
        XCTAssertEqual(payslip.deductions, deductions)
    }
} 