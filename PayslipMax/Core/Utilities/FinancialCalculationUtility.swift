import Foundation

/// Protocol for Financial Calculation Utility to enable dependency injection
protocol FinancialCalculationUtilityProtocol {
    /// Calculates the correct total deductions for a payslip
    func calculateTotalDeductions(for payslip: any PayslipDataProtocol) -> Double

    /// Calculates the correct net income for a payslip
    func calculateNetIncome(for payslip: any PayslipDataProtocol) -> Double

    /// Aggregates total income across multiple payslips
    func aggregateTotalIncome(for payslips: [any PayslipDataProtocol]) -> Double

    /// Aggregates total deductions across multiple payslips
    func aggregateTotalDeductions(for payslips: [any PayslipDataProtocol]) -> Double

    /// Aggregates net income across multiple payslips
    func aggregateNetIncome(for payslips: [any PayslipDataProtocol]) -> Double

    /// Calculates average monthly income from a set of payslips
    func calculateAverageMonthlyIncome(for payslips: [any PayslipDataProtocol]) -> Double

    /// Calculates average monthly net remittance from a set of payslips
    func calculateAverageNetRemittance(for payslips: [any PayslipDataProtocol]) -> Double

    /// Creates a unified earnings breakdown from multiple payslips
    func calculateEarningsBreakdown(for payslips: [any PayslipDataProtocol]) -> [(category: String, amount: Double, percentage: Double)]

    /// Creates a unified deductions breakdown from multiple payslips
    func calculateDeductionsBreakdown(for payslips: [any PayslipDataProtocol]) -> [(category: String, amount: Double, percentage: Double)]

    /// Calculates percentage change between two values
    func calculatePercentageChange(from: Double, to: Double) -> Double

    /// Calculates income trend by comparing first and second half of payslips
    func calculateIncomeTrend(for payslips: [any PayslipDataProtocol]) -> Double

    /// Calculates deductions trend by comparing first and second half of payslips
    func calculateDeductionsTrend(for payslips: [any PayslipDataProtocol]) -> Double

    /// Calculates net income trend by comparing first and second half of payslips
    func calculateNetIncomeTrend(for payslips: [any PayslipDataProtocol]) -> Double

    /// Calculates growth rate between current and previous values
    func calculateGrowthRate(current: Double, previous: Double) -> Double

    /// Validates that financial calculations are consistent across a payslip
    func validateFinancialConsistency(for payslip: any PayslipDataProtocol) -> [String]
}

/// Centralized utility for uniform financial calculations across the PayslipMax project.
/// This ensures consistent calculation logic and prevents double-counting errors.
/// Now supports both singleton and dependency injection patterns
class FinancialCalculationUtility: FinancialCalculationUtilityProtocol, FinancialCalculationServiceProtocol, SafeConversionProtocol {

    // MARK: - Singleton
    static let shared = FinancialCalculationUtility()

    /// Current conversion state
    var conversionState: ConversionState = .singleton

    /// Feature flag that controls DI vs singleton usage
    var controllingFeatureFlag: Feature { return .diFinancialCalculationUtility }

    /// Initialize with dependency injection support
    /// - Parameter dependencies: Optional dependencies (none required for this service)
    init(dependencies: [String: Any] = [:]) {
        // No dependencies required for financial calculations
    }

    // MARK: - Core Financial Calculations

    /// Calculates the correct total deductions for a payslip.
    /// Uses debits as the authoritative total (which already includes all deductions).
    /// - Parameter payslip: The payslip to calculate deductions for
    /// - Returns: The total deductions amount
    func calculateTotalDeductions(for payslip: any PayslipDataProtocol) -> Double {
        // The debits field is the authoritative total deductions
        // It already includes tax, dsop, and all other deductions
        return payslip.debits
    }

    /// Calculates the correct net income for a payslip.
    /// Net income = credits - debits (debits already includes all deductions)
    /// - Parameter payslip: The payslip to calculate net income for
    /// - Returns: The net income amount
    func calculateNetIncome(for payslip: any PayslipDataProtocol) -> Double {
        return payslip.credits - payslip.debits
    }

    /// Aggregates total income across multiple payslips.
    /// - Parameter payslips: Array of payslips to aggregate
    /// - Returns: Total income across all payslips
    func aggregateTotalIncome(for payslips: [any PayslipDataProtocol]) -> Double {
        return payslips.reduce(0) { $0 + $1.credits }
    }

    /// Aggregates total deductions across multiple payslips.
    /// - Parameter payslips: Array of payslips to aggregate
    /// - Returns: Total deductions across all payslips
    func aggregateTotalDeductions(for payslips: [any PayslipDataProtocol]) -> Double {
        return payslips.reduce(0) { $0 + calculateTotalDeductions(for: $1) }
    }

