import Foundation
import PDFKit

// Note: PayslipItemProtocol and PayslipItemFactory are defined in their respective files

// MARK: - PayslipData Factory Methods

extension PayslipData {

    // MARK: - Universal Dual-Section Helper Methods

    /// Enhanced universal dual-key retrieval for any allowance
    /// Supports both new dual-section keys (_EARNINGS/_DEDUCTIONS) and legacy single keys
    /// - Parameters:
    ///   - payslip: The payslip containing earnings and deductions
    ///   - baseKey: The base component key (e.g., "HRA", "CEA", "RH12")
    /// - Returns: Net value (earnings - deductions) + legacy compatibility
    private static func getUniversalDualSectionValue(from payslip: AnyPayslip, baseKey: String) -> Double {
        let earningsKey = "\(baseKey)_EARNINGS"
        let deductionsKey = "\(baseKey)_DEDUCTIONS"

        let earningsValue = payslip.earnings[earningsKey] ?? 0
        let deductionsValue = payslip.deductions[deductionsKey] ?? 0
        let legacyEarningsValue = payslip.earnings[baseKey] ?? 0
        let legacyDeductionsValue = payslip.deductions[baseKey] ?? 0

        // Return net value: (earnings - deductions) + legacy compatibility
        let netValue = earningsValue + legacyEarningsValue - deductionsValue - legacyDeductionsValue

        // Only log in non-test environments for debugging dual-section retrieval
        if !ProcessInfo.isRunningInTestEnvironment && (earningsValue > 0 || deductionsValue > 0 || legacyEarningsValue > 0 || legacyDeductionsValue > 0) {
            print("PayslipDataFactory: Universal dual-section value for \(baseKey): earnings=₹\(earningsValue), deductions=₹\(deductionsValue), legacy_earnings=₹\(legacyEarningsValue), legacy_deductions=₹\(legacyDeductionsValue), net=₹\(netValue)")
        }

        return netValue
    }

    /// Gets the total absolute value for display (for allowances that can appear in both sections)
    /// - Parameters:
    ///   - payslip: The payslip containing earnings and deductions
    ///   - baseKey: The base component key
    /// - Returns: Total absolute value regardless of section
    private static func getUniversalDualSectionAbsoluteValue(from payslip: AnyPayslip, baseKey: String) -> Double {
        let earningsKey = "\(baseKey)_EARNINGS"
        let deductionsKey = "\(baseKey)_DEDUCTIONS"

        let earningsValue = payslip.earnings[earningsKey] ?? 0
        let deductionsValue = payslip.deductions[deductionsKey] ?? 0
        let legacyEarningsValue = payslip.earnings[baseKey] ?? 0
        let legacyDeductionsValue = payslip.deductions[baseKey] ?? 0

        return earningsValue + deductionsValue + legacyEarningsValue + legacyDeductionsValue
    }

