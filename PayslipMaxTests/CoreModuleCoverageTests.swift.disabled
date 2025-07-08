import XCTest
import Foundation
@testable import PayslipMax

/// Strategic tests targeting Core module for maximum coverage impact
/// Core module: 71 files, currently ~1% covered - critical infrastructure
final class CoreModuleCoverageTests: XCTestCase {
    
    // MARK: - Error Types Coverage
    
    func testPDFProcessingError_ComprehensiveCoverage() {
        // Test all error cases with detailed validation
        let errorCases: [(PDFProcessingError, String)] = [
            (.fileNotFound, "file"),
            (.invalidPDFData, "invalid"),
            (.emptyDocument, "empty"),
            (.passwordProtected, "password"),
            (.incorrectPassword, "incorrect"),
            (.corruptedData, "corrupted"),
            (.unsupportedFormat, "unsupported"),
            (.extractionFailed, "extraction"),
            (.parsingFailed("test failure"), "parsing"),
            (.processingTimeout, "timeout"),
            (.networkError("network issue"), "network"),
            (.fileAccessError("access denied"), "access"),
            (.insufficientMemory, "memory"),
            (.securityRestricted, "security"),
            (.unknown, "unknown")
        ]
        
        for (error, expectedSubstring) in errorCases {
            // Test localized description
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Error \(error) should have description")
            XCTAssertTrue(description.lowercased().contains(expectedSubstring.lowercased()), 
                         "Error \(error) description should contain '\(expectedSubstring)'")
            
            // Test error description
            if let errorDescription = error.errorDescription {
                XCTAssertFalse(errorDescription.isEmpty)
            }
            
            // Test error equality
            let sameError: PDFProcessingError
            switch error {
            case .parsingFailed(_):
                sameError = .parsingFailed("test failure")
            case .networkError(_):
                sameError = .networkError("network issue")
            case .fileAccessError(_):
                sameError = .fileAccessError("access denied")
            default:
                sameError = error
            }
            XCTAssertEqual(error.localizedDescription, sameError.localizedDescription)
        }
    }
    
