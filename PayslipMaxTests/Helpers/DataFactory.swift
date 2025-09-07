import Foundation
@testable import PayslipMax

/// Protocol for generating test data objects
protocol DataFactoryProtocol {
    /// Creates a standard sample PayslipItem for testing
    func createPayslipItem(
        id: UUID,
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double,
        name: String,
        accountNumber: String,
        panNumber: String
    ) -> PayslipItem

    /// Creates a collection of sample payslips spanning multiple months
    func createPayslipItems(count: Int) -> [PayslipItem]

    /// Creates a PayslipItem that represents an edge case
    func createEdgeCasePayslipItem(type: EdgeCaseType) -> PayslipItem
}

/// Factory for creating test data objects
class DataFactory: DataFactoryProtocol {

    // MARK: - DataFactoryProtocol Implementation

    func createPayslipItem(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0,
        name: String = "John Doe",
        accountNumber: String = "XXXX1234",
        panNumber: String = "ABCDE1234F"
    ) -> PayslipItem {
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber
        )
    }

    func createPayslipItems(count: Int = 12) -> [PayslipItem] {
        let months = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]

        return (0..<count).map { index in
            let monthIndex = index % 12
            let yearOffset = index / 12

            return PayslipItem(
                month: months[monthIndex],
                year: 2023 + yearOffset,
                credits: Double.random(in: 4000...6000),
                debits: Double.random(in: 800...1200),
                dsop: Double.random(in: 200...400),
                tax: Double.random(in: 600...1000),
                name: "John Doe",
                accountNumber: "XXXX1234",
                panNumber: "ABCDE1234F"
            )
        }
    }

    func createEdgeCasePayslipItem(type: EdgeCaseType) -> PayslipItem {
        switch type {
        case .zeroValues:
            return createPayslipItem(credits: 0, debits: 0, dsop: 0, tax: 0)

        case .negativeBalance:
            return createPayslipItem(credits: 1000, debits: 1500, dsop: 300, tax: 200)

        case .veryLargeValues:
            return createPayslipItem(credits: 1_000_000, debits: 300_000, dsop: 50_000, tax: 150_000)

        case .decimalPrecision:
            return createPayslipItem(credits: 5000.75, debits: 1000.25, dsop: 300.50, tax: 800.33)

        case .specialCharacters:
            return createPayslipItem(
                name: "O'Connor-Smith, Jr.",
                accountNumber: "XXXX-1234/56",
                panNumber: "ABCDE1234F&"
            )
        }
    }
}

/// Edge case types for test data generation
enum EdgeCaseType {
    case zeroValues
    case negativeBalance
    case veryLargeValues
    case decimalPrecision
    case specialCharacters
}
