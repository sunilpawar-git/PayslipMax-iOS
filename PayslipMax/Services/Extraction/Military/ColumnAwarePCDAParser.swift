import Foundation

/// Parser specifically designed for pre-Nov 2023 PCDA payslips
/// Solves spatial orientation problem by using known column structure
/// 
/// Pre-Nov 2023 PCDA tables ALWAYS have this 4-column structure:
/// [Credit Description] | [Credit Amount] | [Debit Description] | [Debit Amount]
class ColumnAwarePCDAParser {
    
    // MARK: - PCDA Table Structure Knowledge
    
    private struct KnownPCDAStructure {
        static let creditDescColumn = 0
        static let creditAmountColumn = 1
        static let debitDescColumn = 2
        static let debitAmountColumn = 3
        static let minimumColumnsRequired = 4
    }
    
    // MARK: - Known Data Categories
    
    /// Known earning types for validation - comprehensive list for pre-Nov 2023 PCDA
    private static let validCreditTypes = Set([
        "BASIC PAY", "BPAY", "DA", "DEARNESS ALLOWANCE", "HRA", "HOUSE RENT ALLOWANCE",
        "TA", "TRANSPORT ALLOWANCE", "CEA", "CHILDREN EDUCATION ALLOWANCE", 
        "WASHING ALLOWANCE", "WASHIA", "OUTFIT ALLOWANCE", "OUTFITA",
        "MSP", "MILITARY SERVICE PAY", "RATION", "RSHNA", "TPT", "TPTA",
        "MEDICAL", "MISC", "ARREARS", "ARR", "SPECIAL", "ALLOWANCE",
        "COMPENSATORY", "COMP", "HILL", "FIELD", "RISK", "FLYING",
        "SUBMARINE", "PARACHUTE", "COMMANDO", "SIACHEN", "HIGH ALTITUDE"
    ])
    
    /// Known deduction types for validation - comprehensive list for pre-Nov 2023 PCDA
    private static let validDebitTypes = Set([
        "DSOP", "DSOPF", "DEFENCE SAVINGS", "AGIF", "ARMY GROUP INSURANCE",
        "ITAX", "INCOME TAX", "IT", "PLI", "POSTAL LIFE INSURANCE",
        "SBI", "CGEIS", "CENTRAL GOVERNMENT", "CDA", "HOSP", "HOSPITAL",
        "CANTEEN", "MESS", "RATION", "MEDICAL", "RECOVERY", "REC",
        "FINE", "COURT", "DAMAGE", "BARRACK", "QUARTERS", "ELECTRICITY",
        "WATER", "TELEPHONE", "INTERNET", "INSURANCE", "LOAN", "ADVANCE"
    ])
    
    // MARK: - Public Methods
    
    /// Extract earnings and deductions using column-aware approach
    /// This method solves the spatial orientation problem by:
    /// 1. Using known PCDA column positions
    /// 2. Validating extracted items against known types
    /// 3. Ignoring spatially confused data outside known columns
    func extractTableData(from text: String) -> (earnings: [String: Double], deductions: [String: Double]) {
        print("ColumnAwarePCDAParser: Processing with spatial awareness")
        
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Find table boundaries
        let lines = text.components(separatedBy: .newlines)
        guard let tableRange = findTableRange(in: lines) else {
            print("ColumnAwarePCDAParser: No table found")
            return (earnings, deductions)
        }
        
        // Process each table row with column awareness
        for i in tableRange {
            let line = lines[i]
            let (rowEarnings, rowDeductions) = processTableRowWithColumnAwareness(line)
            
            // Merge results - avoiding spatial confusion
            rowEarnings.forEach { key, value in
                earnings[key] = (earnings[key] ?? 0) + value
            }
            rowDeductions.forEach { key, value in
                deductions[key] = (deductions[key] ?? 0) + value
            }
        }
        
        print("ColumnAwarePCDAParser: Successfully extracted \(earnings.count) earnings, \(deductions.count) deductions")
        return (earnings, deductions)
    }
    
    // MARK: - Private Methods
    