    /// Comprehensive universal allowance retrieval for any component
    /// Handles both guaranteed single-section and universal dual-section components
    /// - Parameters:
    ///   - payslip: The payslip containing earnings and deductions
    ///   - components: Array of component keys to check (in priority order)
    ///   - isDualSection: Whether this component supports dual-section processing
    /// - Returns: Total value found across all component variations
    private static func getUniversalAllowanceValue(
        from payslip: AnyPayslip,
        components: [String],
        isDualSection: Bool = true
    ) -> Double {
        var totalValue: Double = 0

        for component in components {
            if isDualSection {
                totalValue += getUniversalDualSectionValue(from: payslip, baseKey: component)
            } else {
                // For guaranteed single-section components, check both dictionaries for safety
                totalValue += payslip.earnings[component] ?? payslip.deductions[component] ?? 0
            }
        }

        return totalValue
    }
    /// Creates a `PayslipData` instance from a type conforming to `PayslipItemProtocol`.
    /// Extracts and maps relevant fields.
    /// - Parameter payslipItem: The source payslip item.
    /// - Returns: A new `PayslipData` instance populated with data from `payslipItem`.
    @available(*, deprecated, message: "Use initializer with PayslipProtocol instead")
    static func from(payslipItem: any PayslipItemProtocol) -> PayslipData {
        var data = PayslipData(from: PayslipItemFactory.createEmpty() as any PayslipProtocol)

        // Personal details
        data.id = payslipItem.id
        data.timestamp = payslipItem.timestamp
        data.name = payslipItem.name
        data.accountNumber = payslipItem.accountNumber
        data.panNumber = payslipItem.panNumber
        data.month = payslipItem.month
        data.year = payslipItem.year

        // Financial summary
        data.totalCredits = payslipItem.credits
        data.totalDebits = payslipItem.debits
        data.dsop = payslipItem.dsop
        data.tax = payslipItem.tax
        data.incomeTax = payslipItem.tax
        data.netRemittance = payslipItem.credits - payslipItem.debits

        // Store all earnings and deductions
        data.allEarnings = payslipItem.earnings
        data.allDeductions = payslipItem.deductions

        // Standard earnings components - Updated to use new unified extraction keys
        data.basicPay = payslipItem.earnings["Basic Pay"] ?? payslipItem.earnings["BPAY"] ?? 0
        data.dearnessPay = payslipItem.earnings["Dearness Allowance"] ?? payslipItem.earnings["DA"] ?? 0
        data.militaryServicePay = payslipItem.earnings["Military Service Pay"] ?? payslipItem.earnings["MSP"] ?? 0

        // Handle dual-section RH12 using new distinct keys for Phase 2 implementation
        let rh12Earnings = payslipItem.earnings["RH12_EARNINGS"] ?? payslipItem.earnings["Risk and Hardship Allowance"] ?? 0
        let rh12Deductions = payslipItem.deductions["RH12_DEDUCTIONS"] ?? payslipItem.deductions["Risk and Hardship Allowance"] ?? 0
        let rh12Value = rh12Earnings + rh12Deductions

        // Only log in non-test environments to reduce test verbosity
        if !ProcessInfo.isRunningInTestEnvironment {
            print("PayslipData: Found RH12 earnings: \(rh12Earnings), deductions: \(rh12Deductions), total: \(rh12Value)")
            print("PayslipData: Available earnings keys: \(Array(payslipItem.earnings.keys))")
            print("PayslipData: Available deductions keys: \(Array(payslipItem.deductions.keys))")
        }

        // Calculate miscCredits as the difference between total credits and known components
        let knownEarnings = data.basicPay + data.dearnessPay + data.militaryServicePay
        data.miscCredits = data.totalCredits - knownEarnings

        if !ProcessInfo.isRunningInTestEnvironment {
            print("PayslipData: Basic Pay: \(data.basicPay), DA: \(data.dearnessPay), MSP: \(data.militaryServicePay)")
            print("PayslipData: knownEarnings: \(knownEarnings), miscCredits: \(data.miscCredits)")
        }

        return data
    }