    /// Aggregates net income across multiple payslips.
    /// - Parameter payslips: Array of payslips to aggregate
    /// - Returns: Total net income across all payslips
    func aggregateNetIncome(for payslips: [any PayslipDataProtocol]) -> Double {
        return payslips.reduce(0) { $0 + calculateNetIncome(for: $1) }
    }

    /// Calculates average monthly income from a set of payslips.
    /// - Parameter payslips: Array of payslips to calculate average from
    /// - Returns: Average monthly income or 0 if no payslips
    func calculateAverageMonthlyIncome(for payslips: [any PayslipDataProtocol]) -> Double {
        guard !payslips.isEmpty else { return 0 }
        let totalIncome = aggregateTotalIncome(for: payslips)
        return totalIncome / Double(payslips.count)
    }

    /// Calculates average monthly net remittance from a set of payslips.
    /// - Parameter payslips: Array of payslips to calculate average from
    /// - Returns: Average monthly net remittance or 0 if no payslips
    func calculateAverageNetRemittance(for payslips: [any PayslipDataProtocol]) -> Double {
        guard !payslips.isEmpty else { return 0 }
        let totalNetIncome = aggregateNetIncome(for: payslips)
        return totalNetIncome / Double(payslips.count)
    }

    // MARK: - Category Breakdown Calculations

    /// Creates a unified earnings breakdown from multiple payslips.
    /// Aggregates earnings by category across all payslips.
    /// - Parameter payslips: Array of payslips to analyze
    /// - Returns: Dictionary of category totals with percentages
    func calculateEarningsBreakdown(for payslips: [any PayslipDataProtocol]) -> [(category: String, amount: Double, percentage: Double)] {
        var categoryTotals: [String: Double] = [:]

        for payslip in payslips {
            for (category, amount) in payslip.earnings {
                categoryTotals[category, default: 0] += amount
            }
        }

        let totalIncome = categoryTotals.values.reduce(0, +)

        return categoryTotals
            .compactMap { (category, amount) in
                guard amount > 0 else { return nil }
                let percentage = totalIncome > 0 ? (amount / totalIncome) * 100 : 0
                return (category: category, amount: amount, percentage: percentage)
            }
            .sorted { $0.amount > $1.amount }
    }

