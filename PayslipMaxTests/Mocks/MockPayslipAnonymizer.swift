//
//  MockPayslipAnonymizer.swift
//  PayslipMaxTests
//
//  Mock implementation of PayslipAnonymizerProtocol for testing
//

import Foundation
@testable import PayslipMax

class MockPayslipAnonymizer: PayslipAnonymizerProtocol {
    var lastRedactionCount: Int = 0
    var shouldFail: Bool = false

    func anonymize(_ text: String) throws -> String {
        if shouldFail {
            throw AnonymizationError.noTextProvided
        }
        return "Anonymized: " + text
    }

    func validate(_ text: String) -> Bool {
        return true
    }
}
