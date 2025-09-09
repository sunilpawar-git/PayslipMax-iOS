//
//  PDFValidationService.swift
//  PayslipMaxTests
//
//  Created by PayslipMax
//  Copyright © 2024 PayslipMax. All rights reserved.
//

import Foundation
@testable import PayslipMax

/// Protocol for PDF validation services
protocol PDFValidationServiceProtocol {
    /// Validates PDF data for basic integrity
    func validatePDFData(_ data: Data) -> ValidationResult
}

/// Service responsible for validating PDF data integrity
class PDFValidationService: PDFValidationServiceProtocol {

    // MARK: - PDFValidationServiceProtocol Implementation

    func validatePDFData(_ data: Data) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Check if data is empty
        if data.isEmpty {
            errors.append(ValidationError(field: "pdfData", message: "PDF data cannot be empty", severity: .error))
            return .failure(errors: errors)
        }

        // Check minimum size (PDF header is typically small)
        if data.count < 100 {
            warnings.append(ValidationWarning(field: "pdfData", message: "PDF data is unusually small"))
        }

        // Check for PDF header
        let headerBytes = data.prefix(8)
        let headerString = String(data: headerBytes, encoding: .ascii) ?? ""

        if !headerString.hasPrefix("%PDF-") {
            errors.append(ValidationError(field: "pdfData", message: "Data does not appear to be a valid PDF", severity: .error))
        }

        // Check for PDF trailer
        let trailerString = String(data: data.suffix(1024), encoding: .ascii) ?? ""
        if !trailerString.contains("%%EOF") {
            errors.append(ValidationError(field: "pdfData", message: "PDF data is missing EOF marker", severity: .error))
        }

        if errors.isEmpty {
            return warnings.isEmpty ? .success() : .successWithWarnings(warnings: warnings)
        } else {
            return .failure(errors: errors)
        }
    }
}