    /// Creates a `PayslipData` instance from any type conforming to `PayslipProtocol`.
    /// Extracts and maps relevant fields, including standard components and metadata.
    /// Calculates miscellaneous credits based on known earnings components.
    /// - Parameter payslip: The source payslip object conforming to `PayslipProtocol`.
    init(from payslip: AnyPayslip) {
        // Personal details
        self.id = payslip.id
        self.timestamp = payslip.timestamp
        self.name = payslip.name
        self.accountNumber = payslip.accountNumber
        self.panNumber = payslip.panNumber
        self.month = payslip.month
        self.year = payslip.year

        // Financial summary
        self.totalCredits = payslip.credits
        self.totalDebits = payslip.debits
        self.credits = payslip.credits      // Set protocol property for calculateNetAmount()
        self.debits = payslip.debits        // Set protocol property for calculateNetAmount()
        self.dsop = payslip.dsop
        self.tax = payslip.tax
        self.incomeTax = payslip.tax
        self.netRemittance = payslip.credits - payslip.debits

        // Store all earnings and deductions
        self.allEarnings = payslip.earnings
        self.allDeductions = payslip.deductions
        self.earnings = payslip.earnings    // Set protocol property for compatibility
        self.deductions = payslip.deductions // Set protocol property for compatibility

        // Standard earnings components - Enhanced with universal dual-section support
        self.basicPay = payslip.earnings["Basic Pay"] ?? payslip.earnings["BPAY"] ?? 0
        self.dearnessPay = Self.getUniversalDualSectionValue(from: payslip, baseKey: "DA") +
                          (payslip.earnings["Dearness Allowance"] ?? 0)
        self.militaryServicePay = payslip.earnings["Military Service Pay"] ?? payslip.earnings["MSP"] ?? 0

        // Enhanced universal dual-section handling for all allowances
        let rh12Value = Self.getUniversalDualSectionAbsoluteValue(from: payslip, baseKey: "RH12") +
                       (payslip.earnings["Risk and Hardship Allowance"] ?? 0) +
                       (payslip.deductions["Risk and Hardship Allowance"] ?? 0)

        // Only log in non-test environments to reduce test verbosity
        if !ProcessInfo.isRunningInTestEnvironment {
            let rh12Earnings = payslip.earnings["RH12_EARNINGS"] ?? 0
            let rh12Deductions = payslip.deductions["RH12_DEDUCTIONS"] ?? 0
            print("PayslipData: Enhanced dual-section RH12 - earnings: ₹\(rh12Earnings), deductions: ₹\(rh12Deductions), total: ₹\(rh12Value)")
            print("PayslipData: Available earnings keys: \(Array(payslip.earnings.keys))")
            print("PayslipData: Available deductions keys: \(Array(payslip.deductions.keys))")
        }

        // Enhanced guaranteed deductions with universal support
        self.agif = Self.getUniversalAllowanceValue(
            from: payslip,
            components: ["AGIF", "Army Group Insurance Fund"],
            isDualSection: false  // AGIF is guaranteed deductions only
        )

        // Calculate miscCredits as the difference between total credits and known components
        let knownEarnings = self.basicPay + self.dearnessPay + self.militaryServicePay
        self.miscCredits = self.totalCredits - knownEarnings

        // Calculate miscDebits excluding known deductions
        self.miscDebits = self.totalDebits - self.dsop - self.tax - self.agif

        // Only log in non-test environments to reduce test verbosity
        if !ProcessInfo.isRunningInTestEnvironment {
            print("PayslipData: Enhanced components - Basic Pay: ₹\(self.basicPay), DA: ₹\(self.dearnessPay), MSP: ₹\(self.militaryServicePay)")
            print("PayslipData: Enhanced deductions - AGIF: ₹\(self.agif), Tax: ₹\(self.tax), DSOP: ₹\(self.dsop)")
            print("PayslipData: Calculated misc - Credits: ₹\(self.miscCredits), Debits: ₹\(self.miscDebits)")
        }

        // Metadata
        self.pdfData = payslip.pdfData
        self.isSample = payslip.isSample
        self.source = payslip.source
        self.status = payslip.status
    }
}

// MARK: - PayslipData Factory Protocol

/// Protocol for creating PayslipData instances
protocol PayslipDataFactoryProtocol {
    /// Create PayslipData from any payslip protocol
    static func create(from payslip: AnyPayslip) -> PayslipData

    /// Create empty PayslipData
    static func createEmpty() -> PayslipData

    /// Create sample PayslipData for testing
    static func createSample() -> PayslipData
}

// MARK: - PayslipData Factory Implementation

/// Factory class for creating PayslipData instances
class PayslipDataFactory: PayslipDataFactoryProtocol {
    /// Create PayslipData from any payslip protocol
    static func create(from payslip: AnyPayslip) -> PayslipData {
        return PayslipData(from: payslip)
    }

    /// Create empty PayslipData
    static func createEmpty() -> PayslipData {
        return PayslipData()
    }

    /// Create sample PayslipData for testing
    static func createSample() -> PayslipData {
        var data = PayslipData()
        data.id = UUID()
        data.timestamp = Date()
        data.name = "Sample Officer"
        data.month = "January"
        data.year = 2024
        data.totalCredits = 75000.0
        data.totalDebits = 15000.0
        data.dsop = 5000.0
        data.tax = 8000.0
        data.netRemittance = 55000.0

        // Sample earnings
        data.allEarnings = [
            "Basic Pay": 50000.0,
            "Dearness Allowance": 15000.0,
            "Military Service Pay": 10000.0
        ]

        // Sample deductions
        data.allDeductions = [
            "Tax": 8000.0,
            "AGIF": 2000.0,
            "DSOP": 5000.0
        ]

        data.basicPay = 50000.0
        data.dearnessPay = 15000.0
        data.militaryServicePay = 10000.0
        data.miscCredits = 0.0
        data.agif = 2000.0
        data.miscDebits = 0.0

        data.isSample = true
        data.source = "Factory Sample"
        data.status = "Active"

        return data
    }
}
