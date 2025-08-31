import Foundation

/// Responsible for building PayslipItem objects from extracted data
class PayslipBuilder {
    private let patternProvider: PatternProvider
    private let validator: PayslipValidator
    
    init(patternProvider: PatternProvider, validator: PayslipValidator) {
        self.patternProvider = patternProvider
        self.validator = validator
    }
    
    /// Creates a PayslipItem from extracted data
    ///
    /// - Parameters:
    ///   - extractedData: The extracted data dictionary
    ///   - earnings: The earnings dictionary
    ///   - deductions: The deductions dictionary
    ///   - pdfData: The PDF data (optional)
    /// - Returns: A PayslipItem
    func createPayslipItem(
        from extractedData: [String: String],
        earnings: [String: Double],
        deductions: [String: Double],
        pdfData: Data? = nil
    ) -> PayslipItem {
        // Validate and clean the extracted data
        let validatedEarnings = validator.validateFinancialData(earnings)
        let validatedDeductions = validator.validateFinancialData(deductions)
        
        // Extract month and year from statement period
        var month = "Unknown"
        var year = Calendar.current.component(.year, from: Date())
        
        if let statementPeriod = extractedData["statementPeriod"] {
            month = getMonthName(from: statementPeriod)
            year = getYear(from: statementPeriod)
        } else if let extractedMonth = extractedData["month"], !extractedMonth.isEmpty {
            month = extractedMonth
            if let extractedYear = extractedData["year"], let yearInt = Int(extractedYear) {
                year = yearInt
            }
        }
        
        // Extract financial values
        let credits: Double
        let debits: Double
        var dsop: Double = 0.0
        var tax: Double = 0.0
        
        // Phase 14: Prefer printed totals when flagged; otherwise compute from components
        let flags = ServiceRegistry.shared.resolve(FeatureFlagProtocol.self)
        let builderGateOn = flags?.isEnabled(.pcdaBuilderGating) ?? false
        if builderGateOn, let printedCredits = validatedEarnings["__CREDITS_TOTAL"] {
            credits = printedCredits
        } else if let militaryCredits = validatedEarnings["__CREDITS_TOTAL"] {
            credits = militaryCredits
        } else {
            credits = validatedEarnings.values.reduce(0, +)
        }
        
        if builderGateOn, let printedDebits = validatedDeductions["__DEBITS_TOTAL"] {
            debits = printedDebits
        } else if let militaryDebits = validatedDeductions["__DEBITS_TOTAL"] {
            debits = militaryDebits
        } else {
            debits = validatedDeductions.values.reduce(0, +)
        }
        
        // Extract DSOP values using multiple strategies
        if let dsopStr = extractedData["dsop"], let dsopValue = Double(dsopStr), validator.isValidDSOPValue(dsopValue) {
            dsop = dsopValue
        } else if let dsopSubscriptionStr = extractedData["dsopSubscription"], let dsopValue = Double(dsopSubscriptionStr), validator.isValidDSOPValue(dsopValue) {
            dsop = dsopValue
        } else if let militaryDsop = validatedDeductions["__DSOP_TOTAL"], validator.isValidDSOPValue(militaryDsop) {
            // Use the special military DSOP value if it's large enough
            dsop = militaryDsop
        } else if let deductionDsop = validatedDeductions["DSOP"], validator.isValidDSOPValue(deductionDsop) {
            // Use the deductions DSOP field if available and large enough
            dsop = deductionDsop
        } else if let earningDsop = validatedEarnings["DSOP"], validator.isValidDSOPValue(earningDsop) {
            // If DSOP was incorrectly categorized as earnings, use it anyway
            dsop = earningDsop
        }
        
        // Extract tax values using multiple strategies
        if let itaxStr = extractedData["itax"], let itaxValue = Double(itaxStr), validator.isValidTaxValue(itaxValue) {
            tax = itaxValue
        } else if let incomeTaxStr = extractedData["incomeTaxDeducted"], let taxValue = Double(incomeTaxStr), validator.isValidTaxValue(taxValue) {
            tax = taxValue
        } else if let militaryTax = validatedDeductions["__TAX_TOTAL"], validator.isValidTaxValue(militaryTax) {
            // Use the special military tax value if it's large enough
            tax = militaryTax
        } else if let deductionTax = validatedDeductions["ITAX"], validator.isValidTaxValue(deductionTax) {
            // Use the deductions ITAX field if available
            tax = deductionTax
        } else if let earningTax = validatedEarnings["ITAX"], validator.isValidTaxValue(earningTax) {
            // If ITAX was incorrectly categorized as earnings, use it anyway
            tax = earningTax
        }
        
        // Create a PayslipItem
        let payslip = PayslipItem(
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: extractedData["name"] ?? "Unknown",
            accountNumber: extractedData["accountNumber"] ?? "Unknown",
            panNumber: extractedData["panNumber"] ?? "Unknown",
            pdfData: pdfData
        )
        
        // Remove special keys before setting earnings and deductions
        var cleanEarnings = validatedEarnings
        cleanEarnings.removeValue(forKey: "__CREDITS_TOTAL")
        
        var cleanDeductions = validatedDeductions
        cleanDeductions.removeValue(forKey: "__DEBITS_TOTAL")
        cleanDeductions.removeValue(forKey: "__DSOP_TOTAL")
        cleanDeductions.removeValue(forKey: "__TAX_TOTAL")
        
        // Set earnings and deductions
        payslip.earnings = cleanEarnings
        payslip.deductions = cleanDeductions
        
        return payslip
    }
    
    // MARK: - Helper Methods
    
    /// Extracts the month name from a statement period
    ///
    /// - Parameter text: The text to extract the month name from
    /// - Returns: The month name
    private func getMonthName(from text: String) -> String {
        let monthNames = ["January", "February", "March", "April", "May", "June", 
                         "July", "August", "September", "October", "November", "December"]
        
        // Check for month name in text
        for month in monthNames {
            if text.contains(month) {
                return month
            }
        }
        
        // Check for date format DD/MM/YYYY or DD-MM-YYYY
        if let match = text.firstMatch(for: "\\d{1,2}[/-](\\d{1,2})[/-]\\d{4}"),
           match.count >= 2,
           let monthNum = Int(match[1]), monthNum >= 1, monthNum <= 12 {
            return monthNames[monthNum - 1]
        }
        
        return "Unknown"
    }
    
    /// Extracts the year from a statement period
    ///
    /// - Parameter text: The text to extract the year from
    /// - Returns: The year
    private func getYear(from text: String) -> Int {
        // Check for year in YYYY format
        if let match = text.firstMatch(for: "(\\d{4})"),
           match.count >= 2,
           let year = Int(match[1]) {
            return year
        }
        
        // Check for date format DD/MM/YYYY or DD-MM-YYYY
        if let match = text.firstMatch(for: "\\d{1,2}[/-]\\d{1,2}[/-](\\d{4})"),
           match.count >= 2,
           let year = Int(match[1]) {
            return year
        }
        
        return Calendar.current.component(.year, from: Date())
    }
}

// Extension for String to support regex matching
extension String {
    func matches(for regex: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            
            return results.map { result in
                var matches: [String] = []
                // Add each capture group
                for i in 0..<result.numberOfRanges {
                    if let range = Range(result.range(at: i), in: self) {
                        matches.append(String(self[range]))
                    }
                }
                return matches
            }
        } catch {
            print("Invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func firstMatch(for regex: String) -> [String]? {
        return matches(for: regex).first
    }
} 