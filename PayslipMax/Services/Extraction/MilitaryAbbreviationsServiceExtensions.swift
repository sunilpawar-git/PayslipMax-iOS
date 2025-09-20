//
//  MilitaryAbbreviationsServiceExtensions.swift
//  PayslipMax
//
//  Created for Phase 6: Performance Optimization
//  Extensions to MilitaryAbbreviationsService for component classification
//

import Foundation

// MARK: - Extensions

/// Extension to MilitaryAbbreviationsService for component classification
extension MilitaryAbbreviationsService {
    /// Classifies a component using the comprehensive military abbreviations database
    /// - Parameter component: The pay component code to classify
    /// - Returns: PayslipSection (.earnings or .deductions) or nil if unknown
    func classifyComponent(_ component: String) -> PayslipSection? {
        let normalizedComponent = component.uppercased().trimmingCharacters(in: .whitespaces)

        // Handle arrears patterns (ARR-CODE)
        let cleanComponent = normalizedComponent.hasPrefix("ARR-")
            ? String(normalizedComponent.dropFirst(4))
            : normalizedComponent

        // First try exact match lookup
        if let abbreviation = abbreviation(forCode: cleanComponent) {
            return (abbreviation.isCredit ?? true) ? .earnings : .deductions
        }

        // Try partial matching for complex codes (e.g., "RH12" should match codes containing "RH")
        let creditCodes = creditAbbreviations.map { $0.code.uppercased() }
        let debitCodes = debitAbbreviations.map { $0.code.uppercased() }

        // Check if component contains any known credit code
        for creditCode in creditCodes {
            if cleanComponent.contains(creditCode) || creditCode.contains(cleanComponent) {
                return .earnings
            }
        }

        // Check if component contains any known debit code
        for debitCode in debitCodes {
            if cleanComponent.contains(debitCode) || debitCode.contains(cleanComponent) {
                return .deductions
            }
        }

        // Fallback: Check for common military allowance patterns that are typically earnings
        // Only match complete words or clear abbreviations to avoid false positives
        let allowancePatterns = ["RH", "MSP", "DA", "TPTA", "CEA", "CLA", "HRA", "BPAY", "BP"]
        for pattern in allowancePatterns {
            // Use word boundaries to avoid partial matches like "UNKNOWN" containing "WN"
            if cleanComponent.range(of: "\\b\(pattern)\\b", options: .regularExpression) != nil {
                return .earnings
            }
        }

        // Fallback: Check for common deduction patterns
        let deductionPatterns = ["DSOP", "AGIF", "AFPF", "ITAX", "IT", "EHCESS", "GPF", "PF"]
        for pattern in deductionPatterns {
            // Use word boundaries to avoid partial matches
            if cleanComponent.range(of: "\\b\(pattern)\\b", options: .regularExpression) != nil {
                return .deductions
            }
        }

        return nil // Unknown classification
    }
}