    /// Creates a unified deductions breakdown from multiple payslips.
    /// Prevents double-counting of tax and DSOP by checking if they're already in deductions dictionary.
    /// - Parameter payslips: Array of payslips to analyze
    /// - Returns: Dictionary of category totals with percentages
    func calculateDeductionsBreakdown(for payslips: [any PayslipDataProtocol]) -> [(category: String, amount: Double, percentage: Double)] {
        var categoryTotals: [String: Double] = [:]

        for payslip in payslips {
            // Add deductions from the detailed breakdown
            for (category, amount) in payslip.deductions {
                categoryTotals[category, default: 0] += amount
            }

            // Only add tax and DSOP if they're NOT already in deductions dictionary
            // This prevents double-counting
            if payslip.tax > 0 && !payslip.deductions.keys.contains(where: { key in
                key.uppercased().contains("TAX") || key.uppercased().contains("ITAX")
            }) {
                categoryTotals["Income Tax", default: 0] += payslip.tax
            }

            if payslip.dsop > 0 && payslip.deductions["DSOP"] == nil {
                categoryTotals["DSOP", default: 0] += payslip.dsop
            }
        }

        let totalDeductions = categoryTotals.values.reduce(0, +)

        return categoryTotals
            .compactMap { (category, amount) in
                guard amount > 0 else { return nil }
                let percentage = totalDeductions > 0 ? (amount / totalDeductions) * 100 : 0
                return (category: category, amount: amount, percentage: percentage)
            }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Trend Calculations

    /// Calculates percentage change between two values.
    /// - Parameters:
    ///   - from: The original value
    ///   - to: The new value
    /// - Returns: Percentage change (positive for increase, negative for decrease)
    func calculatePercentageChange(from: Double, to: Double) -> Double {
        guard from > 0 else { return 0 }
        return ((to - from) / from) * 100
    }

    /// Calculates income trend by comparing first and second half of payslips.
    /// - Parameter payslips: Array of payslips sorted by date
    /// - Returns: Percentage change in income trend
    func calculateIncomeTrend(for payslips: [any PayslipDataProtocol]) -> Double {
        return self.calculateTrend(for: payslips, getValue: { $0.credits })
    }

    /// Calculates deductions trend by comparing first and second half of payslips.
    /// - Parameter payslips: Array of payslips sorted by date
    /// - Returns: Percentage change in deductions trend
    func calculateDeductionsTrend(for payslips: [any PayslipDataProtocol]) -> Double {
        return self.calculateTrend(for: payslips, getValue: { calculateTotalDeductions(for: $0) })
    }

    /// Calculates net income trend by comparing first and second half of payslips.
    /// - Parameter payslips: Array of payslips sorted by date
    /// - Returns: Percentage change in net income trend
    func calculateNetIncomeTrend(for payslips: [any PayslipDataProtocol]) -> Double {
        return self.calculateTrend(for: payslips, getValue: { calculateNetIncome(for: $0) })
    }

    /// Calculates growth rate between current and previous values.
    /// - Parameters:
    ///   - current: The current value
    ///   - previous: The previous value
    /// - Returns: Growth rate as a percentage
    func calculateGrowthRate(current: Double, previous: Double) -> Double {
        return calculatePercentageChange(from: previous, to: current)
    }

    // MARK: - Validation Methods

    /// Validates that financial calculations are consistent across a payslip.
    /// - Parameter payslip: The payslip to validate
    /// - Returns: Array of validation issues found
    func validateFinancialConsistency(for payslip: any PayslipDataProtocol) -> [String] {
        var issues: [String] = []

        // Check if debits equals sum of deductions + tax + dsop (should NOT be the case)
        let deductionsSum = payslip.deductions.values.reduce(0, +)
        let manualSum = deductionsSum + payslip.tax + payslip.dsop

        if abs(payslip.debits - manualSum) < 1.0 && payslip.tax > 0 && payslip.dsop > 0 {
            issues.append("Possible double-counting: debits equals deductions + tax + dsop")
        }

        // Check if DSOP is in both deductions dictionary and dsop property
        if let dsopInDeductions = payslip.deductions["DSOP"], payslip.dsop > 0 {
            if abs(dsopInDeductions - payslip.dsop) < 1.0 {
                issues.append("DSOP is duplicated in both deductions dictionary and dsop property")
            }
        }

        // Check if tax is in both deductions dictionary and tax property
        let taxInDeductions = payslip.deductions.first { key, _ in
            key.uppercased().contains("TAX") || key.uppercased().contains("ITAX")
        }

        if let (_, taxAmount) = taxInDeductions, payslip.tax > 0 {
            if abs(taxAmount - payslip.tax) < 1.0 {
                issues.append("Tax is duplicated in both deductions dictionary and tax property")
            }
        }

        return issues
    }

    // MARK: - SafeConversionProtocol Implementation

    /// Validates that the service can be safely converted to DI
    func validateConversionSafety() async -> Bool {
        // Financial calculation utility has no external dependencies, safe to convert
        return true
    }

    /// Validates dependencies are properly injected and functional
    func validateDependencies() async -> DependencyValidationResult {
        // Financial calculation utility has no external dependencies
        return DependencyValidationResult.success
    }

    /// Creates a new instance via dependency injection
    func createDIInstance(dependencies: [String: Any]) -> Self? {
        return FinancialCalculationUtility(dependencies: dependencies) as? Self
    }

    /// Performs the conversion from singleton to DI pattern
    func performConversion(container: any DIContainerProtocol) async -> Bool {
        await MainActor.run {
            conversionState = .converting
            ConversionTracker.shared.updateConversionState(for: FinancialCalculationUtility.self, state: .converting)
        }

        // Note: Integration with existing DI architecture will be handled separately
        // This method validates the conversion is safe and updates tracking

        await MainActor.run {
            conversionState = .dependencyInjected
            ConversionTracker.shared.updateConversionState(for: FinancialCalculationUtility.self, state: .dependencyInjected)
        }

        Logger.info("Successfully converted FinancialCalculationUtility to DI pattern", category: "FinancialCalculationUtility")
        return true
    }

    /// Rolls back to singleton pattern if issues are detected
    func rollbackConversion() async -> Bool {
        await MainActor.run {
            conversionState = .singleton
            ConversionTracker.shared.updateConversionState(for: FinancialCalculationUtility.self, state: .singleton)
        }
        Logger.info("Rolled back FinancialCalculationUtility to singleton pattern", category: "FinancialCalculationUtility")
        return true
    }

    /// Returns the singleton instance (fallback mode)
    static func sharedInstance() -> Self {
        return shared as! Self
    }

    /// Determines whether to use DI or singleton based on feature flags
    @MainActor static func resolveInstance() -> Self {
        let featureFlagManager = FeatureFlagManager.shared
        let shouldUseDI = featureFlagManager.isEnabled(.diFinancialCalculationUtility)

        if shouldUseDI {
            // Note: DI resolution will be integrated with existing factory pattern
            // For now, fallback to singleton until factory methods are implemented
            Logger.debug("DI enabled for FinancialCalculationUtility, but using singleton fallback", category: "FinancialCalculationUtility")
        }

        // Fallback to singleton
        return shared as! Self
    }
}
