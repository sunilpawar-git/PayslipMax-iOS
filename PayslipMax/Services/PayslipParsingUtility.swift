import Foundation
import PDFKit

/// Utility class for converting between different payslip data formats
class PayslipParsingUtility {
    
    /// Converts ParsedPayslipData from the enhanced parser to a PayslipItem
    /// - Parameter parsedData: The parsed data from EnhancedPDFParser
    /// - Parameter pdfData: The original PDF data
    /// - Returns: A PayslipItem populated with the parsed data
    static func convertToPayslipItem(from parsedData: ParsedPayslipData, pdfData: Data) -> PayslipItem {
        // Extract month and year
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        var month = "Unknown"
        var year = Calendar.current.component(.year, from: Date())
        
        if let dateString = parsedData.metadata["statementDate"], !dateString.isEmpty {
            if let date = dateFormatter.date(from: dateString) {
                let monthFormatter = DateFormatter()
                monthFormatter.dateFormat = "MMMM"
                month = monthFormatter.string(from: date)
                year = Calendar.current.component(.year, from: date)
            }
        } else if let monthValue = parsedData.metadata["month"], !monthValue.isEmpty {
            month = monthValue
            
            if let yearValue = parsedData.metadata["year"], let yearInt = Int(yearValue) {
                year = yearInt
            }
        }
        
        // Calculate totals
        let totalEarnings = parsedData.earnings.values.reduce(0, +)
        let totalDeductions = parsedData.deductions.values.reduce(0, +)
        
        // Get tax and DSOP values
        let taxValue = parsedData.taxDetails["incomeTax"] ?? 0
        let dsopValue = parsedData.dsopDetails["subscription"] ?? 0
        
        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: year,
            credits: totalEarnings,
            debits: totalDeductions - taxValue - dsopValue,
            dsop: dsopValue,
            tax: taxValue,
            name: parsedData.personalInfo["name"] ?? "",
            accountNumber: parsedData.personalInfo["accountNumber"] ?? "",
            panNumber: parsedData.personalInfo["panNumber"] ?? "",
            pdfData: pdfData
        )
        
        // Set earnings and deductions
        payslip.earnings = parsedData.earnings
        payslip.deductions = parsedData.deductions
        
        // Add contact information to metadata
        if !parsedData.contactInfo.isEmpty {
            if !parsedData.contactInfo.emails.isEmpty {
                payslip.metadata["contactEmails"] = parsedData.contactInfo.emails.joined(separator: "|")
            }
            
            if !parsedData.contactInfo.phoneNumbers.isEmpty {
                payslip.metadata["contactPhones"] = parsedData.contactInfo.phoneNumbers.joined(separator: "|")
            }
            
            if !parsedData.contactInfo.websites.isEmpty {
                payslip.metadata["contactWebsites"] = parsedData.contactInfo.websites.joined(separator: "|")
            }
        }
        
