//
//  MockPayslipProcessor.swift
//  PayslipMaxTests
//
//  Mock implementation of PayslipProcessorProtocol
//

import Foundation
@testable import PayslipMax

class MockPayslipProcessor: PayslipProcessorProtocol {
    var handlesFormat: PayslipFormat = .defense
    var resultToReturn: PayslipItem?
    var errorToThrow: Error?
    var processCalled = false

    func processPayslip(from text: String) async throws -> PayslipItem {
        processCalled = true
        if let error = errorToThrow { throw error }
        return resultToReturn ?? PayslipItem(month: "JAN", year: 2025)
    }

    func canProcess(text: String) -> Double { return 1.0 }
}
