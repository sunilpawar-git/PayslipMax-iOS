import Foundation
import PDFKit

// Note: PayslipItemProtocol and PayslipItemFactory are defined in their respective files

// MARK: - PayslipData Factory Methods

extension PayslipData {
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
        print("PayslipData: Found RH12 earnings: \(rh12Earnings), deductions: \(rh12Deductions), total: \(rh12Value)")
        print("PayslipData: Available earnings keys: \(Array(payslipItem.earnings.keys))")
        print("PayslipData: Available deductions keys: \(Array(payslipItem.deductions.keys))")

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

        // Handle dual-section RH12 using new distinct keys for Phase 2 implementation
        let rh12Earnings = payslip.earnings["RH12_EARNINGS"] ?? payslip.earnings["Risk and Hardship Allowance"] ?? 0
        let rh12Deductions = payslip.deductions["RH12_DEDUCTIONS"] ?? payslip.deductions["Risk and Hardship Allowance"] ?? 0
        let rh12Value = rh12Earnings + rh12Deductions
        print("PayslipData: Found RH12 earnings: \(rh12Earnings), deductions: \(rh12Deductions), total: \(rh12Value)")
        print("PayslipData: Available earnings keys: \(Array(payslip.earnings.keys))")
        print("PayslipData: Available deductions keys: \(Array(payslip.deductions.keys))")

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
