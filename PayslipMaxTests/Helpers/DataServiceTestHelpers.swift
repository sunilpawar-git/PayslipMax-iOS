import XCTest
import SwiftData
@testable import PayslipMax

/// Helper methods for DataService tests
enum DataServiceTestHelpers {

    /// Creates a test payslip with the given parameters
    static func createTestPayslip(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double,
        name: String,
        accountNumber: String = "XXXX5678",
        panNumber: String = "ABCDE5678F",
        pdfData: Data = Data()
    ) -> PayslipItem {
        return PayslipItem(
            id: id,
            timestamp: timestamp,
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: pdfData
        )
    }
}

