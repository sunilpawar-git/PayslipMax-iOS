import Foundation
import PDFKit

// Forward declarations for external dependencies
// These will be resolved by the module imports in the main project
typealias PayslipItemProtocol = any PayslipProtocol
class PayslipItemFactory {
    static func createEmpty() -> any PayslipProtocol {
        // This would normally return a PayslipItem, but for compilation we return a protocol
        fatalError("PayslipItemFactory.createEmpty() should be implemented in the actual factory")
    }
}

// MARK: - PayslipData Factory Methods

extension PayslipData {
    /// Creates a `PayslipData` instance from a type conforming to `PayslipItemProtocol`.
    /// Extracts and maps relevant fields.
    /// - Parameter payslipItem: The source payslip item.
    /// - Returns: A new `PayslipData` instance populated with data from `payslipItem`.
    @available(*, deprecated, message: "Use initializer with PayslipProtocol instead")
    static func from(payslipItem: any PayslipItemProtocol) -> PayslipData {
        var data = PayslipData(from: (PayslipItemFactory.createEmpty() as! any PayslipProtocol))

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

        // Handle the RH12 using correct unified extraction key
        let rh12Value = payslipItem.earnings["Risk and Hardship Allowance"] ?? payslipItem.earnings["RH12"] ?? payslipItem.deductions["RH12"] ?? 0
        print("PayslipData: Found RH12 value: \(rh12Value) from Risk and Hardship Allowance key")

        // Calculate miscCredits as the difference between total credits and known components
        let knownEarnings = data.basicPay + data.dearnessPay + data.militaryServicePay
        data.miscCredits = data.totalCredits - knownEarnings

        print("PayslipData: Basic Pay: \(data.basicPay), DA: \(data.dearnessPay), MSP: \(data.militaryServicePay)")
        print("PayslipData: knownEarnings: \(knownEarnings), miscCredits: \(data.miscCredits)")

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
        self.dsop = payslip.dsop
        self.tax = payslip.tax
        self.incomeTax = payslip.tax
        self.netRemittance = payslip.credits - payslip.debits

        // Store all earnings and deductions
        self.allEarnings = payslip.earnings
        self.allDeductions = payslip.deductions

        // Standard earnings components - Updated to use new unified extraction keys
        self.basicPay = payslip.earnings["Basic Pay"] ?? payslip.earnings["BPAY"] ?? 0
        self.dearnessPay = payslip.earnings["Dearness Allowance"] ?? payslip.earnings["DA"] ?? 0
        self.militaryServicePay = payslip.earnings["Military Service Pay"] ?? payslip.earnings["MSP"] ?? 0

        // Handle the RH12 using correct unified extraction key
        let rh12Value = payslip.earnings["Risk and Hardship Allowance"] ?? payslip.earnings["RH12"] ?? payslip.deductions["RH12"] ?? 0
        print("PayslipData: Found RH12 value: \(rh12Value) from Risk and Hardship Allowance key")

        // Calculate miscCredits as the difference between total credits and known components
        let knownEarnings = self.basicPay + self.dearnessPay + self.militaryServicePay
        self.miscCredits = self.totalCredits - knownEarnings

        // Metadata
        self.pdfData = payslip.pdfData
        self.isSample = payslip.isSample
        self.source = payslip.source
        self.status = payslip.status

        print("PayslipData: Basic Pay: \(self.basicPay), DA: \(self.dearnessPay), MSP: \(self.militaryServicePay)")
        print("PayslipData: knownEarnings: \(knownEarnings), miscCredits: \(self.miscCredits)")
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
