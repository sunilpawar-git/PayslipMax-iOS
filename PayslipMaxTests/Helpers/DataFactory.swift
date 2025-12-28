import Foundation
@testable import PayslipMax

/// Protocol for generating test data objects
protocol DataFactoryProtocol {
    /// Creates a standard sample PayslipItem for testing using parameter struct
    func createPayslipItem(params: PayslipItemParams) -> PayslipItem

    /// Creates a collection of sample payslips spanning multiple months
    func createPayslipItems(count: Int) -> [PayslipItem]

    /// Creates a PayslipItem that represents an edge case
    func createEdgeCasePayslipItem(type: EdgeCaseType) -> PayslipItem
}

/// Factory for creating test data objects
class DataFactory: DataFactoryProtocol {

    // MARK: - DataFactoryProtocol Implementation

    func createPayslipItem(params: PayslipItemParams = .default) -> PayslipItem {
        return PayslipItem(
            id: params.id,
            month: params.month,
            year: params.year,
            credits: params.credits,
            debits: params.debits,
            dsop: params.dsop,
            tax: params.tax,
            name: params.name,
            accountNumber: params.accountNumber,
            panNumber: params.panNumber
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
        let base = PayslipItemParams.default
        switch type {
        case .zeroValues:
            let params = PayslipItemParams(
                id: base.id, month: base.month, year: base.year,
                credits: 0, debits: 0, dsop: 0, tax: 0,
                name: base.name, accountNumber: base.accountNumber, panNumber: base.panNumber
            )
            return createPayslipItem(params: params)

        case .negativeBalance:
            let params = PayslipItemParams(
                id: base.id, month: base.month, year: base.year,
                credits: 1000, debits: 1500, dsop: 300, tax: 200,
                name: base.name, accountNumber: base.accountNumber, panNumber: base.panNumber
            )
            return createPayslipItem(params: params)

        case .veryLargeValues:
            let params = PayslipItemParams(
                id: base.id, month: base.month, year: base.year,
                credits: 1_000_000, debits: 300_000, dsop: 50_000, tax: 150_000,
                name: base.name, accountNumber: base.accountNumber, panNumber: base.panNumber
            )
            return createPayslipItem(params: params)

        case .decimalPrecision:
            let params = PayslipItemParams(
                id: base.id, month: base.month, year: base.year,
                credits: 5000.75, debits: 1000.25, dsop: 300.50, tax: 800.33,
                name: base.name, accountNumber: base.accountNumber, panNumber: base.panNumber
            )
            return createPayslipItem(params: params)

        case .specialCharacters:
            let params = PayslipItemParams(
                id: base.id, month: base.month, year: base.year,
                credits: base.credits, debits: base.debits, dsop: base.dsop, tax: base.tax,
                name: "O'Connor-Smith, Jr.", accountNumber: "XXXX-1234/56", panNumber: "ABCDE1234F&"
            )
            return createPayslipItem(params: params)
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
