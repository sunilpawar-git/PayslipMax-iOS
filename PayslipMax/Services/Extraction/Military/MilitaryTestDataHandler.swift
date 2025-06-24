import Foundation

/// Protocol for military test data handling services
protocol MilitaryTestDataHandlerProtocol {
    func createTestPayslipItem(from text: String, pdfData: Data?) -> PayslipItem
    func isTestData(_ text: String) -> Bool
}

/// Service responsible for handling test data scenarios in military payslip extraction
///
/// This service provides specialized handling for test cases and debugging scenarios,
/// allowing developers to create controlled test environments with known data values.
class MilitaryTestDataHandler: MilitaryTestDataHandlerProtocol {
    
    // MARK: - Public Methods
    
    /// Checks if the provided text contains test data markers
    ///
    /// - Parameter text: The text content to check
    /// - Returns: `true` if the text contains test case markers, `false` otherwise
    func isTestData(_ text: String) -> Bool {
        return text.contains("#TEST_CASE#")
    }
    
    /// Creates a test payslip item for testing and debugging purposes.
    ///
    /// This specialized method generates a test `PayslipItem` by parsing specially formatted markers
    /// in the input text. It supports a flexible key-value format that allows testers to specify
    /// exactly which values should be used for testing particular scenarios or edge cases.
    ///
    /// ## Test Marker Format
    /// The method recognizes markers in the format `#KEY:VALUE#`, where:
    /// - `KEY` is an uppercase identifier (e.g., `NAME`, `MONTH`, `CREDITS`)
    /// - `VALUE` is the desired test value (e.g., `Test Officer`, `January`, `50000`)
    ///
    /// ## Supported Test Keys
    /// - **Basic Fields**: `NAME`, `MONTH`, `YEAR`, `ACCOUNT`, `PAN`
    /// - **Financial Totals**: `CREDITS`, `DEBITS`, `TAX`, `DSOP`
    /// - **Earnings Components**: Any key prefixed with `EARN_` (e.g., `EARN_Basic Pay`)
    /// - **Deductions Components**: Any key prefixed with `DED_` (e.g., `DED_ITAX`)
    ///
    /// ## Example Test String
    /// ```
    /// #TEST_CASE##NAME:Capt. John Smith##MONTH:June##YEAR:2024##CREDITS:75000##DEBITS:22500##EARN_Basic Pay:45000##EARN_MSP:15000##DED_DSOP:7500#
    /// ```
    ///
    /// This method is intended solely for testing purposes, particularly for:
    /// - Unit testing extraction logic
    /// - Validating financial calculations
    /// - Testing edge cases and unusual payslip formats
    /// - Debugging extraction issues with controlled inputs
    ///
    /// - Parameters:
    ///   - text: The text content containing test data markers (e.g., from a test file or string).
    ///   - pdfData: Optional raw PDF data to associate with the test payslip.
    /// - Returns: A `PayslipItem` populated with values extracted from the test markers or defaults.
    func createTestPayslipItem(from text: String, pdfData: Data?) -> PayslipItem {
        // Extract test values from the text using simple key-value format
        var testValues: [String: String] = [:]
        
        // Find test data markers in format #KEY:VALUE#
        let pattern = "#([A-Z_]+):(.*?)#"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            
            for match in matches {
                if match.numberOfRanges >= 3 {
                    let keyRange = match.range(at: 1)
                    let valueRange = match.range(at: 2)
                    
                    let key = nsText.substring(with: keyRange)
                    let value = nsText.substring(with: valueRange)
                    
                    testValues[key] = value
                }
            }
        }
        
        // Extract or use default values
        let name = testValues["NAME"] ?? "Test Military Officer"
        let month = testValues["MONTH"] ?? getCurrentMonth()
        let yearStr = testValues["YEAR"] ?? String(getCurrentYear())
        let accountNumber = testValues["ACCOUNT"] ?? "MILITARY123456789"
        
        // Convert numeric values
        let credits = Double(testValues["CREDITS"] ?? "50000") ?? 50000.0
        let debits = Double(testValues["DEBITS"] ?? "15000") ?? 15000.0
        let tax = Double(testValues["TAX"] ?? "8000") ?? 8000.0
        let dsop = Double(testValues["DSOP"] ?? "5000") ?? 5000.0
        let year = Int(yearStr) ?? getCurrentYear()
        
        // Create test earnings and deductions
        var earnings: [String: Double] = [
            "Basic Pay": credits * 0.6,
            "Allowances": credits * 0.4
        ]
        
        var deductions: [String: Double] = [
            "ITAX": tax,
            "DSOP": dsop,
            "Other": debits - tax - dsop
        ]
        
        // Override with any specific earnings or deductions
        for (key, value) in testValues {
            if key.starts(with: "EARN_") {
                let earningName = String(key.dropFirst(5))
                if let amount = Double(value) {
                    earnings[earningName] = amount
                }
            } else if key.starts(with: "DED_") {
                let deductionName = String(key.dropFirst(4))
                if let amount = Double(value) {
                    deductions[deductionName] = amount
                }
            }
        }
        
        // Create the payslip item
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
            accountNumber: accountNumber,
            panNumber: testValues["PAN"] ?? "",
            pdfData: pdfData ?? Data()
        )
        
        // Set earnings and deductions
        payslip.earnings = earnings
        payslip.deductions = deductions
        
        return payslip
    }
    
    // MARK: - Private Helper Methods
    
    /// Returns the full name of the current month (e.g., "January", "February").
    private func getCurrentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    /// Returns the current year as an integer.
    private func getCurrentYear() -> Int {
        return Calendar.current.component(.year, from: Date())
    }
} 