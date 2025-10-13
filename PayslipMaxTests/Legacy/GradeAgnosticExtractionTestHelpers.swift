//
//  GradeAgnosticExtractionTestHelpers.swift
//  PayslipMaxTests
//
//  Helper methods and utilities for GradeAgnosticExtractionTests
//

import Foundation
import XCTest

/// Helper utilities for grade-agnostic extraction tests
struct GradeAgnosticExtractionTestHelpers {

    /// Validates that expected financial components are extracted correctly
    static func validateFinancialExtraction(result: [String: Double],
                                          expectedBasicPay: Double,
                                          expectedDA: Double? = nil,
                                          expectedMSP: Double? = nil,
                                          expectedRH12: Double? = nil,
                                          expectedTPTA: Double? = nil,
                                          testDescription: String = "") {

        XCTAssertEqual(result["BasicPay"], expectedBasicPay,
                      "Should extract BasicPay \(expectedBasicPay)\(testDescription)")

        if let da = expectedDA {
            XCTAssertEqual(result["DA"], da,
                          "Should extract DA \(da)\(testDescription)")
        }

        if let msp = expectedMSP {
            XCTAssertEqual(result["MSP"], msp,
                          "Should extract MSP \(msp)\(testDescription)")
        }

        if let rh12 = expectedRH12 {
            XCTAssertEqual(result["RH12"], rh12,
                          "Should extract RH12 \(rh12)\(testDescription)")
        }

        if let tpta = expectedTPTA {
            XCTAssertEqual(result["TPTA"], tpta,
                          "Should extract TPTA \(tpta)\(testDescription)")
        }
    }

    /// Validates that key components exist in extraction result
    static func validateKeyComponentsExist(result: [String: Double],
                                         components: [String],
                                         testDescription: String = "") {
        for component in components {
            XCTAssertNotNil(result[component],
                           "Should extract \(component)\(testDescription)")
        }
    }

    /// Gets grade inference method through reflection (for testing purposes)
    static func getGradeInferenceMethod() -> ((Double) -> String?)? {
        // Use reflection to access private method for testing
        // This is a simplified approach - in practice, you might expose this for testing
        return nil
    }

    /// Creates test payslip text with earnings and deductions sections
    static func createComprehensivePayslipText(basicPay: Double,
                                             daAmount: Double,
                                             gradeLevel: String? = nil,
                                             includeGradeInBPAY: Bool = false) -> String {
        let gradeText = includeGradeInBPAY && gradeLevel != nil ? " (\(gradeLevel!))" : ""
        let msp = 15500.0
        let rh12 = 21125.0
        let tpta = 3600.0
        let tptada = 1908.0
        let dsop = 40000.0
        let agif = 10000.0

        return """
        Principal Controller of Defence Accounts (Officers), Pune
        STATEMENT OF ACCOUNT

        आय/EARNINGS (₹)                    कटौती/DEDUCTIONS (₹)
        Description     Amount             Description     Amount
        BPAY\(gradeText)           \(Int(basicPay))             DSOP           \(Int(dsop))
        DA             \(Int(daAmount))              AGIF           \(Int(agif))
        MSP            \(Int(msp))              ITAX           57028
        RH12           \(Int(rh12))              EHCESS         2282
        TPTA           \(Int(tpta))
        TPTADA         \(Int(tptada))

        कुल आय         \(Int(basicPay + daAmount + msp + rh12 + tpta + tptada))            कुल कटौती       \(Int(dsop + agif + 57028 + 2282))
        Gross Pay                        Total Deductions
        """
    }
}
