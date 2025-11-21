import Foundation

/// Protocol for validating mandatory payslip components
protocol MandatoryComponentValidator {
    func validateMandatoryEarnings(_ components: [PayComponent]) -> ComponentValidationResult
    func validateMandatoryDeductions(_ components: [PayComponent]) -> ComponentValidationResult
}

/// Default implementation of mandatory component validation
class DefaultMandatoryComponentValidator: MandatoryComponentValidator {

    func validateMandatoryEarnings(_ components: [PayComponent]) -> ComponentValidationResult {
        let earningsComponents = components.filter { $0.section == .earnings }
        var missing: [String] = []

        // Check for BPAY (any variant: BPAY, BPAY (1) through BPAY (16))
        let hasBPAY = earningsComponents.contains { component in
            let code = component.code.uppercased()
            return code.hasPrefix("BPAY") ||
                   code.contains("BASIC PAY") ||
                   code.contains("BASIC_PAY")
        }
        if !hasBPAY {
            missing.append("BPAY (Basic Pay)")
        }

        // Check for DA (Dearness Allowance)
        let hasDA = earningsComponents.contains { component in
            let code = component.code.uppercased()
            return code == "DA" ||
                   code.hasPrefix("DA_") ||
                   code.contains("DEARNESS")
        }
        if !hasDA {
            missing.append("DA (Dearness Allowance)")
        }

        // Check for MSP (Military Service Pay)
        let hasMSP = earningsComponents.contains { component in
            let code = component.code.uppercased()
            return code == "MSP" ||
                   code.hasPrefix("MSP_") ||
                   code.contains("MILITARY SERVICE PAY")
        }
        if !hasMSP {
            missing.append("MSP (Military Service Pay)")
        }

        if !missing.isEmpty {
            Logger.warning("[MandatoryComponentValidator] Missing mandatory earnings: \(missing.joined(separator: ", "))")
            return ComponentValidationResult.failure(missingComponents: missing)
        }

        Logger.info("[MandatoryComponentValidator] All mandatory earnings present ✅")
        return .success
    }

    func validateMandatoryDeductions(_ components: [PayComponent]) -> ComponentValidationResult {
        let deductionComponents = components.filter { $0.section == .deductions }
        var missing: [String] = []

        // Check for DSOP or AFPP (at least one must exist)
        let hasDSOPorAFPP = deductionComponents.contains { component in
            let code = component.code.uppercased()
            return code.contains("DSOP") || code.contains("AFPP")
        }
        if !hasDSOPorAFPP {
            missing.append("DSOP/AFPP (Provident Fund)")
        }

        // Check for AGIF (Army Group Insurance Fund)
        let hasAGIF = deductionComponents.contains { component in
            let code = component.code.uppercased()
            return code.contains("AGIF") || code.contains("ARMY GROUP INSURANCE")
        }
        if !hasAGIF {
            missing.append("AGIF (Army Group Insurance Fund)")
        }

        // Check for ITAX (Income Tax)
        let hasITAX = deductionComponents.contains { component in
            let code = component.code.uppercased()
            return code.contains("ITAX") ||
                   code.contains("INCOME TAX") ||
                   code.contains("IT_")
        }
        if !hasITAX {
            missing.append("ITAX (Income Tax)")
        }

        if !missing.isEmpty {
            Logger.warning("[MandatoryComponentValidator] Missing mandatory deductions: \(missing.joined(separator: ", "))")
            return ComponentValidationResult.failure(missingComponents: missing)
        }

        Logger.info("[MandatoryComponentValidator] All mandatory deductions present ✅")
        return .success
    }
}

/// Component de-duplicator
class ComponentDeduplicator {

    /// De-duplicates components by grouping by base code and keeping unique values
    func deduplicate(_ components: [PayComponent]) -> [PayComponent] {
        var uniqueComponents: [String: PayComponent] = [:]
        var duplicateCounts: [String: Int] = [:]

        for component in components {
            // Extract base code (remove suffixes like _EARNINGS_2, _DEDUCTIONS_3)
            let baseCode = extractBaseCode(component.code)
            let key = "\(baseCode)_\(component.section)"

            if let existing = uniqueComponents[key] {
                // Check if it's a duplicate (same value)
                if abs(existing.amount - component.amount) < 0.01 {
                    // True duplicate - skip it
                    duplicateCounts[key, default: 0] += 1
                    continue
                } else {
                    // Different value - might be a variant or different instance
                    // Keep both but use numbered key
                    let numberedKey = "\(key)_\(duplicateCounts[key, default: 1])"
                    uniqueComponents[numberedKey] = component
                    duplicateCounts[key, default: 0] += 1
                    continue
                }
            }

            uniqueComponents[key] = component
        }

        // Log duplicates removed
        let totalDuplicates = duplicateCounts.values.reduce(0, +)
        if totalDuplicates > 0 {
            Logger.info("[ComponentDeduplicator] Removed \(totalDuplicates) duplicate components")
            for (key, count) in duplicateCounts where count > 0 {
                Logger.info("[ComponentDeduplicator]   - \(key): \(count) duplicates")
            }
        }

        return Array(uniqueComponents.values)
    }

    private func extractBaseCode(_ code: String) -> String {
        // Remove suffixes like _EARNINGS_2, _DEDUCTIONS_3, _EARNINGS, _DEDUCTIONS
        let pattern = #"_(EARNINGS|DEDUCTIONS)(_\d+)?$"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(code.startIndex..., in: code)
            let cleanCode = regex.stringByReplacingMatches(
                in: code,
                range: range,
                withTemplate: ""
            )
            return cleanCode
        }
        return code
    }
}