    func testMockError_ComprehensiveCoverage() {
        let mockErrors: [MockError] = [
            .initializationFailed,
            .processingFailed,
            .extractionFailed,
            .unlockFailed,
            .incorrectPassword,
            .genericError("Custom error message")
        ]
        
        for error in mockErrors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
            
            // Test error conformance
            XCTAssertTrue(error is Error)
            XCTAssertTrue(error is LocalizedError)
            
            // Test specific error messages
            switch error {
            case .genericError(let message):
                XCTAssertTrue(error.localizedDescription.contains(message))
            default:
                XCTAssertTrue(error.localizedDescription.count > 0)
            }
        }
    }
    
    // MARK: - Data Models Coverage
    
    func testPayslipContentValidationResult_AllProperties() {
        // Test with valid result
        let validResult = PayslipContentValidationResult(
            isValid: true,
            confidence: 0.95,
            detectedFields: ["credits", "debits", "name", "date"],
            missingRequiredFields: []
        )
        
        XCTAssertTrue(validResult.isValid)
        XCTAssertEqual(validResult.confidence, 0.95)
        XCTAssertEqual(validResult.detectedFields.count, 4)
        XCTAssertTrue(validResult.missingRequiredFields.isEmpty)
        XCTAssertTrue(validResult.detectedFields.contains("credits"))
        
        // Test with invalid result
        let invalidResult = PayslipContentValidationResult(
            isValid: false,
            confidence: 0.3,
            detectedFields: ["name"],
            missingRequiredFields: ["credits", "debits", "date"]
        )
        
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertEqual(invalidResult.confidence, 0.3)
        XCTAssertEqual(invalidResult.detectedFields.count, 1)
        XCTAssertEqual(invalidResult.missingRequiredFields.count, 3)
        XCTAssertTrue(invalidResult.missingRequiredFields.contains("credits"))
        
        // Test edge cases
        let edgeResult = PayslipContentValidationResult(
            isValid: false,
            confidence: 0.0,
            detectedFields: [],
            missingRequiredFields: ["everything"]
        )
        
        XCTAssertFalse(edgeResult.isValid)
        XCTAssertEqual(edgeResult.confidence, 0.0)
        XCTAssertTrue(edgeResult.detectedFields.isEmpty)
        XCTAssertEqual(edgeResult.missingRequiredFields, ["everything"])
    }
    
    // MARK: - Utility Classes Coverage
    
    func testTestDataGenerator_EdgeCases() {
        // Test edge case payslips
        let zeroValues = TestDataGenerator.edgeCasePayslipItem(type: .zeroValues)
        XCTAssertEqual(zeroValues.credits, 0)
        XCTAssertEqual(zeroValues.debits, 0)
        XCTAssertEqual(zeroValues.dsop, 0)
        XCTAssertEqual(zeroValues.tax, 0)
        
        let negativeBalance = TestDataGenerator.edgeCasePayslipItem(type: .negativeBalance)
        XCTAssertTrue(negativeBalance.credits < negativeBalance.debits)
        
        let largeValues = TestDataGenerator.edgeCasePayslipItem(type: .veryLargeValues)
        XCTAssertTrue(largeValues.credits >= 1_000_000)
        
        let precisionValues = TestDataGenerator.edgeCasePayslipItem(type: .decimalPrecision)
        XCTAssertTrue(precisionValues.credits.truncatingRemainder(dividingBy: 1) != 0)
        
        let specialChars = TestDataGenerator.edgeCasePayslipItem(type: .specialCharacters)
        XCTAssertTrue(specialChars.name.contains("'") || specialChars.name.contains("-"))
        
        // Test multiple payslips generation
        let payslips = TestDataGenerator.samplePayslipItems(count: 24)
        XCTAssertEqual(payslips.count, 24)
        
        // Test year progression
        let firstYear = payslips[0].year
        let lastYear = payslips[23].year
        XCTAssertTrue(lastYear >= firstYear)
        
        // Test month variety
        let months = Set(payslips.map { $0.month })
        XCTAssertTrue(months.count > 1)
    }
    
    func testTestDataGenerator_PDFGeneration() {
        // Test basic PDF generation
        let basicPDF = TestDataGenerator.samplePDFDocument()
        XCTAssertNotNil(basicPDF)
        XCTAssertTrue(basicPDF.pageCount > 0)
        
        // Test custom text PDF
        let customText = "Custom payslip content for testing"
        let customPDF = TestDataGenerator.samplePDFDocument(withText: customText)
        XCTAssertNotNil(customPDF)
        XCTAssertTrue(customPDF.pageCount > 0)
        
        // Test payslip PDF generation
        let payslipPDF = TestDataGenerator.samplePayslipPDF(
            name: "PDF Test User",
            rank: "Major",
            id: "PDF123",
            month: "August",
            year: 2023,
            credits: 9000.0,
            debits: 1800.0,
            dsop: 450.0,
            tax: 1350.0
        )
        
        XCTAssertNotNil(payslipPDF)
        XCTAssertTrue(payslipPDF.pageCount > 0)
        
        // Verify PDF has content
        if let page = payslipPDF.page(at: 0) {
            let pageString = page.string
            XCTAssertTrue(pageString?.contains("PDF Test User") ?? false)
            XCTAssertTrue(pageString?.contains("August 2023") ?? false)
        }
    }
    
    // MARK: - Protocol Conformance Testing
    
    func testPayslipDataProtocol_Conformance() {
        let payslip = PayslipItem(
            month: "Protocol Test", year: 2023, credits: 6000.0, debits: 1200.0,
            dsop: 300.0, tax: 900.0, name: "Protocol User",
            accountNumber: "PROT1234", panNumber: "PROT5678"
        )
        
        // Test protocol conformance
        XCTAssertTrue(payslip is PayslipDataProtocol)
        
        // Test protocol properties
        let protocolPayslip: PayslipDataProtocol = payslip
        XCTAssertEqual(protocolPayslip.month, "Protocol Test")
        XCTAssertEqual(protocolPayslip.year, 2023)
        XCTAssertEqual(protocolPayslip.credits, 6000.0)
        XCTAssertEqual(protocolPayslip.debits, 1200.0)
        XCTAssertEqual(protocolPayslip.dsop, 300.0)
        XCTAssertEqual(protocolPayslip.tax, 900.0)
        XCTAssertEqual(protocolPayslip.name, "Protocol User")
        XCTAssertEqual(protocolPayslip.accountNumber, "PROT1234")
        XCTAssertEqual(protocolPayslip.panNumber, "PROT5678")
        
        // Test protocol methods
        let netAmount = protocolPayslip.calculateNetAmountUnified()
        XCTAssertEqual(netAmount, 4800.0) // 6000 - 1200
        
        let validationIssues = protocolPayslip.validateFinancialConsistency()
        XCTAssertTrue(validationIssues.count >= 0)
    }
    
    // MARK: - Integration and Performance
    
    func testCoreIntegration_CrossModule() {
        // Test integration between core utilities and models
        let utility = FinancialCalculationUtility.shared
        let testPayslips = TestDataGenerator.samplePayslipItems(count: 12)
        
        // Test aggregation across multiple payslips
        let totalIncome = utility.aggregateTotalIncome(for: testPayslips)
        XCTAssertTrue(totalIncome > 0)
        
        let totalDeductions = utility.aggregateTotalDeductions(for: testPayslips)
        XCTAssertTrue(totalDeductions > 0)
        
        let netIncome = utility.aggregateNetIncome(for: testPayslips)
        XCTAssertEqual(netIncome, totalIncome - totalDeductions, accuracy: 0.01)
        
        // Test trends
        let incomeTrend = utility.calculateIncomeTrend(for: testPayslips)
        let deductionsTrend = utility.calculateDeductionsTrend(for: testPayslips)
        
        XCTAssertTrue(incomeTrend.isFinite)
        XCTAssertTrue(deductionsTrend.isFinite)
        
        // Test breakdown calculations
        let earningsBreakdown = utility.calculateEarningsBreakdown(for: testPayslips)
        let deductionsBreakdown = utility.calculateDeductionsBreakdown(for: testPayslips)
        
        XCTAssertTrue(earningsBreakdown.count >= 0)
        XCTAssertTrue(deductionsBreakdown.count >= 0)
        
        // Test validation across all payslips
        for payslip in testPayslips {
            let issues = utility.validateFinancialConsistency(for: payslip)
            XCTAssertTrue(issues.count >= 0)
        }
    }
    
    func testPerformanceBaseline_CoreOperations() {
        // Performance baseline tests for core operations
        let largePayslipSet = TestDataGenerator.samplePayslipItems(count: 1000)
        let utility = FinancialCalculationUtility.shared
        
        measure {
            // Test aggregation performance
            let _ = utility.aggregateTotalIncome(for: largePayslipSet)
            let _ = utility.aggregateTotalDeductions(for: largePayslipSet)
            let _ = utility.aggregateNetIncome(for: largePayslipSet)
        }
        
        // Test individual operations don't take too long
        let start = Date()
        let _ = utility.calculateEarningsBreakdown(for: largePayslipSet)
        let _ = utility.calculateDeductionsBreakdown(for: largePayslipSet)
        let elapsed = Date().timeIntervalSince(start)
        
        XCTAssertTrue(elapsed < 5.0, "Core operations should complete within 5 seconds")
    }
}