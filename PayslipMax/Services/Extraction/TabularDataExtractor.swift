import Foundation

/// Handles extraction of tabular data structures from payslip text.
///
/// This component focuses on parsing structured tabular data within payslips,
/// particularly for financial information laid out in table format. It was
/// extracted from PatternMatcher to achieve better separation of concerns
/// and comply with the 300-line limit rule.
///
/// ## Single Responsibility
/// The TabularDataExtractor has one clear responsibility: parsing text that
/// contains structured tabular data and extracting financial values organized
/// by earnings and deductions categories.
///
/// ## Extraction Strategy
/// The class recognizes common tabular patterns in payslip documents:
/// - Code-value pairs arranged in columns
/// - Formatted currency amounts
/// - Categorization into earnings vs deductions
class TabularDataExtractor: TabularDataExtractorProtocol {
    
    // MARK: - Categorization Methods
    
    /// Extracts tabular structure from text and categorizes financial data.
    ///
    /// This method parses text that contains financial data in a tabular format,
    /// extracting code-value pairs and categorizing them as either earnings or deductions.
    /// It handles various formatting styles commonly found in payslip documents.
    ///
    /// - Parameters:
    ///   - text: The input text containing tabular financial data
    ///   - earnings: An inout dictionary to collect earnings data
    ///   - deductions: An inout dictionary to collect deductions data
    func extractTabularStructure(from text: String, into earnings: inout [String: Double], and deductions: inout [String: Double]) {
        // Look for tabular patterns: Code Amount Code Amount
        let tabularPattern = "([A-Z]{2,6})\\s+([\\d,]+\\.?\\d*)\\s+([A-Z]{2,6})\\s+([\\d,]+\\.?\\d*)"
        let tabularRegex = try? NSRegularExpression(pattern: tabularPattern, options: [])
        let tabularMatches = tabularRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []
        
        for match in tabularMatches {
            // First code-amount pair
            if match.numberOfRanges >= 3 {
                let codeRange1 = match.range(at: 1)
                let amountRange1 = match.range(at: 2)
                
                if let codeSubstring1 = Range(codeRange1, in: text),
                   let amountSubstring1 = Range(amountRange1, in: text) {
                    let code1 = String(text[codeSubstring1])
                    let amountStr1 = String(text[amountSubstring1]).replacingOccurrences(of: ",", with: "")
                    
                    if let amount1 = Double(amountStr1), !shouldExcludeCode(code1) {
                        if isEarningsCode(code1) {
                            earnings[code1] = amount1
                        } else if isDeductionCode(code1) {
                            deductions[code1] = amount1
                        }
                    }
                }
            }
            
            // Second code-amount pair
            if match.numberOfRanges >= 5 {
                let codeRange2 = match.range(at: 3)
                let amountRange2 = match.range(at: 4)
                
                if let codeSubstring2 = Range(codeRange2, in: text),
                   let amountSubstring2 = Range(amountRange2, in: text) {
                    let code2 = String(text[codeSubstring2])
                    let amountStr2 = String(text[amountSubstring2]).replacingOccurrences(of: ",", with: "")
                    
                    if let amount2 = Double(amountStr2), !shouldExcludeCode(code2) {
                        if isEarningsCode(code2) {
                            earnings[code2] = amount2
                        } else if isDeductionCode(code2) {
                            deductions[code2] = amount2
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Private Categorization Methods
    
    /// Determines if a code should be excluded from extraction results.
    ///
    /// This method filters out codes that are not meaningful financial data,
    /// such as formatting artifacts, headers, or non-financial identifiers.
    ///
    /// - Parameter code: The financial code to evaluate
    /// - Returns: True if the code should be excluded, false otherwise
    private func shouldExcludeCode(_ code: String) -> Bool {
        let excludedCodes = ["TOTAL", "GROSS", "NET", "CURR", "PREV", "YTD", "DATE", "PAGE"]
        return excludedCodes.contains(code.uppercased())
    }
    
    /// Determines if a financial code represents earnings/income.
    ///
    /// This method categorizes financial codes based on common military and
    /// civilian payslip patterns, identifying codes that typically represent
    /// income or earnings components.
    ///
    /// - Parameter code: The financial code to categorize
    /// - Returns: True if the code represents earnings, false otherwise
    private func isEarningsCode(_ code: String) -> Bool {
        let earningsCodes = ["BP", "BPAY", "DA", "MSP", "HRA", "CCA", "TA", "MEDICAL", "UNIFORM"]
        return earningsCodes.contains(code.uppercased())
    }
    
    /// Determines if a financial code represents deductions.
    ///
    /// This method categorizes financial codes based on common military and
    /// civilian payslip patterns, identifying codes that typically represent
    /// deductions or expenses.
    ///
    /// - Parameter code: The financial code to categorize
    /// - Returns: True if the code represents deductions, false otherwise
    private func isDeductionCode(_ code: String) -> Bool {
        let deductionCodes = ["DSOP", "AGIF", "ITAX", "TDS", "INS", "LOAN", "ADVANCE", "PF", "ESI"]
        return deductionCodes.contains(code.uppercased())
    }
}
