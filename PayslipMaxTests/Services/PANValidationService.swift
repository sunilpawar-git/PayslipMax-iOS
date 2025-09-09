//
//  PANValidationService.swift
//  PayslipMaxTests
//
//  Created by PayslipMax
//  Copyright © 2024 PayslipMax. All rights reserved.
//

import Foundation
@testable import PayslipMax

/// Protocol for PAN validation services
protocol PANValidationServiceProtocol {
    /// Validates PAN format
    func isValidPANFormat(_ pan: String) -> Bool

    /// Generates warnings for PAN-related issues
    func generatePANWarnings(_ pan: String) -> [ValidationWarning]
}

/// Service responsible for validating PAN (Permanent Account Number) formats
class PANValidationService: PANValidationServiceProtocol {

    // MARK: - PANValidationServiceProtocol Implementation

    func isValidPANFormat(_ pan: String) -> Bool {
        // Basic PAN format validation (AAAAA9999A)
        let panRegex = "^[A-Z]{5}[0-9]{4}[A-Z]{1}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", panRegex)
        return predicate.evaluate(with: pan)
    }

    func generatePANWarnings(_ pan: String) -> [ValidationWarning] {
        var warnings: [ValidationWarning] = []

        if !isValidPANFormat(pan) {
            warnings.append(ValidationWarning(field: "panNumber", message: "PAN number format may be invalid"))
        }

        return warnings
    }
}
