//
//  WarningGenerationService.swift
//  PayslipMaxTests
//
//  Created by PayslipMax
//  Copyright © 2024 PayslipMax. All rights reserved.
//

import Foundation
@testable import PayslipMax

/// Protocol for warning generation services
protocol WarningGenerationServiceProtocol {
    /// Generates warnings for payslip data
    func generateWarnings(for payslip: PayslipItem) -> [ValidationWarning]
}

/// Service responsible for generating validation warnings
class WarningGenerationService: WarningGenerationServiceProtocol {

    // MARK: - WarningGenerationServiceProtocol Implementation

    func generateWarnings(for payslip: PayslipItem) -> [ValidationWarning] {
        var warnings: [ValidationWarning] = []

        // Warn about special characters in names
        if payslip.name.contains(where: { !$0.isLetter && !$0.isWhitespace && !$0.isPunctuation }) {
            warnings.append(ValidationWarning(field: "name", message: "Name contains special characters"))
        }

        return warnings
    }
}
