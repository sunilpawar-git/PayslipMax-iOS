import Foundation
import PDFKit

/// Factory for creating PayslipItem instances
class PayslipItemFactory: PayslipItemFactoryProtocol {
    
    /// Creates an empty payslip item
    /// - Returns: An empty PayslipItem
    static func createEmpty() -> AnyPayslip {
        return PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "",
            year: 0,
            credits: 0,
            debits: 0,
            dsop: 0,
            tax: 0,
            name: "",
            accountNumber: "",
            panNumber: ""
        )
    }
    
    /// Creates a sample payslip item for testing or preview
    /// - Returns: A sample PayslipItem
    static func createSample() -> AnyPayslip {
        return PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2023,
            credits: 50000,
            debits: 15000,
            dsop: 5000,
            tax: 3000,
            earnings: ["Basic Pay": 35000, "Allowances": 15000],
            deductions: ["Pension": 5000, "Insurance": 2000, "Other": 8000],
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            isSample: true,
            source: "System Generated",
            status: "Demo"
        )
    }
    
    /// Creates a sample payslip item with PDF data
    /// - Parameter pdfData: PDF data to include
    /// - Returns: A sample PayslipItem with PDF data
    static func createSampleWithPDF(pdfData: Data) -> AnyPayslip {
        return PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2023,
            credits: 50000,
            debits: 15000,
            dsop: 5000,
            tax: 3000,
            earnings: ["Basic Pay": 35000, "Allowances": 15000],
            deductions: ["Pension": 5000, "Insurance": 2000, "Other": 8000],
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            pdfData: pdfData,
            isSample: true,
            source: "PDF Import",
            status: "Demo"
        )
    }
} 