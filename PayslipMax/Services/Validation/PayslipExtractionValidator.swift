//
//  PayslipExtractionValidator.swift
//  PayslipMax
//
//  Created for enhanced payslip data extraction validation
//  Ensures accuracy and prevents false positives in military payslip parsing
//

import Foundation
// swiftlint:disable no_hardcoded_strings
/// Protocol defining payslip extraction validation capabilities
protocol PayslipExtractionValidatorProtocol {
    func validateExtraction(
        earnings: [String: Double],
        deductions: [String: Double],
        statedTotals: (credits: Double, debits: Double)
    ) -> ExtractionValidationResult
    func validateIndividualComponents(
        earnings: [String: Double],
        deductions: [String: Double]
    ) -> [ExtractionValidationWarning]
    func calculateConfidenceScore(for extraction: ExtractionData) -> Double
}

/// Comprehensive validator for payslip extraction results
/// Implements SOLID principles with single responsibility for validation
class PayslipExtractionValidator: PayslipExtractionValidatorProtocol {

    private let dynamicPatternService: DynamicMilitaryPatternService

    init(dynamicPatternService: DynamicMilitaryPatternService = DynamicMilitaryPatternService()) {
        self.dynamicPatternService = dynamicPatternService
    }

    // MARK: - Public Methods

    /// Validates complete extraction results with comprehensive checks
    func validateExtraction(
        earnings: [String: Double],
        deductions: [String: Double],
        statedTotals: (credits: Double, debits: Double)
    ) -> ExtractionValidationResult {

        var warnings: [ExtractionValidationWarning] = []
        var correctedEarnings = earnings
        var correctedDeductions = deductions

        // 1. Validate individual components
        let componentWarnings = validateIndividualComponents(earnings: earnings, deductions: deductions)
        warnings.append(contentsOf: componentWarnings)

        // 2. Validate totals against stated amounts
        let totalWarnings = validateTotals(earnings: earnings, deductions: deductions, statedTotals: statedTotals)
        warnings.append(contentsOf: totalWarnings)

        // 3. Apply corrections based on warnings
        let corrections = applyCorrections(earnings: earnings, deductions: deductions, warnings: warnings)
        correctedEarnings = corrections.earnings
        correctedDeductions = corrections.deductions

        // 4. Calculate confidence score
        let extractionData = ExtractionData(
            earnings: correctedEarnings,
            deductions: correctedDeductions,
            statedCredits: statedTotals.credits,
            statedDebits: statedTotals.debits,
            payslipType: "military"
        )
        let confidenceScore = calculateConfidenceScore(for: extractionData)

        // 5. Generate validation summary
        let summary = generateSummary(
            originalEarnings: earnings,
            originalDeductions: deductions,
            correctedEarnings: correctedEarnings,
            correctedDeductions: correctedDeductions,
            statedTotals: statedTotals
        )

        // 6. Determine overall validity
        let isValid = confidenceScore >= ValidationThresholds.minConfidenceForAcceptance &&
            summary.totalVariancePercent <= ValidationThresholds.maxVariancePercent

        return ExtractionValidationResult(
            isValid: isValid,
            confidenceScore: confidenceScore,
            warnings: warnings,
            correctedEarnings: correctedEarnings,
            correctedDeductions: correctedDeductions,
            summary: summary
        )
    }

    /// Validates individual earnings and deduction components
    func validateIndividualComponents(
        earnings: [String: Double],
        deductions: [String: Double]
    ) -> [ExtractionValidationWarning] {
        var warnings: [ExtractionValidationWarning] = []

        // Dynamic validation using military pay structure
        if let basicPay = earnings["Basic Pay"] {
            let validation = dynamicPatternService.validateBasicPay(basicPay)
            if !validation.isValid {
                let severity: ValidationSeverity = validation.message.contains("doesn't match") ? .high : .medium
                warnings.append(ExtractionValidationWarning(
                    component: "Basic Pay",
                    issue: .unrealisticAmount,
                    severity: severity,
                    message: validation.message,
                    suggestedValue: nil
                ))
            }

            // Validate allowances against basic pay using dynamic service
            for (component, amount) in earnings where component != "Basic Pay" {
                let allowanceValidation = dynamicPatternService.validateAllowance(
                    component,
                    amount: amount,
                    basicPay: basicPay,
                    level: nil
                )
                if !allowanceValidation.isValid {
                    let severity: ValidationSeverity = allowanceValidation.message.contains("significantly") ? .high : .medium
                    warnings.append(ExtractionValidationWarning(
                        component: component,
                        issue: component.contains("HRA") ? .falsePositive : .unrealisticAmount,
                        severity: severity,
                        message: allowanceValidation.message,
                        suggestedValue: nil
                    ))
                }
            }
        } else {
            warnings.append(ExtractionValidationWarning(
                component: "Basic Pay",
                issue: .missingComponent,
                severity: .critical,
                message: "Basic Pay not detected - this is essential for military payslips",
                suggestedValue: nil
            ))
        }

        return warnings
    }

