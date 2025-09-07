import Foundation
@testable import PayslipMax

/// Helper utilities for InsightsCoordinator tests
class InsightsCoordinatorTestHelpers {

    /// Creates a standard set of test payslips for testing
    static func createStandardTestPayslips() -> [PayslipItem] {
        return [
            PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: 50000.0,
                debits: 10000.0,
                dsop: 5000.0,
                tax: 8000.0,
                name: "Test User 1",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            ),
            PayslipItem(
                id: UUID(),
                month: "February",
                year: 2023,
                credits: 52000.0,
                debits: 10500.0,
                dsop: 5200.0,
                tax: 8500.0,
                name: "Test User 1",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            ),
            PayslipItem(
                id: UUID(),
                month: "March",
                year: 2023,
                credits: 51000.0,
                debits: 10200.0,
                dsop: 5100.0,
                tax: 8200.0,
                name: "Test User 1",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            )
        ]
    }

    /// Creates a large dataset of payslips for performance testing
    static func createLargeTestPayslipSet(count: Int) -> [PayslipItem] {
        let months = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]

        return (0..<count).map { index in
            PayslipItem(
                id: UUID(),
                month: months[index % months.count],
                year: 2020 + (index / 12),
                credits: Double.random(in: 30000...80000),
                debits: Double.random(in: 5000...20000),
                dsop: Double.random(in: 2000...8000),
                tax: Double.random(in: 3000...15000),
                name: "Test User \(index % 10)",
                accountNumber: "ACC\(String(format: "%03d", index % 100))",
                panNumber: "PAN\(String(format: "%03d", index % 100))"
            )
        }
    }

    /// Creates payslips with specific patterns for testing
    static func createPayslipsWithPattern(
        months: [String],
        baseCredits: Double,
        growthRate: Double
    ) -> [PayslipItem] {
        return months.enumerated().map { index, month in
            let credits = baseCredits * pow(1 + growthRate, Double(index))
            PayslipItem(
                id: UUID(),
                month: month,
                year: 2023,
                credits: credits,
                debits: credits * 0.2, // 20% deductions
                dsop: credits * 0.1,   // 10% DSOP
                tax: credits * 0.16,   // 16% tax
                name: "Test User 1",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            )
        }
    }

    /// Creates payslips with edge case values for testing
    static func createEdgeCasePayslips() -> [PayslipItem] {
        return [
            // Zero credits
            PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: 0.0,
                debits: 0.0,
                dsop: 0.0,
                tax: 0.0,
                name: "Test User",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            ),
            // Very high values
            PayslipItem(
                id: UUID(),
                month: "February",
                year: 2023,
                credits: 999999.99,
                debits: 999999.99,
                dsop: 999999.99,
                tax: 999999.99,
                name: "Test User",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            ),
            // Negative values (edge case)
            PayslipItem(
                id: UUID(),
                month: "March",
                year: 2023,
                credits: 50000.0,
                debits: -1000.0,
                dsop: 5000.0,
                tax: 8000.0,
                name: "Test User",
                accountNumber: "ACC001",
                panNumber: "PAN001"
            )
        ]
    }

    /// Creates payslips for different years for trend testing
    static func createMultiYearPayslips() -> [PayslipItem] {
        var payslips: [PayslipItem] = []

        for year in 2020...2023 {
            for month in ["January", "June", "December"] {
                payslips.append(
                    PayslipItem(
                        id: UUID(),
                        month: month,
                        year: year,
                        credits: Double(40000 + (year - 2020) * 5000), // Annual growth
                        debits: Double(8000 + (year - 2020) * 1000),
                        dsop: 4000.0,
                        tax: Double(6000 + (year - 2020) * 800),
                        name: "Test User",
                        accountNumber: "ACC001",
                        panNumber: "PAN001"
                    )
                )
            }
        }

        return payslips
    }
}
