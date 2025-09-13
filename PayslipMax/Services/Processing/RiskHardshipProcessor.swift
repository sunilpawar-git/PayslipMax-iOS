//
//  RiskHardshipProcessor.swift
//  PayslipMax
//
//  Created for dual-section RH component processing
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Service for processing Risk and Hardship allowance components
/// Handles dual-section RH codes (RH11-RH33) that can appear in both earnings and deductions
final class RiskHardshipProcessor {

    // MARK: - Properties

    /// Section classifier for dual-section component detection
    private let sectionClassifier = PayslipSectionClassifier()

    // MARK: - Public Interface

    /// Processes RH components and stores them in appropriate sections
    /// - Parameters:
    ///   - key: The extracted key containing RH code
    ///   - value: The extracted monetary value
    ///   - text: The full payslip text for context analysis
    ///   - earnings: Mutable earnings dictionary to update
    ///   - deductions: Mutable deductions dictionary to update
    func processRiskHardshipComponent(
        key: String,
        value: Double,
        text: String,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        guard isRiskHardshipCode(key) else {
            print("[RiskHardshipProcessor] Warning: '\(key)' is not a valid RH code")
            return
        }

        // All RH codes can appear in both earnings and deductions - use section context
        let sectionType = sectionClassifier.classifyRH12Section(key: key, value: value, text: text)

        if sectionType == .earnings {
            // Accumulate earnings RH12 values (handle multiple instances)
            let currentEarnings = earnings["RH12_EARNINGS"] ?? 0.0
            earnings["RH12_EARNINGS"] = currentEarnings + value
            print("[RiskHardshipProcessor] RH12 classified as EARNINGS: ₹\(value)")
        } else if sectionType == .deductions {
            // Accumulate deductions RH12 values (handle multiple instances)
            let currentDeductions = deductions["RH12_DEDUCTIONS"] ?? 0.0
            deductions["RH12_DEDUCTIONS"] = currentDeductions + value
            print("[RiskHardshipProcessor] RH12 classified as DEDUCTIONS: ₹\(value)")
        }
    }

    /// Checks if the given key represents a Risk and Hardship allowance code
    /// Supports all RH codes: RH11, RH12, RH13, RH21, RH22, RH23, RH31, RH32, RH33
    /// - Parameter key: The extracted component key
    /// - Returns: True if the key represents any RH allowance code
    func isRiskHardshipCode(_ key: String) -> Bool {
        let rhCodes = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]
        let uppercaseKey = key.uppercased()

        return rhCodes.contains { rhCode in
            uppercaseKey.contains(rhCode)
        }
    }
}
