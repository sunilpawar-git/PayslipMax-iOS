import Foundation
@testable import PayslipMax

/// Protocol for complex payslip generation operations
protocol ComplexPayslipGeneratorProtocol {
    /// Creates a collection of payslips with varied date ranges
    static func payslipTimeSeriesData(
        startMonth: Int,
        startYear: Int,
        count: Int,
        baseCredits: Double,
        incrementAmount: Double
    ) -> [PayslipItem]

    /// Creates a set of payslips with various allowances and deductions
    static func detailedPayslipWithBreakdown(
        name: String,
        month: String,
        year: Int
    ) -> PayslipItem
}

/// A generator for complex payslip-related test data
class ComplexPayslipGenerator: ComplexPayslipGeneratorProtocol {

    // MARK: - Time Series Data Generation

    /// Creates a collection of payslips with varied date ranges
    static func payslipTimeSeriesData(
        startMonth: Int = 1,
        startYear: Int = 2022,
        count: Int = 12,
        baseCredits: Double = 5000.0,
        incrementAmount: Double = 200.0
    ) -> [PayslipItem] {
        let months = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]

        return (0..<count).map { index in
            let monthIndex = (startMonth - 1 + index) % 12
            let yearOffset = (startMonth - 1 + index) / 12
            let currentYear = startYear + yearOffset

            // Gradually increase salary over time
            let currentCredits = baseCredits + (Double(index) * incrementAmount)
            let currentDebits = currentCredits * 0.2  // 20% of credits
            let currentDSOP = currentCredits * 0.05  // 5% of credits
            let currentTax = currentCredits * 0.15  // 15% of credits

            return PayslipItem(
                month: months[monthIndex],
                year: currentYear,
                credits: currentCredits,
                debits: currentDebits,
                dsop: currentDSOP,
                tax: currentTax,
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            )
        }
    }

    // MARK: - Detailed Breakdown Generation

    /// Creates a set of payslips with various allowances and deductions
    static func detailedPayslipWithBreakdown(
        name: String = "James Wilson",
        month: String = "September",
        year: Int = 2023
    ) -> PayslipItem {
        let payslip = PayslipItem(
            month: month,
            year: year,
            credits: 8500.0,
            debits: 1700.0,
            dsop: 425.0,
            tax: 1275.0,
            name: name,
            accountNumber: "XXXX6543",
            panNumber: "PQRST6789U"
        )

        // Note: Detailed breakdown would be added here if PayslipItem conformed to DetailedPayslipRepresentable
        // For now, we return the base PayslipItem as detailed formatting is handled by specialized generators

        return payslip
    }
}