    /// Calculates confidence score for extraction accuracy
    func calculateConfidenceScore(for extraction: ExtractionData) -> Double {
        var score: Double = 1.0

        // Factor 1: Total variance (40% weight)
        if extraction.statedCredits > 0 {
            let extractedCredits = extraction.earnings.values.reduce(0, +)
            let creditsVariance = abs(extractedCredits - extraction.statedCredits) / extraction.statedCredits
            score -= creditsVariance * 0.4
        }

        if extraction.statedDebits > 0 {
            let extractedDebits = extraction.deductions.values.reduce(0, +)
            let debitsVariance = abs(extractedDebits - extraction.statedDebits) / extraction.statedDebits
            score -= debitsVariance * 0.3
        }

        // Factor 2: Component presence (20% weight)
        let expectedComponents = ["Basic Pay", "Dearness Allowance", "Military Service Pay"]
        let detectedComponents = expectedComponents.filter { extraction.earnings.keys.contains($0) }
        let componentScore = Double(detectedComponents.count) / Double(expectedComponents.count)
        score = score * 0.8 + componentScore * 0.2

        // Factor 3: Realistic values (10% weight)
        if let basicPay = extraction.earnings["Basic Pay"] {
            if basicPay >= ValidationThresholds.minBasicPayForMilitary &&
               basicPay <= ValidationThresholds.maxBasicPayForMilitary {
                score += 0.1
            }
        }

        return max(0.0, min(1.0, score))
    }

    // MARK: - Private Helper Methods

    private func validateTotals(
        earnings: [String: Double],
        deductions: [String: Double],
        statedTotals: (credits: Double, debits: Double)
    ) -> [ExtractionValidationWarning] {
        var warnings: [ExtractionValidationWarning] = []

        let extractedCredits = earnings.values.reduce(0, +)
        let extractedDebits = deductions.values.reduce(0, +)

        if statedTotals.credits > 0 {
            let variance = abs(extractedCredits - statedTotals.credits) / statedTotals.credits * 100
            if variance > ValidationThresholds.maxVariancePercent {
                warnings.append(ExtractionValidationWarning(
                    component: "Total Credits",
                    issue: .totalMismatch,
                    severity: .high,
                    message: "Extracted credits (\(extractedCredits)) differ significantly from stated total (\(statedTotals.credits))",
                    suggestedValue: statedTotals.credits
                ))
            }
        }

        if statedTotals.debits > 0 {
            let variance = abs(extractedDebits - statedTotals.debits) / statedTotals.debits * 100
            if variance > ValidationThresholds.maxVariancePercent {
                warnings.append(ExtractionValidationWarning(
                    component: "Total Deductions",
                    issue: .totalMismatch,
                    severity: .high,
                    message: "Extracted deductions (\(extractedDebits)) differ significantly from stated total (\(statedTotals.debits))",
                    suggestedValue: statedTotals.debits
                ))
            }
        }

        return warnings
    }

    private func applyCorrections(
        earnings: [String: Double],
        deductions: [String: Double],
        warnings: [ExtractionValidationWarning]
    ) -> (earnings: [String: Double], deductions: [String: Double]) {
        var correctedEarnings = earnings
        let correctedDeductions = deductions

        for warning in warnings {
            if warning.severity == .critical && warning.issue == .falsePositive {
                if warning.component == "House Rent Allowance" {
                    correctedEarnings.removeValue(forKey: "House Rent Allowance")
                    print("[PayslipExtractionValidator] Removed false positive HRA")
                }
            }
        }

        return (correctedEarnings, correctedDeductions)
    }

    private func generateSummary(
        originalEarnings: [String: Double],
        originalDeductions: [String: Double],
        correctedEarnings: [String: Double],
        correctedDeductions: [String: Double],
        statedTotals: (credits: Double, debits: Double)
    ) -> ValidationSummary {

        let _ = originalEarnings.values.reduce(0, +)
        let correctedCredits = correctedEarnings.values.reduce(0, +)
        let correctedDebits = correctedDeductions.values.reduce(0, +)

        let totalVariance = statedTotals.credits > 0 ?
            abs(correctedCredits - statedTotals.credits) / statedTotals.credits * 100 : 0.0

        let earningsAccuracy = statedTotals.credits > 0 ?
            max(0, 1.0 - abs(correctedCredits - statedTotals.credits) / statedTotals.credits) : 1.0

        let deductionsAccuracy = statedTotals.debits > 0 ?
            max(0, 1.0 - abs(correctedDebits - statedTotals.debits) / statedTotals.debits) : 1.0

        return ValidationSummary(
            totalVariancePercent: totalVariance,
            earningsAccuracy: earningsAccuracy,
            deductionsAccuracy: deductionsAccuracy,
            componentsDetected: originalEarnings.count + originalDeductions.count,
            componentsValidated: correctedEarnings.count + correctedDeductions.count
        )
    }
}
// swiftlint:enable no_hardcoded_strings
