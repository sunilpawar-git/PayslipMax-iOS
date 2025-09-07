import Foundation
@testable import PayslipMax

/// Shared helper methods and test data generators for ChartDataPreparationService tests
/// Provides common test utilities to reduce code duplication across test files
struct ChartDataPreparationServiceTestHelpers {

    /// Creates a test payslip with specified values
    /// - Parameters:
    ///   - month: Month string for the payslip
    ///   - year: Year integer for the payslip
    ///   - credits: Credits amount
    ///   - debits: Debits amount
    /// - Returns: PayslipItem configured with test values
    static func createTestPayslip(
        month: String,
        year: Int,
        credits: Double,
        debits: Double
    ) -> PayslipItem {
        return PayslipItem(
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: 0.0,
            tax: 0.0,
            name: "Test User",
            accountNumber: "TEST123",
            panNumber: "TESTPAN"
        )
    }

    /// Creates a collection of test payslips with sequential data
    /// - Parameter count: Number of payslips to create
    /// - Returns: Array of test payslips
    static func createSequentialTestPayslips(count: Int) -> [PayslipItem] {
        var payslips: [PayslipItem] = []

        for i in 1...count {
            let payslip = createTestPayslip(
                month: "Month\(i % 12 + 1)",
                year: 2020 + (i / 12),
                credits: Double(4000 + i),
                debits: Double(800 + i / 5)
            )
            payslips.append(payslip)
        }

        return payslips
    }

    /// Creates payslips for performance testing with large dataset
    /// - Parameter count: Number of payslips to create
    /// - Returns: Array of payslips optimized for performance testing
    static func createPerformanceTestPayslips(count: Int) -> [PayslipItem] {
        var payslips: [PayslipItem] = []

        for i in 1...count {
            let payslip = createTestPayslip(
                month: "Month\(i % 12 + 1)",
                year: 2020 + (i / 12),
                credits: Double(4000 + i),
                debits: Double(800 + i / 5)
            )
            payslips.append(payslip)
        }

        return payslips
    }

    /// Creates payslips with varied financial values for edge case testing
    /// - Returns: Array of payslips with different value scenarios
    static func createEdgeCasePayslips() -> [PayslipItem] {
        return [
            // Zero values
            createTestPayslip(month: "Zero", year: 2024, credits: 0.0, debits: 0.0),

            // Negative net (debits > credits)
            createTestPayslip(month: "Negative", year: 2024, credits: 3000.0, debits: 4000.0),

            // Large values
            createTestPayslip(month: "Large", year: 2024, credits: 999999.99, debits: 123456.78),

            // Decimal precision
            createTestPayslip(month: "Decimal", year: 2024, credits: 4567.89, debits: 1234.56)
        ]
    }

    /// Creates payslips with different month formats for format testing
    /// - Returns: Array of payslips with varied month representations
    static func createVariedFormatPayslips() -> [PayslipItem] {
        return [
            createTestPayslip(month: "Jan", year: 2023, credits: 4000.0, debits: 800.0),
            createTestPayslip(month: "February", year: 2024, credits: 4200.0, debits: 900.0),
            createTestPayslip(month: "03", year: 2024, credits: 4100.0, debits: 850.0),
            createTestPayslip(month: "December", year: 2025, credits: 4500.0, debits: 950.0)
        ]
    }

    /// Validates chart data properties match expected values
    /// - Parameters:
    ///   - chartData: Array of PayslipChartData to validate
    ///   - expectedCount: Expected number of items
    ///   - expectedValues: Array of expected values for validation
    /// - Returns: Validation result for use in test assertions
    static func validateChartData(
        _ chartData: [PayslipChartData],
        expectedCount: Int,
        expectedValues: [(month: String, credits: Double, debits: Double, net: Double)]? = nil
    ) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []

        if chartData.count != expectedCount {
            errors.append("Expected \(expectedCount) items, but got \(chartData.count)")
        }

        if let expectedValues = expectedValues {
            for (index, expected) in expectedValues.enumerated() {
                guard index < chartData.count else {
                    errors.append("Missing item at index \(index)")
                    break
                }

                let item = chartData[index]
                if item.month != expected.month {
                    errors.append("Item \(index): expected month '\(expected.month)', got '\(item.month)'")
                }
                if item.credits != expected.credits {
                    errors.append("Item \(index): expected credits \(expected.credits), got \(item.credits)")
                }
                if item.debits != expected.debits {
                    errors.append("Item \(index): expected debits \(expected.debits), got \(item.debits)")
                }
                if item.net != expected.net {
                    errors.append("Item \(index): expected net \(expected.net), got \(item.net)")
                }
            }
        }

        return (errors.isEmpty, errors)
    }
}

// Support enums (if not available)
private enum ProcessingQuality: CaseIterable, Codable {
    case high, medium, low
}

private enum ExtractionSource: CaseIterable, Codable {
    case manual, ocr, pattern
}
