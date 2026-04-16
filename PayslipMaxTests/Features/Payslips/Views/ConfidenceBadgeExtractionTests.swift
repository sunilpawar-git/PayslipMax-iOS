import XCTest
import SwiftUI
@testable import PayslipMax

final class ConfidenceBadgeExtractionTests: XCTestCase {

    func testExtractConfidenceFromPayslipItemMetadata() {
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "Aug",
            year: 2025,
            credits: 275015,
            debits: 102029,
            dsop: 21705,
            tax: 75219,
            earnings: ["Basic Pay": 144700],
            deductions: ["DSOP": 21705],
            name: "Test User",
            pdfData: Data(),
            source: "SimplifiedParser_v1.0",
            metadata: [
                "parsingConfidence": "0.95",
                "parserVersion": "1.0"
            ]
        )

        guard let confidenceStr = payslip.metadata["parsingConfidence"],
              let confidence = Double(confidenceStr) else {
            XCTFail("Should be able to extract confidence from metadata")
            return
        }

        XCTAssertEqual(confidence, 0.95, accuracy: 0.01)
    }

    func testExtractConfidenceFromPayslipDTO() {
        let dto = PayslipDTO(
            id: UUID(),
            timestamp: Date(),
            month: "Aug",
            year: 2025,
            credits: 275015,
            debits: 102029,
            dsop: 21705,
            tax: 75219,
            earnings: ["Basic Pay": 144700],
            deductions: ["DSOP": 21705],
            name: "Test User",
            accountNumber: "",
            panNumber: "",
            isNameEncrypted: false,
            isAccountNumberEncrypted: false,
            isPanNumberEncrypted: false,
            encryptionVersion: 1,
            isSample: false,
            source: "SimplifiedParser_v1.0",
            status: "Processed",
            notes: nil,
            numberOfPages: 1,
            metadata: [
                "parsingConfidence": "0.88",
                "parserVersion": "1.0"
            ]
        )

        guard let confidenceStr = dto.metadata["parsingConfidence"],
              let confidence = Double(confidenceStr) else {
            XCTFail("Should be able to extract confidence from DTO metadata")
            return
        }

        XCTAssertEqual(confidence, 0.88, accuracy: 0.01)
    }

    func testHandleMissingConfidenceMetadata() {
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "Jul",
            year: 2025,
            credits: 200000,
            debits: 50000,
            dsop: 20000,
            tax: 30000,
            earnings: [:],
            deductions: [:],
            name: "Legacy User",
            pdfData: Data(),
            source: "LegacyParser",
            metadata: [:]
        )

        let confidence = payslip.metadata["parsingConfidence"]
        XCTAssertNil(confidence, "Legacy payslips should have nil confidence")
    }

    func testInvalidConfidenceFormat() {
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "Aug",
            year: 2025,
            credits: 275015,
            debits: 102029,
            dsop: 21705,
            tax: 75219,
            earnings: [:],
            deductions: [:],
            name: "Test User",
            pdfData: Data(),
            source: "SimplifiedParser_v1.0",
            metadata: [
                "parsingConfidence": "invalid"
            ]
        )

        let confidenceStr = payslip.metadata["parsingConfidence"]
        XCTAssertNotNil(confidenceStr, "Confidence string should exist")

        let confidence = Double(confidenceStr ?? "")
        XCTAssertNil(confidence, "Invalid confidence string should return nil when parsed")
    }
}
