//
//  EnhancedRH12Detector.swift
//  PayslipMax
//
//  Created for Phase 4: Enhanced dual-section RH12 detection
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Enhanced RH12 detection service for dual-section component identification
/// Addresses Phase 4 requirement to find both earnings and deductions RH12 instances
final class EnhancedRH12Detector {

    // MARK: - Public Interface

    /// Detects all RH12 instances in the payslip text using enhanced pattern matching
    /// This addresses Phase 4 requirement to find both earnings and deductions RH12 instances
    /// - Parameters:
    ///   - text: The payslip text to search
    ///   - statedDeductionsTotal: Optional stated total deductions for validation
    ///   - knownDeductions: Optional array of known deduction values for cross-validation
    /// - Returns: Array of tuples containing (value, context) for each RH12 instance found
    func detectAllRH12Instances(in text: String, statedDeductionsTotal: Double? = nil, knownDeductions: [Double] = []) -> [(value: Double, context: String)] {
        var instances: [(value: Double, context: String)] = []
        var foundValues: Set<Double> = []

        // Enhanced RH12 detection patterns - more comprehensive than single legacy pattern
        let rhPatterns = [
            "RH12[\\s]*:?[\\s]*₹?([0-9,]+(?:\\.[0-9]+)?)",
            "RH12[\\s]*₹?([0-9,]+(?:\\.[0-9]+)?)",
            "RH12[\\s]+([0-9,]+(?:\\.[0-9]+)?)",
            "Risk[\\s]+Hardship[\\s]*₹?([0-9,]+(?:\\.[0-9]+)?)",  // More specific Risk Hardship pattern
            "Risk.*Hardship.*₹?([0-9,]+(?:\\.[0-9]+)?)",
            "R\\s*H\\s*1\\s*2.*?₹?([0-9,]+(?:\\.[0-9]+)?)"
        ]

        for pattern in rhPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let nsText = text as NSString
                let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

                for result in results {
                    if result.numberOfRanges > 1 {
                        let amountRange = result.range(at: 1)
                        if amountRange.location != NSNotFound {
                            // Check for invalid characters immediately before the number
                            let precedingCharIndex = amountRange.location - 1
                            var hasInvalidPrecedingChar = false
                            if precedingCharIndex >= 0 && precedingCharIndex < nsText.length {
                                let precedingChar = nsText.character(at: precedingCharIndex)
                                if precedingChar == 45 { // ASCII for '-'
                                    hasInvalidPrecedingChar = true
                                }
                            }

                            if !hasInvalidPrecedingChar {
                                let amountString = nsText.substring(with: amountRange)
                                if let value = parseAmount(amountString), isValidAmount(value) {
                                    // Use exact match for duplicate detection (no tolerance for different values)
                                    if !foundValues.contains(value) {
                                        foundValues.insert(value)

                                        // Extract context around the match (800 chars window to ensure section headers)
                                        let contextStart = max(0, result.range.location - 400)
                                        let contextLength = min(800, nsText.length - contextStart)
                                        let contextRange = NSRange(location: contextStart, length: contextLength)
                                        let context = nsText.substring(with: contextRange)

                                        instances.append((value: value, context: context))
                                        print("[EnhancedRH12Detector] Enhanced RH12 pattern found: ₹\(value)")
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("[EnhancedRH12Detector] RH12 pattern error: \(error)")
            }
        }

        // Apply cross-validation to prevent false positives
        let validatedInstances = validateAgainstTotals(instances, statedDeductionsTotal: statedDeductionsTotal, knownDeductions: knownDeductions)

        print("[EnhancedRH12Detector] Enhanced RH12 detection found \(validatedInstances.count) validated instances (filtered from \(instances.count))")
        return validatedInstances
    }

    // MARK: - Private Helper Methods

    /// Parses amount string to double value (helper for RH12 detection)
    private func parseAmount(_ amountString: String) -> Double? {
        let cleanAmount = amountString
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanAmount)
    }

    /// Validates if the detected amount is reasonable for RH12 component
    /// Filters out invalid amounts like 0, negative values, or unrealistic amounts
    private func isValidAmount(_ value: Double) -> Bool {
        // RH12 amounts should be positive and within reasonable military allowance range
        // Based on analysis: RH12 typically ranges from ₹500 to ₹50,000
        return value > 0 && value >= 500 && value <= 50000
    }

    /// Validates detected RH12 instances against known totals to prevent false positives
    /// - Parameters:
    ///   - instances: Detected RH12 instances with context
    ///   - statedDeductionsTotal: The stated total deductions from the payslip
    ///   - knownDeductions: Array of known deduction values for cross-validation
    /// - Returns: Filtered instances that don't cause total discrepancies
    private func validateAgainstTotals(_ instances: [(value: Double, context: String)], statedDeductionsTotal: Double?, knownDeductions: [Double]) -> [(value: Double, context: String)] {
        guard let statedTotal = statedDeductionsTotal, !instances.isEmpty else {
            // If no stated total provided or no instances, return all (no filtering)
            return instances
        }

        // Separate instances into earnings and deductions based on context analysis
        var earningsRH12: [Double] = []
        var deductionsRH12: [Double] = []

        for instance in instances {
            let context = instance.context.lowercased()
            let value = instance.value

            // Determine if this RH12 is in earnings or deductions section based on context
            let isInEarningsSection = context.contains("earning") || context.contains("credit") || context.contains("जमा")
            let isInDeductionsSection = context.contains("deduction") || context.contains("debit") || context.contains("नामे")

            if isInEarningsSection && !isInDeductionsSection {
                earningsRH12.append(value)
            } else if isInDeductionsSection && !isInEarningsSection {
                deductionsRH12.append(value)
            } else {
                // Ambiguous context - check value-based heuristics
                // High values (> ₹15,000) typically earnings, low values (< ₹10,000) typically deductions
                if value > 15000 {
                    earningsRH12.append(value)
                } else if value < 10000 {
                    deductionsRH12.append(value)
                } else {
                    // Mid-range values - keep as deductions (safer assumption)
                    deductionsRH12.append(value)
                }
            }
        }

        // Calculate expected total deductions if we include all detected RH12 deductions
        let knownDeductionsSum = knownDeductions.reduce(0, +)
        let rh12DeductionsSum = deductionsRH12.reduce(0, +)
        let expectedTotalDeductions = knownDeductionsSum + rh12DeductionsSum

        // If including all RH12 deductions would exceed stated total by more than 5%, filter out suspicious values
        let tolerance = 0.05 // 5% tolerance for rounding/minor discrepancies
        let maxAllowedTotal = statedTotal * (1 + tolerance)

        if expectedTotalDeductions > maxAllowedTotal {
            // Too many RH12 deductions detected - filter out the most suspicious ones
            let excess = expectedTotalDeductions - statedTotal
            print("[EnhancedRH12Detector] RH12 deductions total (₹\(rh12DeductionsSum)) exceeds stated total by ₹\(excess) - filtering suspicious values")

            // Sort RH12 deductions by suspiciousness (mid-range values are most suspicious)
            let sortedDeductions = deductionsRH12.sorted { (a, b) -> Bool in
                // Prefer to keep values that are clearly earnings (>15k) or clearly deductions (<10k)
                let aScore = abs(a - 12500) // Distance from midpoint (12,500)
                let bScore = abs(b - 12500)
                return aScore > bScore // Keep values further from midpoint
            }

            // Keep only the most confident deductions (remove mid-range suspicious values)
            let filteredDeductions = sortedDeductions.filter { value in
                // Keep values clearly in deduction range or if we have few detections
                value < 10000 || deductionsRH12.count <= 1
            }

            // Recalculate with filtered deductions
            let filteredRH12Sum = filteredDeductions.reduce(0, +)
            let newExpectedTotal = knownDeductionsSum + filteredRH12Sum

            if newExpectedTotal <= maxAllowedTotal {
                print("[EnhancedRH12Detector] Filtered RH12 deductions from \(deductionsRH12.count) to \(filteredDeductions.count) instances")
                deductionsRH12 = filteredDeductions
            } else {
                // Still too high - keep only the single most confident deduction
                let mostConfident = sortedDeductions.first(where: { $0 < 10000 }) ?? sortedDeductions.first
                deductionsRH12 = mostConfident != nil ? [mostConfident!] : []
                print("[EnhancedRH12Detector] Kept only most confident RH12 deduction: ₹\(mostConfident ?? 0)")
            }
        }

        // Reconstruct validated instances from filtered earnings and deductions
        var validatedInstances: [(value: Double, context: String)] = []

        for instance in instances {
            let value = instance.value
            if earningsRH12.contains(value) || deductionsRH12.contains(value) {
                validatedInstances.append(instance)
            }
        }

        return validatedInstances
    }
}
