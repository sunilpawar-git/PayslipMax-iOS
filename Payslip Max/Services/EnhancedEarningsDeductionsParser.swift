import Foundation
import PDFKit

/// Data structure to hold parsed earnings and deductions data
struct EarningsDeductionsData {
    // Standard earnings
    var bpay: Double = 0
    var da: Double = 0
    var msp: Double = 0
    
    // Standard deductions
    var dsop: Double = 0
    var agif: Double = 0
    var itax: Double = 0
    
    // Non-standard components
    var knownEarnings: [String: Double] = [:]
    var knownDeductions: [String: Double] = [:]
    
    // Miscellaneous components
    var miscCredits: Double = 0
    var miscDebits: Double = 0
    
    // Totals
    var grossPay: Double = 0
    var totalDeductions: Double = 0
    
    // Raw data for reference
    var rawEarnings: [String: Double] = [:]
    var rawDeductions: [String: Double] = [:]
}

/// Enhanced parser for earnings and deductions that uses the AbbreviationManager
class EnhancedEarningsDeductionsParser {
    private let abbreviationManager: AbbreviationManager
    private let learningSystem: AbbreviationLearningSystem
    
    init(abbreviationManager: AbbreviationManager) {
        self.abbreviationManager = abbreviationManager
        self.learningSystem = AbbreviationLearningSystem(abbreviationManager: abbreviationManager)
    }
    
    /// Extracts earnings and deductions data from the payslip text
    /// - Parameter pageText: The text of the payslip page
    /// - Returns: Structured earnings and deductions data
    func extractEarningsDeductions(from pageText: String) -> EarningsDeductionsData {
        var data = EarningsDeductionsData()
        
        // First, identify the earnings and deductions sections
        let earningsSectionPattern = "EARNINGS[\\s\\S]*?Description\\s+Amount"
        let deductionsSectionPattern = "DEDUCTIONS[\\s\\S]*?Description\\s+Amount"
        
        // Extract raw earnings items
        if let earningsRange = pageText.range(of: earningsSectionPattern, options: .regularExpression) {
            let earningsText = String(pageText[earningsRange])
            let earningsItems = extractItemsFromSection(earningsText)
            data.rawEarnings = earningsItems
            
            // Process earnings items
            processEarningsItems(earningsItems, into: &data)
        }
        
        // Extract raw deductions items
        if let deductionsRange = pageText.range(of: deductionsSectionPattern, options: .regularExpression) {
            let deductionsText = String(pageText[deductionsRange])
            let deductionsItems = extractItemsFromSection(deductionsText)
            data.rawDeductions = deductionsItems
            
            // Process deductions items
            processDeductionsItems(deductionsItems, into: &data)
        }
        
        // Extract Gross Pay
        if let grossPayRange = pageText.range(of: "Gross Pay\\s+(\\d+)", options: .regularExpression) {
            let grossPayMatch = String(pageText[grossPayRange])
            if let valueRange = grossPayMatch.range(of: "\\d+", options: .regularExpression) {
                let valueString = String(grossPayMatch[valueRange])
                data.grossPay = Double(valueString) ?? 0
            }
        }
        
        // Extract Total Deductions
        if let totalDeductionsRange = pageText.range(of: "Total Deductions\\s+(\\d+)", options: .regularExpression) {
            let totalDeductionsMatch = String(pageText[totalDeductionsRange])
            if let valueRange = totalDeductionsMatch.range(of: "\\d+", options: .regularExpression) {
                let valueString = String(totalDeductionsMatch[valueRange])
                data.totalDeductions = Double(valueString) ?? 0
            }
        }
        
        // Validate and adjust if needed
        validateAndAdjustData(&data)
        
        return data
    }
    
    /// Process earnings items according to the specified logic
    /// - Parameters:
    ///   - items: Dictionary of earnings items
    ///   - data: Data structure to update with processed earnings
    private func processEarningsItems(_ items: [String: Double], into data: inout EarningsDeductionsData) {
        for (key, value) in items {
            switch key {
            case "BPAY":
                data.bpay = value
            case "DA":
                data.da = value
            case "MSP":
                data.msp = value
            default:
                // Check if it's a known non-standard earning
                let type = abbreviationManager.getType(for: key)
                if type == .earning {
                    data.knownEarnings[key] = value
                } else if type == .deduction {
                    // This is a known deduction but appears in earnings section
                    // This could be a mistake in the document or a misclassification
                    print("Warning: Found deduction \(key) in earnings section")
                    data.knownDeductions[key] = value
                } else {
                    // Unknown abbreviation, add to misc credits
                    data.miscCredits += value
                    print("Unknown earning abbreviation: \(key) with value \(value)")
                    
                    // Track the unknown abbreviation with the learning system
                    learningSystem.trackUnknownAbbreviation(key, context: "earnings", value: value)
                    
                    // Also track with the abbreviation manager for backward compatibility
                    abbreviationManager.trackUnknownAbbreviation(key, value: value)
                }
            }
        }
    }
    
