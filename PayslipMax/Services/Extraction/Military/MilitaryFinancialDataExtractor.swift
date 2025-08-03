import Foundation

/// Protocol for military financial data extraction services
protocol MilitaryFinancialDataExtractorProtocol {
    func extractMilitaryTabularData(from text: String) -> ([String: Double], [String: Double])
}

/// Service responsible for extracting financial data from military payslips
///
/// This service handles the complex task of extracting earnings and deductions from
/// military payslip formats, particularly PCDA (Principal Controller of Defence Accounts)
/// format which uses specific coding patterns and tabular data layouts.
class MilitaryFinancialDataExtractor: MilitaryFinancialDataExtractorProtocol {
    
    // MARK: - Constants
    
    /// Known earning codes in military payslips
    private let earningCodes = Set([
        "BPAY", "DA", "DP", "HRA", "TA", "MISC", "CEA", "TPT", 
        "WASHIA", "OUTFITA", "MSP", "ARR-RSHNA", "RSHNA", 
        "RH12", "TPTA", "TPTADA"
    ])
    
    /// Known deduction codes in military payslips
    private let deductionCodes = Set([
        "DSOP", "AGIF", "ITAX", "IT", "SBI", "PLI", "AFNB", 
        "AOBA", "PLIA", "HOSP", "CDA", "CGEIS", "DEDN"
    ])
    
    // MARK: - Public Methods
    
    /// Extracts structured earnings and deductions data from military payslip text.
    ///
    /// This method performs sophisticated pattern matching to extract financial components
    /// from military payslips, particularly those following PCDA (Principal Controller of
    /// Defence Accounts) formatting standards.
    ///
    /// ## Military Payslip Format Recognition
    ///
    /// The method specifically handles:
    /// - **PCDA Format**: Standard format used by Indian Armed Forces
    /// - **Two-column layouts**: `BPAY 123456.00 DSOP 12345.00`
    /// - **Single-column layouts**: `ITAX 5000.00`
    /// - **Summary sections**: Total deductions, gross pay, net remittance
    ///
    /// ## Extraction Process
    ///
    /// 1. **Format Detection**: Identifies PCDA or military-specific markers
    /// 2. **Pattern Matching**: Uses regex to extract code-value pairs
    /// 3. **Classification**: Categorizes codes as earnings or deductions using known military codes
    /// 4. **Validation**: Cross-references totals with explicit gross/net amounts
    /// 5. **Reconciliation**: Adjusts for discrepancies between calculated and stated totals
    ///
    /// The method handles common OCR irregularities and format variations while maintaining
    /// accuracy in financial data extraction.
    ///
    /// - Parameter text: The complete payslip text content.
    /// - Returns: A tuple containing:
    ///   - The first dictionary maps earning component names (String) to their amounts (Double)
    ///   - The second dictionary maps deduction component names (String) to their amounts (Double)
    func extractMilitaryTabularData(from text: String) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        print("MilitaryFinancialDataExtractor: Starting tabular data extraction from \(text.count) characters")
        
        // Check for PCDA format
        if text.contains("PCDA") || text.contains("Principal Controller of Defence Accounts") {
            print("MilitaryFinancialDataExtractor: Detected PCDA format for tabular data extraction")
            
            // Extract using PCDA patterns
            extractPCDATabularData(from: text, earnings: &earnings, deductions: &deductions)
            
            // Process total reconciliation
            reconcileTotals(from: text, earnings: &earnings, deductions: &deductions)
        } else {
            print("MilitaryFinancialDataExtractor: PCDA format not detected in text")
            print("MilitaryFinancialDataExtractor: Text preview: \(String(text.prefix(200)))")
        }
        
