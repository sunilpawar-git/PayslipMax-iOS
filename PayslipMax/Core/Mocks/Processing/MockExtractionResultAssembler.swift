import Foundation

/// Mock implementation of ExtractionResultAssemblerProtocol for testing purposes.
class MockExtractionResultAssembler: ExtractionResultAssemblerProtocol {
    
    /// Controls whether the mock should simulate successful assembly or throw an error
    var shouldSucceed: Bool = true
    
    /// The error to throw when shouldSucceed is false
    var errorToThrow: Error = ModularExtractionError.insufficientData
    
    /// Tracks the last data passed to assemblePayslipItem
    var lastAssembledData: [String: String] = [:]
    
    /// Tracks the last PDF data passed to assemblePayslipItem
    var lastPDFData: Data?
    
    /// Number of times assemblePayslipItem was called
    var assembleCallCount = 0
    
    /// Assembles a PayslipItem from extracted data and PDF data.
    /// - Parameters:
    ///   - data: Dictionary of extracted key-value pairs
    ///   - pdfData: Raw PDF data to include in the PayslipItem
    /// - Returns: A configured PayslipItem
    /// - Throws: ModularExtractionError if shouldSucceed is false
    func assemblePayslipItem(from data: [String: String], pdfData: Data) throws -> PayslipItem {
        assembleCallCount += 1
        lastAssembledData = data
        lastPDFData = pdfData
        
        guard shouldSucceed else {
            throw errorToThrow
        }
        
        // Create a mock PayslipItem with realistic test data
        let month = data["month"] ?? "January"
        let year = Int(data["year"] ?? "2024") ?? 2024
        let name = data["name"] ?? "Test User"
        let credits = Double(data["credits"]?.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression) ?? "50000") ?? 50000
        let debits = Double(data["debits"]?.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression) ?? "10000") ?? 10000
        let tax = Double(data["tax"]?.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression) ?? "5000") ?? 5000
        let dsop = Double(data["dsop"]?.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression) ?? "2000") ?? 2000
        
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: data["account_number"] ?? "123456789",
            panNumber: data["pan_number"] ?? "ABCDE1234F",
            pdfData: pdfData
        )
        
        // Add mock earnings and deductions
        payslip.earnings = ["Basic Pay": credits * 0.6, "Allowances": credits * 0.4]
        payslip.deductions = ["Tax": tax, "DSOP": dsop, "Other": debits - tax - dsop]
        
        return payslip
    }
    
    /// Resets the mock to its initial state
    func reset() {
        shouldSucceed = true
        errorToThrow = ModularExtractionError.insufficientData
        lastAssembledData = [:]
        lastPDFData = nil
        assembleCallCount = 0
    }
}