    /// Find the table range in the document
    private func findTableRange(in lines: [String]) -> Range<Int>? {
        var startIndex: Int?
        var endIndex: Int?
        
        // Find table start (header row with Credit/Debit structure)
        for (index, line) in lines.enumerated() {
            if isTableHeader(line) {
                startIndex = index + 1 // Start after header
                print("ColumnAwarePCDAParser: Found table header at line \(index)")
                break
            }
        }
        
        guard let start = startIndex else { 
            print("ColumnAwarePCDAParser: No table header found")
            return nil 
        }
        
        // Find table end (look for totals or next section)
        for i in start..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            if isTableEnd(line) {
                endIndex = i
                break
            }
        }
        
        let end = endIndex ?? lines.count
        print("ColumnAwarePCDAParser: Table range: \(start) to \(end)")
        return start..<end
    }
    
    /// Check if line is a table header
    private func isTableHeader(_ line: String) -> Bool {
        let upperLine = line.uppercased()
        return (upperLine.contains("CREDIT") && upperLine.contains("DEBIT")) ||
               (upperLine.contains("EARNINGS") && upperLine.contains("DEDUCTIONS")) ||
               (upperLine.contains("DESCRIPTION") && upperLine.contains("AMOUNT")) ||
               (upperLine.contains("CR.") && upperLine.contains("DR."))
    }
    
    /// Check if line indicates table end
    private func isTableEnd(_ line: String) -> Bool {
        let upperLine = line.uppercased()
        return upperLine.contains("TOTAL") || 
               upperLine.contains("NET PAY") ||
               upperLine.contains("GRAND TOTAL") ||
               upperLine.contains("SUMMARY") ||
               line.isEmpty
    }
    
    /// Process a table row with column awareness
    /// This is the core method that solves spatial orientation confusion
    private func processTableRowWithColumnAwareness(_ line: String) -> (earnings: [String: Double], deductions: [String: Double]) {
        // Split by multiple spaces/tabs to get columns
        let components = line.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // PCDA format requires exactly 4 columns - reject if not met
        guard components.count >= KnownPCDAStructure.minimumColumnsRequired else {
            print("ColumnAwarePCDAParser: Skipping row with \(components.count) columns (need 4)")
            return ([:], [:])
        }
        
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Extract credit side (columns 0 & 1) - KNOWN positions
        let creditDesc = components[KnownPCDAStructure.creditDescColumn]
        let creditAmountStr = components[KnownPCDAStructure.creditAmountColumn]
        
        if let creditAmount = parseAmount(creditAmountStr),
           isValidCredit(creditDesc),
           creditAmount > 0 {
            let normalizedDesc = normalizeDescription(creditDesc)
            earnings[normalizedDesc] = creditAmount
            print("✅ Credit: \(normalizedDesc) = ₹\(creditAmount)")
        }
        
        // Extract debit side (columns 2 & 3) - KNOWN positions
        let debitDesc = components[KnownPCDAStructure.debitDescColumn]
        let debitAmountStr = components[KnownPCDAStructure.debitAmountColumn]
        
        if let debitAmount = parseAmount(debitAmountStr),
           isValidDebit(debitDesc),
           debitAmount > 0 {
            let normalizedDesc = normalizeDescription(debitDesc)
            deductions[normalizedDesc] = debitAmount
            print("✅ Debit: \(normalizedDesc) = ₹\(debitAmount)")
        }
        
        return (earnings, deductions)
    }
    
    /// Validate if description is a known credit type
    private func isValidCredit(_ description: String) -> Bool {
        let upperDesc = description.uppercased()
        return Self.validCreditTypes.contains { type in
            upperDesc.contains(type)
        }
    }
    
    /// Validate if description is a known debit type
    private func isValidDebit(_ description: String) -> Bool {
        let upperDesc = description.uppercased()
        return Self.validDebitTypes.contains { type in
            upperDesc.contains(type)
        }
    }
    
    /// Parse amount string to Double, handling Indian currency formatting
    private func parseAmount(_ amountStr: String) -> Double? {
        let cleaned = amountStr
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .replacingOccurrences(of: "/-", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle decimal values
        if let value = Double(cleaned), value > 0 {
            return value
        }
        
        return nil
    }
    
    /// Normalize description for consistent storage
    private func normalizeDescription(_ desc: String) -> String {
        return desc
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }
}

// MARK: - Protocol Conformance

/// Protocol for column-aware parsing services
protocol ColumnAwarePCDAParserProtocol {
    func extractTableData(from text: String) -> (earnings: [String: Double], deductions: [String: Double])
}

extension ColumnAwarePCDAParser: ColumnAwarePCDAParserProtocol {}
