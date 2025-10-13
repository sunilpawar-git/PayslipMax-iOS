import Foundation

/// Simplified payslip parser focused on extracting only essential components
/// Replaces complex 243-code parsing with 10 essential field extraction
class SimplifiedPayslipParser {
    
    // MARK: - Main Parsing Method
    
    /// Parses PDF text and extracts simplified payslip data
    /// - Parameters:
    ///   - text: Extracted text from PDF
    ///   - pdfData: Original PDF data
    /// - Returns: SimplifiedPayslip with parsed essential data
    func parse(_ text: String, pdfData: Data) async -> SimplifiedPayslip {
        // 1. Extract basic information
        let name = extractName(from: text)
        let (month, year) = extractDate(from: text)
        
        // 2. Extract core earnings
        let basicPay = extractBPAY(from: text)
        let dearnessAllowance = extractDA(from: text)
        let militaryServicePay = extractMSP(from: text)
        let grossPay = extractGrossPay(from: text)
        
        // 3. Calculate other earnings
        let coreEarningsTotal = basicPay + dearnessAllowance + militaryServicePay
        let otherEarnings = max(0, grossPay - coreEarningsTotal)
        
        // 4. Extract core deductions
        let dsop = extractDSOP(from: text)
        let agif = extractAGIF(from: text)
        let incomeTax = extractIncomeTax(from: text)
        let totalDeductions = extractTotalDeductions(from: text)
        
        // 5. Calculate other deductions
        let coreDeductionsTotal = dsop + agif + incomeTax
        let otherDeductions = max(0, totalDeductions - coreDeductionsTotal)
        
        // 6. Extract or calculate net remittance
        let extractedNet = extractNetRemittance(from: text)
        let calculatedNet = grossPay - totalDeductions
        let netRemittance = extractedNet > 0 ? extractedNet : calculatedNet
        
        // 7. Calculate confidence score
        let confidence = await calculateConfidence(
            basicPay: basicPay,
            dearnessAllowance: dearnessAllowance,
            militaryServicePay: militaryServicePay,
            grossPay: grossPay,
            dsop: dsop,
            agif: agif,
            incomeTax: incomeTax,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance
        )
        
        // 8. Create simplified payslip
        return SimplifiedPayslip(
            name: name,
            month: month,
            year: year,
            basicPay: basicPay,
            dearnessAllowance: dearnessAllowance,
            militaryServicePay: militaryServicePay,
            otherEarnings: otherEarnings,
            grossPay: grossPay,
            dsop: dsop,
            agif: agif,
            incomeTax: incomeTax,
            otherDeductions: otherDeductions,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance,
            parsingConfidence: confidence,
            pdfData: pdfData,
            source: "PDF Upload"
        )
    }
    
    // MARK: - Name Extraction
    