        return payslip
    }
    
    /// Normalizes earnings and deductions keys using the MilitaryAbbreviationsService
    /// - Parameter payslip: The payslip to normalize
    /// - Returns: The same payslip with normalized keys
    static func normalizePayslipComponents(_ payslip: PayslipItem) -> PayslipItem {
        // Normalize earnings keys
        var normalizedEarnings: [String: Double] = [:]
        for (key, value) in payslip.earnings {
            let normalizedKey = MilitaryAbbreviationsService.shared.normalizePayComponent(key)
            if let existingValue = normalizedEarnings[normalizedKey] {
                normalizedEarnings[normalizedKey] = existingValue + value
            } else {
                normalizedEarnings[normalizedKey] = value
            }
        }
        payslip.earnings = normalizedEarnings
        
        // Normalize deductions keys
        var normalizedDeductions: [String: Double] = [:]
        for (key, value) in payslip.deductions {
            let normalizedKey = MilitaryAbbreviationsService.shared.normalizePayComponent(key)
            if let existingValue = normalizedDeductions[normalizedKey] {
                normalizedDeductions[normalizedKey] = existingValue + value
            } else {
                normalizedDeductions[normalizedKey] = value
            }
        }
        payslip.deductions = normalizedDeductions
        
        return payslip
    }
    
    /// Extracts additional data from the parsed payslip data.
    ///
    /// - Parameter parsedData: The parsed payslip data.
    /// - Returns: A dictionary of additional extracted data.
    static func extractAdditionalData(from parsedData: ParsedPayslipData) -> [String: String] {
        var additionalData: [String: String] = [:]
        
        // Add personal information
        for (key, value) in parsedData.personalInfo {
            additionalData[key] = value
        }
        
        // Add metadata
        for (key, value) in parsedData.metadata {
            additionalData[key] = value
        }
        
        // Add DSOP details
        for (key, value) in parsedData.dsopDetails {
            additionalData["dsop_\(key)"] = String(format: "%.0f", value)
        }
        
        // Add tax details
        for (key, value) in parsedData.taxDetails {
            additionalData["tax_\(key)"] = String(format: "%.0f", value)
        }
        
        // Add contact details
        for (key, value) in parsedData.contactDetails {
            additionalData["contact\(key.capitalized)"] = value
        }
        
        // Add document structure information
        additionalData["documentStructure"] = String(describing: parsedData.documentStructure)
        additionalData["confidenceScore"] = String(format: "%.2f", parsedData.confidenceScore)
        
        return additionalData
    }
    
    /// Analyzes extraction patterns in a text.
    ///
    /// - Parameters:
    ///   - text: The text to analyze.
    ///   - patterns: The patterns to match.
    /// - Returns: A dictionary of pattern names and their matches.
    static func analyzeExtractionPatterns(in text: String, patterns: [String: String]) -> [String: [String]] {
        var results: [String: [String]] = [:]
        
        for (name, pattern) in patterns {
            var matches: [String] = []
            
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = text as NSString
                let matchResults = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
                
                for match in matchResults {
                    if match.numberOfRanges > 0 {
                        // Get the entire match
                        let matchRange = match.range(at: 0)
                        let matchText = nsString.substring(with: matchRange)
                        
                        // If there's a capture group, get that too
                        if match.numberOfRanges > 1 {
                            let captureRange = match.range(at: 1)
                            let captureText = nsString.substring(with: captureRange)
                            matches.append("\(matchText) → Captured: \(captureText)")
                        } else {
                            matches.append(matchText)
                        }
                    }
                }
            }
            
            results[name] = matches
        }
        
        return results
    }
    
    /// Gets common extraction patterns used in payslip parsing.
    ///
    /// - Returns: A dictionary of pattern names and their regex patterns.
    static func getCommonExtractionPatterns() -> [String: String] {
        return [
            // Personal details patterns
            "Name": "(?:Name|Employee Name|Emp Name|Employee|Name of Employee)[:\\s]+([A-Za-z\\s.]+)",
            "Account Number": "(?:A/C|Account No|Bank A/C|Account Number)[:\\s]+([A-Za-z0-9\\s./]+)",
            "PAN Number": "(?:PAN|PAN No|PAN Number)[:\\s]+([A-Za-z0-9\\s]+)",
            "PAN Number (Direct)": "[A-Z]{5}[0-9]{4}[A-Z]{1}",
            
            // Date patterns
            "Month/Year": "(January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{4})",
            "Date Format": "(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})",
            
            // Financial patterns
            "Basic Pay": "(?:Basic Pay|Basic|Basic Salary)[^0-9]*([0-9,]+)",
            "Dearness Allowance": "(?:Dearness Allowance|DA|D\\.A\\.)[^0-9]*([0-9,]+)",
            "House Rent Allowance": "(?:House Rent Allowance|HRA|H\\.R\\.A\\.)[^0-9]*([0-9,]+)",
            "Transport Allowance": "(?:Transport Allowance|TA|T\\.A\\.)[^0-9]*([0-9,]+)",
            
            // Deduction patterns
            "Income Tax": "(?:Income Tax|Tax|I\\.Tax|TDS|Income-tax|IT)[^0-9]*([0-9,]+)",
            "DSOP Fund": "(?:DSOP|DSOP Fund|PF|Provident Fund)[^0-9]*([0-9,]+)",
            "AGIF": "(?:AGIF|Army Group Insurance)[^0-9]*([0-9,]+)",
            
            // DSOP details patterns
            "DSOP Opening Balance": "(?:Opening Balance)[^0-9]*([0-9,]+)",
            "DSOP Subscription": "(?:Subscription|Monthly Contribution)[^0-9]*([0-9,]+)",
            "DSOP Closing Balance": "(?:Closing Balance)[^0-9]*([0-9,]+)",
            
            // Tax details patterns
            "Gross Salary": "(?:Gross Salary|Gross Income)[^0-9]*([0-9,]+)",
            "Standard Deduction": "(?:Standard Deduction)[^0-9]*([0-9,]+)",
            "Net Taxable Income": "(?:Net Taxable Income|Taxable Income)[^0-9]*([0-9,]+)",
            
            // Tabular data patterns
            "Tabular Data": "([A-Za-z\\s&\\-]+)[.:\\s]+(\\d+(?:[.,]\\d+)?)",
            
            // Section headers
            "Section Headers": "(PERSONAL DETAILS|EMPLOYEE DETAILS|EARNINGS|PAYMENTS|PAY AND ALLOWANCES|DEDUCTIONS|RECOVERIES|INCOME TAX DETAILS|TAX DETAILS|DSOP FUND|DSOP DETAILS|CONTACT DETAILS|YOUR CONTACT POINTS)"
        ]
    }
} 