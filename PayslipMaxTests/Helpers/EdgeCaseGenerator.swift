import Foundation
@testable import PayslipMax

/// Protocol for edge case payslip generation operations
protocol EdgeCaseGeneratorProtocol {
    /// Creates a payslip with anomalies for testing edge cases
    static func anomalousPayslip(anomalyType: AnomalyType) -> PayslipItem
}

/// A generator for edge case payslip-related test data
class EdgeCaseGenerator: EdgeCaseGeneratorProtocol {

    // MARK: - Anomalous Data Generation

    /// Creates a payslip with anomalies for testing edge cases
    static func anomalousPayslip(anomalyType: AnomalyType) -> PayslipItem {
        switch anomalyType {
        case .negativeValues:
            return PayslipItem(
                month: "February",
                year: 2023,
                credits: 5000.0,
                debits: -200.0,  // Negative debit (unusual)
                dsop: 300.0,
                tax: 800.0,
                name: "Anomaly Test",
                accountNumber: "XXXX9999",
                panNumber: "AAAAA9999A"
            )

        case .excessiveValues:
            return PayslipItem(
                month: "March",
                year: 2023,
                credits: 9999999.0,  // Unusually high value
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "Excessive Value",
                accountNumber: "XXXX8888",
                panNumber: "BBBBB8888B"
            )

        case .specialCharacters:
            return PayslipItem(
                month: "April",
                year: 2023,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "Spécïal Ch@r$",  // Special characters
                accountNumber: "XXXX-7777",
                panNumber: "CCCCC7777C"
            )

        case .missingFields:
            return PayslipItem(
                month: "",  // Empty month
                year: 2023,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "Missing Fields",
                accountNumber: "",  // Empty account number
                panNumber: ""  // Empty PAN
            )
        }
    }
}

/// Types of anomalies for generating edge cases
enum AnomalyType {
    case negativeValues
    case excessiveValues
    case specialCharacters
    case missingFields
}
