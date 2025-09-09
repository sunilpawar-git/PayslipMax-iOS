import XCTest
import SwiftUI
@testable import PayslipMax

/// Test helper class for InsightsCoordinator tests
/// Provides mock data creation methods following SOLID principles
@MainActor
final class InsightsCoordinatorTestHelpers {

    // MARK: - Mock Data Creation

    /// Creates a single mock payslip for testing
    static func createMockPayslips() -> [PayslipItem] {
        return [
            PayslipItem(
                month: "April",
                year: 2024,
                credits: 6500.0,
                debits: 1690.0,
                dsop: 325.0,
                tax: 1300.0,
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            )
        ]
    }

    /// Creates multiple mock payslips for testing
    static func createMultipleMockPayslips() -> [PayslipItem] {
        return [
            PayslipItem(
                month: "April",
                year: 2024,
                credits: 6500.0,
                debits: 1690.0,
                dsop: 325.0,
                tax: 1300.0,
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            ),
            PayslipItem(
                month: "March",
                year: 2024,
                credits: 6100.0,
                debits: 1586.0,
                dsop: 305.0,
                tax: 1220.0,
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            )
        ]
    }

    /// Creates mock insights for testing
    static func createMockInsights() -> [InsightItem] {
        return [
            createMockInsightItem(title: "Income Growth", description: "Your income increased by 6.5%"),
            createMockInsightItem(title: "Tax Rate", description: "Your tax rate is 20%"),
            createMockInsightItem(title: "Savings Rate", description: "Your savings rate is 15%")
        ]
    }

    /// Creates a mock insight item
    static func createMockInsightItem(title: String, description: String) -> InsightItem {
        return InsightItem(
            title: title,
            description: description,
            iconName: "chart.bar.fill",
            color: .blue,
            detailItems: [],
            detailType: .monthlyIncomes
        )
    }
}
