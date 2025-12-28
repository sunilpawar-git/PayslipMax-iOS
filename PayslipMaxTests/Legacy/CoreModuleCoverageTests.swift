import XCTest
import Foundation
@testable import PayslipMax

/// Strategic tests targeting Core module for maximum coverage impact
/// Core module: 71 files, currently ~1% covered - critical infrastructure
final class CoreModuleCoverageTests: XCTestCase {

    // MARK: - Error Types Coverage

    func testPDFProcessingError_ComprehensiveCoverage() {
        let errorCases: [(PDFProcessingError, String)] = [
            (.fileAccessError("access denied"), "access"),
            (.invalidPDFData, "invalid"),
            (.emptyDocument, "empty"),
            (.passwordProtected, "password"),
            (.incorrectPassword, "incorrect"),
            (.invalidFormat, "valid"),
            (.unsupportedFormat, "supported"),
            (.extractionFailed("extraction failed"), "extract"),
            (.parsingFailed("test failure"), "parse"),
            (.processingTimeout, "timeout"),
            (.conversionFailed, "convert"),
            (.unableToProcessPDF, "unable"),
            (.invalidData, "invalid"),
            (.invalidPDFStructure, "valid"),
            (.textExtractionFailed, "extract"),
            (.notAPayslip, "payslip"),
            (.processingFailed, "failed")
        ]

        for (error, expectedSubstring) in errorCases {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Error \(error) should have description")
            XCTAssertTrue(
                description.lowercased().contains(expectedSubstring.lowercased()),
                "Error \(error) description should contain '\(expectedSubstring)'"
            )

            if let errorDescription = error.errorDescription {
                XCTAssertFalse(errorDescription.isEmpty)
            }

            let sameError: PDFProcessingError
            switch error {
            case .parsingFailed:
                sameError = .parsingFailed("test failure")
            case .extractionFailed:
                sameError = .extractionFailed("extraction failed")
            case .fileAccessError:
                sameError = .fileAccessError("access denied")
            default:
                sameError = error
            }
            XCTAssertEqual(error.localizedDescription, sameError.localizedDescription)
        }
    }

    func testMockError_ComprehensiveCoverage() {
        let mockErrors: [MockError] = [
            .initializationFailed, .encryptionFailed, .decryptionFailed,
            .authenticationFailed, .saveFailed, .fetchFailed, .deleteFailed,
            .clearAllDataFailed, .unlockFailed, .setupPINFailed, .verifyPINFailed,
            .clearFailed, .processingFailed, .incorrectPassword, .extractionFailed
        ]

        for error in mockErrors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
            XCTAssertNotNil(error.localizedDescription)
        }
    }

    // MARK: - Data Models Coverage

    func testPayslipContentValidationResult_AllProperties() {
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

    // MARK: - Protocol Conformance Testing

    func testPayslipDataProtocol_Conformance() {
        let payslip = PayslipItem(
            month: "Protocol Test", year: 2023, credits: 6000.0, debits: 1200.0,
            dsop: 300.0, tax: 900.0, name: "Protocol User",
            accountNumber: "PROT1234", panNumber: "PROT5678"
        )

        let protocolPayslip: any PayslipDataProtocol = payslip
        XCTAssertNotNil(protocolPayslip)
        XCTAssertEqual(protocolPayslip.month, "Protocol Test")
        XCTAssertEqual(protocolPayslip.year, 2023)
        XCTAssertEqual(protocolPayslip.credits, 6000.0)
        XCTAssertEqual(protocolPayslip.debits, 1200.0)
        XCTAssertEqual(protocolPayslip.dsop, 300.0)
        XCTAssertEqual(protocolPayslip.tax, 900.0)

        let netAmount = protocolPayslip.calculateNetAmount()
        XCTAssertEqual(netAmount, 4800.0)

        let unifiedNetAmount = protocolPayslip.calculateNetAmountUnified()
        XCTAssertEqual(unifiedNetAmount, 4800.0)

        let validationIssues = protocolPayslip.validateFinancialConsistency()
        XCTAssertNotNil(validationIssues)
    }
}
