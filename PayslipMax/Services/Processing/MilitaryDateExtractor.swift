//
//  MilitaryDateExtractor.swift
//  PayslipMax
//
//  Created for military payslip date extraction logic
//  Extracted to maintain file size compliance (<300 lines)
//

import Foundation

/// Service responsible for extracting dates from military payslips
/// Implements SOLID principles with single responsibility for date parsing
class MilitaryDateExtractor {
    
    /// Extracts the payslip statement month and year from military payslip text
    func extractStatementDate(from text: String) -> (month: String, year: Int)? {
        // Military payslip date patterns
        let militaryDatePatterns = [
            "(?:FOR\\s+(?:THE\\s+)?MONTH\\s+(?:OF\\s+)?)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+([0-9]{4})",
            "(?:STATEMENT\\s+FOR\\s+)?([0-9]{1,2})[/\\-]([0-9]{4})",
            "(?:PAY\\s+ACCOUNT\\s+FOR\\s+)?(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)\\s+([0-9]{4})"
        ]
        
        for pattern in militaryDatePatterns {
            if let dateValue = extractDateWithPattern(pattern, from: text) {
                return dateValue
            }
        }
        
        return nil
    }
    
    /// Helper to extract date with specific pattern
    private func extractDateWithPattern(_ pattern: String, from text: String) -> (month: String, year: Int)? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 2 {
                let monthRange = match.range(at: 1)
                let yearRange = match.range(at: 2)
                
                let month = nsString.substring(with: monthRange).capitalized
                let yearStr = nsString.substring(with: yearRange)
                
                if let year = Int(yearStr) {
                    return (month, year)
                }
            }
        } catch {
            print("[MilitaryDateExtractor] Error with date pattern \\(pattern): \\(error.localizedDescription)")
        }
        return nil
    }
    
    /// Extracts personal information from military payslip text
    func extractPersonalInfo(from text: String) -> (name: String?, accountNumber: String?, panNumber: String?) {
        let name = extractName(from: text)
        let accountNumber = extractAccountNumber(from: text)
        let panNumber = extractPANNumber(from: text)
        
        return (name, accountNumber, panNumber)
    }
    
    /// Extracts employee name from military payslip
    private func extractName(from text: String) -> String? {
        let namePatterns = [
            "(?:Name|Employee Name|Emp Name)[:\\s]+([A-Za-z\\s.]+?)(?:\\n|\\s{2,}|[A-Z/]{2,})",
            "Name:\\s*([A-Za-z\\s.]+?)(?:\\s+A/C|\\s+Service)",
            "([A-Z][a-z]+\\s+[A-Z][a-z]+\\s+[A-Z][a-z]+)\\s*(?:A/C|Account)"
        ]
        
        for pattern in namePatterns {
            if let name = extractValueWithPattern(pattern, from: text) {
                let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanName.count > 3 && cleanName.count < 50 {
                    return cleanName
                }
            }
        }
        return nil
    }
    
    /// Extracts account number from military payslip
    private func extractAccountNumber(from text: String) -> String? {
        let accountPatterns = [
            "(?:A/C No|Account No|Account Number)[:\\s-]+([A-Za-z0-9/\\-]+)",
            "A/C\\s+No[:\\s-]+([0-9/\\-A-Za-z]+)"
        ]
        
        for pattern in accountPatterns {
            if let account = extractValueWithPattern(pattern, from: text) {
                let cleanAccount = account.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanAccount.count > 5 {
                    return cleanAccount
                }
            }
        }
        return nil
    }
    
    /// Extracts PAN number from military payslip
    private func extractPANNumber(from text: String) -> String? {
        let panPatterns = [
            "(?:PAN No|PAN Number)[:\\s]+([A-Z]{5}[0-9]{4}[A-Z]{1})",
            "PAN\\s+No[:\\s]+([A-Z0-9*]+)",
            "([A-Z]{5}[0-9]{4}[A-Z]{1})",  // Direct PAN pattern
            "([A-Z]{2}\\*{4}[0-9A-Z]{2,3})" // Masked PAN pattern
        ]
        
        for pattern in panPatterns {
            if let pan = extractValueWithPattern(pattern, from: text) {
                let cleanPAN = pan.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanPAN.count >= 6 {
                    return cleanPAN
                }
            }
        }
        return nil
    }
    
    /// Helper to extract value with regex pattern
    private func extractValueWithPattern(_ pattern: String, from text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                return nsString.substring(with: valueRange)
            }
        } catch {
            print("[MilitaryDateExtractor] Error with pattern \\(pattern): \\(error.localizedDescription)")
        }
        return nil
    }
}