    /// Process deductions items according to the specified logic
    /// - Parameters:
    ///   - items: Dictionary of deductions items
    ///   - data: Data structure to update with processed deductions
    private func processDeductionsItems(_ items: [String: Double], into data: inout EarningsDeductionsData) {
        for (key, value) in items {
            switch key {
            case "DSOP":
                data.dsop = value
            case "AGIF":
                data.agif = value
            case "ITAX":
                data.itax = value
            default:
                // Check if it's a known non-standard deduction
                let type = abbreviationManager.getType(for: key)
                if type == .deduction {
                    data.knownDeductions[key] = value
                } else if type == .earning {
                    // This is a known earning but appears in deductions section
                    // This could be a mistake in the document or a misclassification
                    print("Warning: Found earning \(key) in deductions section")
                    data.knownEarnings[key] = value
                } else {
                    // Unknown abbreviation, add to misc debits
                    data.miscDebits += value
                    print("Unknown deduction abbreviation: \(key) with value \(value)")
                    
                    // Track the unknown abbreviation with the learning system
                    learningSystem.trackUnknownAbbreviation(key, context: "deductions", value: value)
                    
                    // Also track with the abbreviation manager for backward compatibility
                    abbreviationManager.trackUnknownAbbreviation(key, value: value)
                }
            }
        }
    }
    
    /// Helper to extract items from a section
    /// - Parameter sectionText: The text of the section to extract items from
    /// - Returns: Dictionary of item names and values
    private func extractItemsFromSection(_ sectionText: String) -> [String: Double] {
        var items: [String: Double] = [:]
        
        // Pattern to match "ITEM_NAME    12345" format
        let pattern = "([A-Za-z\\-]+)\\s+(\\d+(?:\\.\\d+)?)"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = sectionText as NSString
        let matches = regex?.matches(in: sectionText, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            if match.numberOfRanges == 3 {
                let keyRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let key = nsString.substring(with: keyRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let valueString = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let value = Double(valueString) {
                    items[key] = value
                }
            }
        }
        
        return items
    }
    
    /// Validate data and make adjustments if needed
    /// - Parameter data: Data structure to validate and adjust
    private func validateAndAdjustData(_ data: inout EarningsDeductionsData) {
        // Calculate total of standard earnings
        let standardEarningsTotal = data.bpay + data.da + data.msp
        
        // Calculate total of known non-standard earnings
        let knownNonStandardEarningsTotal = data.knownEarnings.values.reduce(0, +)
        
        // Calculate total of all earnings
        let calculatedTotalEarnings = standardEarningsTotal + knownNonStandardEarningsTotal + data.miscCredits
        
        // If there's a discrepancy between calculated and extracted gross pay, adjust misc credits
        if abs(calculatedTotalEarnings - data.grossPay) > 0.01 && data.grossPay > 0 {
            data.miscCredits += (data.grossPay - calculatedTotalEarnings)
        }
        
        // Calculate total of standard deductions
        let standardDeductionsTotal = data.dsop + data.agif + data.itax
        
        // Calculate total of known non-standard deductions
        let knownNonStandardDeductionsTotal = data.knownDeductions.values.reduce(0, +)
        
        // Calculate total of all deductions
        let calculatedTotalDeductions = standardDeductionsTotal + knownNonStandardDeductionsTotal + data.miscDebits
        
        // If there's a discrepancy between calculated and extracted total deductions, adjust misc debits
        if abs(calculatedTotalDeductions - data.totalDeductions) > 0.01 && data.totalDeductions > 0 {
            data.miscDebits += (data.totalDeductions - calculatedTotalDeductions)
        }
    }
    
    /// Returns the abbreviation learning system used by this parser
    /// - Returns: The abbreviation learning system
    func getLearningSystem() -> AbbreviationLearningSystem {
        return learningSystem
    }
} 