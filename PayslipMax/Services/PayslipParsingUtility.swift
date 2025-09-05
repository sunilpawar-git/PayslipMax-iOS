import Foundation
import PDFKit

/// Utility class for payslip parsing operations and pattern analysis
class PayslipParsingUtility {
    
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
            "Salary Month": "Salary\\s+for\\s+the\\s+month\\s+of\\s+([A-Za-z]+\\s+\\d{4})",
            
            // Financial patterns
            "Basic Pay": "(?:Basic Pay|BASIC)[:\\s]+([₹\\d,]+\\.?\\d*)",
            "DA": "(?:DA|D\\.A\\.|Dearness Allowance)[:\\s]+([₹\\d,]+\\.?\\d*)",
            "HRA": "(?:HRA|H\\.R\\.A\\.|House Rent Allowance)[:\\s]+([₹\\d,]+\\.?\\d*)",
            "Gross Pay": "(?:Gross Pay|GROSS)[:\\s]+([₹\\d,]+\\.?\\d*)",
            "Net Pay": "(?:Net Pay|NET PAY|NET)[:\\s]+([₹\\d,]+\\.?\\d*)",
            
            // Deduction patterns
            "Income Tax": "(?:Income Tax|IT|I\\.T\\.)[:\\s]+([₹\\d,]+\\.?\\d*)",
            "PF": "(?:PF|P\\.F\\.|Provident Fund)[:\\s]+([₹\\d,]+\\.?\\d*)",
            "ESI": "(?:ESI|E\\.S\\.I\\.|Employee State Insurance)[:\\s]+([₹\\d,]+\\.?\\d*)",
            
            // Currency amounts (general)
            "Currency Amount": "₹\\s*([0-9,]+(?:\\.[0-9]{2})?)",
            "Numeric Amount": "([0-9,]+(?:\\.[0-9]{2})?)",
            
            // Service details
            "Service Number": "(?:Service No|Svc No|Service Number)[:\\s]+([A-Za-z0-9\\s/]+)",
            "Rank": "(?:Rank|Grade)[:\\s]+([A-Za-z\\s]+)",
            "Unit": "(?:Unit|Station|Base)[:\\s]+([A-Za-z\\s0-9]+)",
            
            // DSOP patterns
            "DSOP Opening": "(?:DSOP|Opening Balance)[:\\s]+([₹\\d,]+\\.?\\d*)",
            "DSOP Closing": "(?:Closing Balance|DSOP Closing)[:\\s]+([₹\\d,]+\\.?\\d*)",
            
            // Leave patterns
            "Leave Balance": "(?:Leave Balance|CL|EL|ML)[:\\s]+([0-9]+)",
            
            // Address patterns
            "Address": "(?:Address|Addr)[:\\s]+([A-Za-z0-9\\s,.-]+)",
            "Pin Code": "(?:PIN|Pin Code|Postal Code)[:\\s]*([0-9]{6})"
        ]
    }
}