        print("MilitaryFinancialDataExtractor: Final result - earnings: \(earnings.count), deductions: \(deductions.count)")
        return (earnings, deductions)
    }
    
    // MARK: - Private Methods
    
    /// Extracts financial data using PCDA-specific patterns
    private func extractPCDATabularData(from text: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        // Check for structured Credit/Debit table format (ALL payslips prior to November 2023)
        // This covers various historical formats including pre-2020, 2020-2022, and 2023 formats
        if (text.uppercased().contains("CREDIT") && text.uppercased().contains("DEBIT")) ||
           text.contains("Amount in INR") ||
           (text.contains("Basic Pay") && text.contains("DSOPF")) ||
           (text.contains("Cr.") && text.contains("Dr.")) ||  // Alternative format used in older payslips
           (text.contains("Credits") && text.contains("Debits")) ||  // Plural format
           (text.uppercased().contains("EARNINGS") && text.uppercased().contains("DEDUCTIONS")) ||  // Alternative naming
           text.contains("STATEMENT OF ACCOUNT") ||  // Common in older PCDA formats
           (text.contains("PCDA") && text.contains("TABLE")) {  // Explicit PCDA table format
            print("MilitaryFinancialDataExtractor: Detected structured Credit/Debit table format")
            let parser = PCDATableParser()
            let (parsedEarnings, parsedDeductions) = parser.extractTableData(from: text)
            earnings.merge(parsedEarnings) { _, new in new }
            deductions.merge(parsedDeductions) { _, new in new }
            return
        }
        
        // Define patterns for earnings and deductions
        // PCDA format typically has patterns like:
        // BPAY      123456.00     DSOP       12345.00
        
        // Match lines with two columns of data
        let twoColumnPattern = "([A-Z]+)\\s+(\\d+(?:\\.\\d+)?)\\s+([A-Z]+)\\s+(\\d+(?:\\.\\d+)?)"
        // Match lines with one column of data  
        let oneColumnPattern = "([A-Z]+)\\s+(\\d+(?:\\.\\d+)?)"
        
        // Process two-column data (earnings and deductions on same line)
        extractTwoColumnData(from: text, pattern: twoColumnPattern, earnings: &earnings, deductions: &deductions)
        
        // Process one-column data
        extractOneColumnData(from: text, pattern: oneColumnPattern, earnings: &earnings, deductions: &deductions)
    }


    

    
    /// Extracts data from two-column format lines
    private func extractTwoColumnData(from text: String, pattern: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.numberOfRanges >= 5 {
                // First code-value pair
                let code1Range = match.range(at: 1)
                let value1Range = match.range(at: 2)
                
                // Second code-value pair
                let code2Range = match.range(at: 3)
                let value2Range = match.range(at: 4)
                
                let code1 = nsText.substring(with: code1Range)
                let code2 = nsText.substring(with: code2Range)
                
                let value1Str = nsText.substring(with: value1Range)
                let value2Str = nsText.substring(with: value2Range)
                
                // Convert values to doubles
                let value1 = Double(value1Str) ?? 0.0
                let value2 = Double(value2Str) ?? 0.0
                
                // Categorize as earnings or deductions based on known codes
                categorizeFinancialData(code: code1, value: value1, earnings: &earnings, deductions: &deductions)
                categorizeFinancialData(code: code2, value: value2, earnings: &earnings, deductions: &deductions)
            }
        }
    }
    
    /// Extracts data from single-column format lines
    private func extractOneColumnData(from text: String, pattern: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let codeRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let code = nsText.substring(with: codeRange)
                let valueStr = nsText.substring(with: valueRange)
                let value = Double(valueStr) ?? 0.0
                
                // Categorize as earnings or deductions based on known codes
                categorizeFinancialData(code: code, value: value, earnings: &earnings, deductions: &deductions)
            }
        }
    }
    
    /// Categorizes financial codes as earnings or deductions
    private func categorizeFinancialData(code: String, value: Double, earnings: inout [String: Double], deductions: inout [String: Double]) {
        if earningCodes.contains(code) {
            earnings[code] = value
        } else if deductionCodes.contains(code) {
            deductions[code] = value
        }
    }
    
    /// Reconciles extracted data with explicit totals found in the document
    private func reconcileTotals(from text: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        // Process total deductions
        reconcileTotalDeductions(from: text, deductions: &deductions)
        
        // Process net remittance calculations
        reconcileNetRemittance(from: text, earnings: &earnings, deductions: deductions)
        
        // Process explicit gross pay
        reconcileGrossPay(from: text, earnings: &earnings)
    }
    
    /// Reconciles total deductions with individual deduction items
    private func reconcileTotalDeductions(from text: String, deductions: inout [String: Double]) {
        let totalDeductionPatterns = [
            "Total Deductions\\s+(\\d+\\.\\d+)",
            "Gross Deductions\\s+(\\d+\\.\\d+)"
        ]
        
        for pattern in totalDeductionPatterns {
            if let totalDeductions = extractNumericValue(from: text, pattern: pattern) {
                let calculatedTotal = deductions.values.reduce(0, +)
                if abs(totalDeductions - calculatedTotal) > 1.0 && deductions.count > 0 {
                    // If there's a mismatch, add an "Other" category for the difference
                    deductions["OTHER"] = totalDeductions - calculatedTotal
                }
            }
        }
    }
    
    /// Reconciles net remittance with calculated values
    private func reconcileNetRemittance(from text: String, earnings: inout [String: Double], deductions: [String: Double]) {
        let netAmountPatterns = [
            "Net Remittance\\s+(\\d+\\.\\d+)",
            "Net Amount\\s+(\\d+\\.\\d+)",
            "Net Payable\\s+(\\d+\\.\\d+)"
        ]
        
        for pattern in netAmountPatterns {
            if let netAmount = extractNumericValue(from: text, pattern: pattern) {
                let totalDeductions = deductions.values.reduce(0, +)
                let grossPay = netAmount + totalDeductions
                
                if earnings.isEmpty {
                    earnings["GROSS PAY"] = grossPay
                } else {
                    let calculatedTotal = earnings.values.reduce(0, +)
                    if abs(grossPay - calculatedTotal) > 1.0 {
                        adjustEarningsForGrossPay(grossPay: grossPay, calculatedTotal: calculatedTotal, earnings: &earnings)
                    }
                }
                break
            }
        }
    }
    
    /// Reconciles explicit gross pay with calculated earnings
    private func reconcileGrossPay(from text: String, earnings: inout [String: Double]) {
        let grossPayPatterns = [
            "Gross Pay\\s+(\\d+\\.\\d+)",
            "Gross Earnings\\s+(\\d+\\.\\d+)",
            "Total Earnings\\s+(\\d+\\.\\d+)"
        ]
        
        for pattern in grossPayPatterns {
            if let grossPay = extractNumericValue(from: text, pattern: pattern) {
                if earnings.isEmpty {
                    earnings["GROSS PAY"] = grossPay
                } else {
                    let calculatedTotal = earnings.values.reduce(0, +)
                    if abs(grossPay - calculatedTotal) > 1.0 {
                        adjustEarningsForGrossPay(grossPay: grossPay, calculatedTotal: calculatedTotal, earnings: &earnings)
                    }
                }
                break
            }
        }
    }
    
    /// Adjusts earnings to match explicit gross pay
    private func adjustEarningsForGrossPay(grossPay: Double, calculatedTotal: Double, earnings: inout [String: Double]) {
        if calculatedTotal == 0 {
            earnings["GROSS PAY"] = grossPay
        } else if calculatedTotal < grossPay {
            // Add an "Other" category for the difference
            earnings["OTHER"] = grossPay - calculatedTotal
        } else {
            // Adjust the largest earning component to make the total match
            if let (key, value) = earnings.max(by: { $0.value < $1.value }) {
                let adjustment = grossPay - calculatedTotal
                earnings[key] = value + adjustment
            }
        }
    }
    
    /// Extracts a numeric value using a regex pattern
    private func extractNumericValue(from text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
              match.numberOfRanges > 1 else {
            return nil
        }
        
        let range = match.range(at: 1)
        guard range.location != NSNotFound,
              let range = Range(range, in: text) else {
            return nil
        }
        
        let valueStr = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(valueStr)
    }
    
} 