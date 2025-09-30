//
//  PayslipDataSerializationTests.swift
//  PayslipMaxTests
//
//  Tests for JSON serialization and deserialization of PayslipData
//  Part of PayslipDataValidationTests refactoring for architectural compliance
//

import XCTest
@testable import PayslipMax

final class PayslipDataSerializationTests: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
    }

    override func tearDownWithError() throws {
        super.tearDown()
    }

    // MARK: - JSON Serialization/Deserialization Tests

    func testJSONSerializationWithDualSectionKeys() throws {
        // Test JSON compatibility with dual-section keys
        let originalPayslipData = PayslipDataTestHelpers.createPayslipDataWithDualSectionTotals()

        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalPayslipData)

        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedPayslipData = try decoder.decode(PayslipData.self, from: jsonData)

        // Verify dual-section keys are preserved
        XCTAssertEqual(decodedPayslipData.allEarnings["RH12_EARNINGS"], originalPayslipData.allEarnings["RH12_EARNINGS"],
                       "Dual-section earnings keys should survive JSON serialization")
        XCTAssertEqual(decodedPayslipData.allDeductions["RH12_DEDUCTIONS"], originalPayslipData.allDeductions["RH12_DEDUCTIONS"],
                       "Dual-section deductions keys should survive JSON serialization")

        // Verify computed properties work after deserialization
        XCTAssertEqual(decodedPayslipData.netIncome, originalPayslipData.netIncome,
                       "NetIncome should be consistent after JSON round-trip")
    }
}
