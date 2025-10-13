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
        // Pattern: Name usually appears after "Name" or "नाम" keyword
        // Handle both Hindi and English text, extract only English name
        let patterns = [
            // Pattern 1: नाम/Name: followed by English name (allowing Hindi text in between)
            #"(?:नाम/Name|Name/नाम|Name|नाम)\s*[:/]\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})"#,
            // Pattern 2: Just look for the pattern with English name after Name keyword (more flexible)
            #"(?:Name|नाम)[^A-Z]{0,20}([A-Z][a-z]+\s+[A-Z][a-z]+\s+[A-Z][a-z]+)"#,
            // Pattern 3: Fallback - any three capitalized words (must not be common headers)
            #"([A-Z][a-z]+\s+[A-Z][a-z]+\s+[A-Z][a-z]+)"#
        ]
        
        // Common headers/words to exclude
        let excludedPhrases = ["Principal Controller", "Controller Of", "Defence Accounts", 
                               "Ministry Of", "Government Of", "Statement Period",
                               "Pay Slip", "Slip For", "For The"]
        
        for pattern in patterns {
            if let match = extractFirstMatch(pattern: pattern, from: text, groupIndex: 1) {
                let cleaned = match
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                
                // Additional validation: ensure it's only English letters and spaces
                let validName = cleaned.components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty && $0.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil }
                    .joined(separator: " ")
                
                // Check if it's a valid name (not a header phrase)
                let isExcluded = excludedPhrases.contains { excluded in
                    validName.localizedCaseInsensitiveContains(excluded)
                }
                
                if validName.count >= 3 && !isExcluded {
                    return validName
                }
            }
        }
        
        return "Unknown"
    }
    
    // MARK: - Date Extraction
    
    private func extractDate(from text: String) -> (month: String, year: Int) {
        // Pattern: Month/Year in various formats
        let patterns = [
            #"(\d{2})/(\d{4})"#, // 08/2025 format
            #"(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\s+(\d{4})"#,
            #"(जनवरी|फरवरी|मार्च|अप्रैल|मई|जून|जुलाई|अगस्त|सितंबर|अक्टूबर|नवंबर|दिसंबर)\s+(\d{4})"# // Hindi months
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges >= 3 {
                
                if let monthRange = Range(match.range(at: 1), in: text),
                   let yearRange = Range(match.range(at: 2), in: text) {
                    
                    let monthStr = String(text[monthRange])
                    let yearStr = String(text[yearRange])
                    
                    if let year = Int(yearStr), year >= 2020, year <= 2030 {
                        // Convert numeric month to name
                        let monthName = convertToMonthName(monthStr)
                        return (monthName, year)
                    }
                }
            }
        }
        
        // Fallback
        return ("Unknown", Calendar.current.component(.year, from: Date()))
    }
    
    /// Converts month string (numeric or name) to abbreviated month name
    private func convertToMonthName(_ input: String) -> String {
        // If numeric (01-12), convert to month name
        if let monthNumber = Int(input), monthNumber >= 1, monthNumber <= 12 {
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            return months[monthNumber - 1]
        }
        
        // If already a month name, abbreviate if needed
        let monthMapping: [String: String] = [
            "JANUARY": "Jan", "FEBRUARY": "Feb", "MARCH": "Mar",
            "APRIL": "Apr", "MAY": "May", "JUNE": "Jun",
            "JULY": "Jul", "AUGUST": "Aug", "SEPTEMBER": "Sep",
            "OCTOBER": "Oct", "NOVEMBER": "Nov", "DECEMBER": "Dec",
            "जनवरी": "Jan", "फरवरी": "Feb", "मार्च": "Mar",
            "अप्रैल": "Apr", "मई": "May", "जून": "Jun",
            "जुलाई": "Jul", "अगस्त": "Aug", "सितंबर": "Sep",
            "अक्टूबर": "Oct", "नवंबर": "Nov", "दिसंबर": "Dec"
        ]
        
        return monthMapping[input.uppercased()] ?? input
    }
    
    // MARK: - Core Earnings Extraction
    
    private func extractBPAY(from text: String) -> Double {
        // Pattern: BPAY or BPAY (12A) followed by amount
        // Using [\d,]+ to handle Indian number format (1,72,986)
        let patterns = [
            #"BPAY\s*(?:\([^)]+\))?\s*:?\s*([\d,]+)"#,
            #"Basic Pay\s*:?\s*([\d,]+)"#,
            #"BP\s+([\d,]+)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractDA(from text: String) -> Double {
        // Pattern: DA followed by amount
        let patterns = [
            #"DA\s*:?\s*([\d,]+)"#,
            #"Dearness\s*(?:Allowance)?\s*:?\s*([\d,]+)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractMSP(from text: String) -> Double {
        // Pattern: MSP followed by amount
        let patterns = [
            #"MSP\s*:?\s*([\d,]+)"#,
            #"Military\s*Service\s*Pay\s*:?\s*([\d,]+)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractGrossPay(from text: String) -> Double {
        // Pattern: Gross Pay or Total Credits
        let patterns = [
            #"Gross\s*(?:Pay)?\s*:?\s*([\d,]+)"#,
            #"Total\s*Credits?\s*:?\s*([\d,]+)"#,
            #"कुल\s*आय\s*:?\s*([\d,]+)"# // Hindi
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    // MARK: - Core Deductions Extraction
    
    private func extractDSOP(from text: String) -> Double {
        // Pattern: DSOP followed by amount
        let patterns = [
            #"DSOP\s*:?\s*([\d,]+)"#,
            #"DSOPP\s*:?\s*([\d,]+)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractAGIF(from text: String) -> Double {
        // Pattern: AGIF followed by amount
        let patterns = [
            #"AGIF\s*(?:FUND)?\s*:?\s*([\d,]+)"#,
            #"Army\s*Group\s*Insurance\s*:?\s*([\d,]+)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractIncomeTax(from text: String) -> Double {
        // Pattern: Income Tax or ITAX or IT
        let patterns = [
            #"ITAX\s*:?\s*([\d,]+)"#,
            #"IT\s+([\d,]+)"#,
            #"Income\s*Tax\s*:?\s*([\d,]+)"#
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    private func extractTotalDeductions(from text: String) -> Double {
        // Pattern: Total Deductions
        let patterns = [
            #"Total\s*Deductions?\s*:?\s*([\d,]+)"#,
            #"कुल\s*कटौती\s*:?\s*([\d,]+)"# // Hindi
        ]
        
        return extractAmount(patterns: patterns, from: text)
    }
    
    // MARK: - Net Remittance Extraction
    
    private func extractNetRemittance(from text: String) -> Double {
        // Pattern: Net Remittance or Net Pay
        // Indian number format: 1,72,986 (lakhs system - comma every 2 digits after first 3)
        let patterns = [
            #"Net\s*Remittance\s*:?\s*[₹Rs\.]*\s*([\d,]+)"#,
            #"निवल\s+प्रेषित\s+धन[/\w\s]*:\s*[₹Rs\.]*\s*([\d,]+)"#, // Hindi: निवल प्रेषित धन
            #"निवल\s*:?\s*[₹Rs\.]*\s*([\d,]+)"# // Hindi: निवल alone
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