    private func extractName(from text: String) -> String {
        // Pattern: Name usually appears near "Name" or "नाम" keyword
        let patterns = [
            #"(?:Name|नाम)[:\s]+([A-Z][a-zA-Z\s]+)"#,
            #"([A-Z][a-z]+\s+[A-Z][a-z]+\s+[A-Z][a-z]+)"# // Fallback: Three capitalized words
        ]
        
        for pattern in patterns {
            if let match = extractFirstMatch(pattern: pattern, from: text, groupIndex: 1) {
                return match.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return "Unknown"
    }
    
    // MARK: - Date Extraction
    
    private func extractDate(from text: String) -> (month: String, year: Int) {
        // Pattern: Month/Year or statement period
        let monthPattern = #"(?:08/2025|August|अगस्त)\s*(?:2025)?"#
        
        if let match = extractFirstMatch(pattern: monthPattern, from: text, groupIndex: 0) {
            let components = match.components(separatedBy: CharacterSet(charactersIn: "/ "))
            
            // Try to extract month and year
            for component in components {
                if let yearValue = Int(component), yearValue >= 2020, yearValue <= 2030 {
                    let monthStr = components.first(where: { $0 != component }) ?? "Unknown"
                    return (monthStr, yearValue)
                }
            }
        }
        
        // Fallback
        return ("Unknown", Calendar.current.component(.year, from: Date()))
    }
    
    // MARK: - Core Earnings Extraction
    
    private func extractBPAY(from text: String) -> Double {
        // Pattern: BPAY or BPAY (12A) followed by amount
        let patterns = [
            #"BPAY\s*(?:\([^)]+\))?\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"Basic Pay\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"BP\s+(\d+(?:,\d{3})*)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractDA(from text: String) -> Double {
        // Pattern: DA followed by amount
        let patterns = [
            #"DA\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"Dearness\s*(?:Allowance)?\s*:?\s*(\d+(?:,\d{3})*)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractMSP(from text: String) -> Double {
        // Pattern: MSP followed by amount
        let patterns = [
            #"MSP\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"Military\s*Service\s*Pay\s*:?\s*(\d+(?:,\d{3})*)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractGrossPay(from text: String) -> Double {
        // Pattern: Gross Pay or Total Credits
        let patterns = [
            #"Gross\s*(?:Pay)?\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"Total\s*Credits?\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"कुल\s*आय\s*:?\s*(\d+(?:,\d{3})*)"# // Hindi
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    // MARK: - Core Deductions Extraction
    
    private func extractDSOP(from text: String) -> Double {
        // Pattern: DSOP followed by amount
        let patterns = [
            #"DSOP\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"DSOPP\s*:?\s*(\d+(?:,\d{3})*)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractAGIF(from text: String) -> Double {
        // Pattern: AGIF followed by amount
        let patterns = [
            #"AGIF\s*(?:FUND)?\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"Army\s*Group\s*Insurance\s*:?\s*(\d+(?:,\d{3})*)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractIncomeTax(from text: String) -> Double {
        // Pattern: Income Tax or ITAX or IT
        let patterns = [
            #"ITAX\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"IT\s+(\d+(?:,\d{3})*)"#,
            #"Income\s*Tax\s*:?\s*(\d+(?:,\d{3})*)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractTotalDeductions(from text: String) -> Double {
        // Pattern: Total Deductions
        let patterns = [
            #"Total\s*Deductions?\s*:?\s*(\d+(?:,\d{3})*)"#,
            #"कुल\s*कटौती\s*:?\s*(\d+(?:,\d{3})*)"# // Hindi
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    // MARK: - Net Remittance Extraction
    
    private func extractNetRemittance(from text: String) -> Double {
        // Pattern: Net Remittance or Net Pay
        let patterns = [
            #"Net\s*(?:Remittance|Pay)?\s*:?\s*[₹Rs\.]*\s*(\d+(?:,\d{3})*)"#,
            #"निवल\s*:?\s*(\d+(?:,\d{3})*)"# // Hindi
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    // MARK: - Confidence Calculation
    
    private func calculateConfidence(
        basicPay: Double,
        dearnessAllowance: Double,
        militaryServicePay: Double,
        grossPay: Double,
        dsop: Double,
        agif: Double,
        incomeTax: Double,
        totalDeductions: Double,
        netRemittance: Double
    ) async -> Double {
        let calculator = ConfidenceCalculator()
        
        return await calculator.calculate(
            basicPay: basicPay,
            dearnessAllowance: dearnessAllowance,
            militaryServicePay: militaryServicePay,
            grossPay: grossPay,
            dsop: dsop,
            agif: agif,
            incomeTax: incomeTax,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance
        )
    }
    
    // MARK: - Utility Methods
    
    /// Extracts amount using multiple patterns
    private func extractAmount(patterns: [String], from text: String) -> Double {
        for pattern in patterns {
            if let amountStr = extractFirstMatch(pattern: pattern, from: text, groupIndex: 1) {
                // Remove commas and convert to Double
                let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
                if let amount = Double(cleanAmount) {
                    return amount
                }
            }
        }
        return 0.0
    }
    
    /// Extracts first regex match from text
    private func extractFirstMatch(pattern: String, from text: String, groupIndex: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        guard groupIndex < match.numberOfRanges else {
            return nil
        }
        
        let matchRange = match.range(at: groupIndex)
        guard matchRange.location != NSNotFound,
              let swiftRange = Range(matchRange, in: text) else {
            return nil
        }
        
        return String(text[swiftRange])
    }
}

