import Foundation

/// Service responsible for parsing PCDA (Principal Controller of Defence Accounts) table format
/// Used for ALL military payslips prior to November 2023 with structured Credit/Debit tables
/// Supports various historical formats including pre-2020, 2020-2022, and 2023 formats
class PCDATableParser {
    private let normalizer: NumericNormalizationServiceProtocol = NumericNormalizationService()
    private func normalizeToDouble(_ s: String) -> Double? {
        let flags = ServiceRegistry.shared.resolve(FeatureFlagProtocol.self)
        if flags?.isEnabled(.numericNormalizationV2) == true {
            return normalizer.normalizeAmount(s)
        } else {
            return Double(s.replacingOccurrences(of: ",", with: ""))
        }
    }
    
    // MARK: - Public Methods
    
    /// Extracts earnings and deductions from PCDA table format
    /// - Parameter text: The payslip text content
    /// - Returns: Tuple of (earnings, deductions) dictionaries
    func extractTableData(from text: String) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Split text into lines
        let lines = text.components(separatedBy: .newlines)
        
        print("PCDATableParser: Processing structured table with \(lines.count) lines")
        
        var index = 0
        while index < lines.count {
            let line = lines[index]
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            if trimmedLine.isEmpty { 
                index += 1
                continue 
            }
            
            print("PCDATableParser: Line \(index): '\(trimmedLine)'")
            
            // Detect main table header - covers ALL historical PCDA formats (pre-2020 to October 2023)
            if (trimmedLine.uppercased().contains("CREDIT") && trimmedLine.uppercased().contains("DEBIT")) ||
               (trimmedLine.contains("Amount in INR") && trimmedLine.contains("DESCRIPTION")) ||
               (trimmedLine.contains("Basic Pay") && (trimmedLine.contains("DSOPF") || trimmedLine.contains("AGIF"))) ||
               (trimmedLine.contains("Cr.") && trimmedLine.contains("Dr.")) ||  // Alternative format
               (trimmedLine.contains("Credits") && trimmedLine.contains("Debits")) ||  // Plural format
               (trimmedLine.uppercased().contains("EARNINGS") && trimmedLine.uppercased().contains("DEDUCTIONS")) {  // Alternative naming
                print("PCDATableParser: Found main table header")
                index += 1
                continue
            }
            
            // Handle the multi-line format specific to your October 2023 payslip
            if let multiLineData = parseMultiLineFormat(lines: lines, startingFrom: index) {
                for (desc, amount, isCredit) in multiLineData.items {
                    let code = convertDescriptionToCode(desc)
                    if isCredit {
                        earnings[code] = amount
                        print("PCDATableParser: Added multi-line earning \(code): \(amount)")
                    } else {
                        deductions[code] = amount
                        print("PCDATableParser: Added multi-line deduction \(code): \(amount)")
                    }
                }
                // Skip the lines we've already processed
                index += multiLineData.linesProcessed
                continue
            }
            
            // Parse two-column format: Basic Pay 136400 DSOPF Subn 40000
            // Try to parse any line that looks like it has two financial entries
            if let (creditDesc, creditAmount, debitDesc, debitAmount) = parseTwoColumnLine(trimmedLine) {
                let creditCode = convertDescriptionToCode(creditDesc)
                let debitCode = convertDescriptionToCode(debitDesc)
                
                earnings[creditCode] = creditAmount
                deductions[debitCode] = debitAmount
                
                print("PCDATableParser: Added earning \(creditCode): \(creditAmount)")
                print("PCDATableParser: Added deduction \(debitCode): \(debitAmount)")
                index += 1
                continue
            }
            
            // Fallback: Parse single-column format (for older/alternative formats)
            if let (desc, amount, isCredit) = parseSingleColumnLine(trimmedLine) {
                let code = convertDescriptionToCode(desc)
                if isCredit {
                    earnings[code] = amount
                    print("PCDATableParser: Added single earning \(code): \(amount)")
                } else {
                    deductions[code] = amount
                    print("PCDATableParser: Added single deduction \(code): \(amount)")
                }
                index += 1
                continue
            }
            
            // Extract totals
            if trimmedLine.contains("Total Credit") || trimmedLine.contains("Total Debit") {
                extractTableTotals(from: trimmedLine, earnings: &earnings, deductions: &deductions)
            }
            
            // Extract remittance 
            if trimmedLine.contains("REMITTANCE") {
                if let remittanceAmount = extractRemittanceAmount(from: trimmedLine) {
                    print("PCDATableParser: Found remittance: \(remittanceAmount)")
                }
            }
            
            index += 1
        }
        
        print("PCDATableParser: Extracted \(earnings.count) earnings and \(deductions.count) deductions")
        return (earnings, deductions)
    }
    
    // MARK: - Private Methods
    
    /// Parses a single-column line format: "Basic Pay 136400" 
    /// Determines if it's a credit or debit based on known patterns
    private func parseSingleColumnLine(_ line: String) -> (String, Double, Bool)? {
        // Pattern to match single entry: Description Amount (Unicode-aware letters; amounts normalized)
        let pattern = "^([\\p{L}][\\p{L}\\s/\\-\\.]+?)\\s+(.+)$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        
        let nsText = line as NSString
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let descRange = match.range(at: 1)
                let amountRange = match.range(at: 2)
                
                let description = nsText.substring(with: descRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let amount = normalizeToDouble(nsText.substring(with: amountRange)) {
                    // Determine if it's a credit (earning) or debit (deduction) based on description
                    let isCredit = isDescriptionAnEarning(description)
                    return (description, amount, isCredit)
                }
            }
        }
        
        return nil
    }
    
    /// Determines if a description represents an earning (credit) or deduction (debit)
    private func isDescriptionAnEarning(_ description: String) -> Bool {
        let upperDesc = description.uppercased()
        
        // Known earning patterns
        let earningPatterns = [
            "BASIC", "PAY", "DA", "MSP", "TPT", "TRANSPORT", "ALLOWANCE", "ALLC",
            "A/O", "ARREARS", "L FEE", "FUR", "FURNITURE", "WASHING", "KIT",
            "COMPENSATORY", "SPECIAL", "RANK", "QUALIFICATION", "TECHNICAL"
        ]
        
        // Known deduction patterns  
        let deductionPatterns = [
            "DSOPF", "DSOP", "AGIF", "TAX", "INCM", "INCOME", "CESS", "R/O",
            "INSURANCE", "SUBSCRIPTION", "FUND", "WELFARE", "CANTEEN", "MEDICAL",
            "DEDUCTION", "RECOVERY", "ADVANCE", "LOAN"
        ]
        
        // Check for earning patterns first
        for pattern in earningPatterns {
            if upperDesc.contains(pattern) {
                return true
            }
        }
        
        // Check for deduction patterns
        for pattern in deductionPatterns {
            if upperDesc.contains(pattern) {
                return false
            }
        }
        
        // Default: if unclear, assume it's an earning (safer for net pay calculation)
        return true
    }
    
    /// Parses a two-column line format: "Basic Pay 136400 DSOPF Subn 40000"
    private func parseTwoColumnLine(_ line: String) -> (String, Double, String, Double)? {
        // Pattern to match two column format: Description1 Amount1 Description2 Amount2 (Unicode-aware)
        let pattern = "^([\\p{L}][\\p{L}\\s/\\-]+?)\\s+(.+?)\\s+([\\p{L}][\\p{L}\\s/\\-]+?)\\s+(.+)$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        
        let nsText = line as NSString
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.numberOfRanges >= 5 {
                let desc1 = nsText.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                let amount1Str = nsText.substring(with: match.range(at: 2))
                let desc2 = nsText.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                let amount2Str = nsText.substring(with: match.range(at: 4))
                
                if let amount1 = normalizeToDouble(amount1Str), let amount2 = normalizeToDouble(amount2Str) {
                    return (desc1, amount1, desc2, amount2)
                }
            }
        }
        
        return nil
    }
    
    /// Converts description text to standardized code format
    private func convertDescriptionToCode(_ description: String) -> String {
        // Locale-aware normalization: Unicode punctuation collapse, Hindi synonyms
        let collapsed = collapseUnicodePunctuation(description)
        let normalizedDesc = collapsed.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Hindi → English synonyms for headers/descriptions commonly seen in legacy PCDA
        // Note: kept minimal and safe; extend as dataset expands
        let hindiSynonyms: [String: String] = [
            "विवरण": "DESCRIPTION",
            "राशि": "AMOUNT",
            "जमा": "CREDIT",
            "नावे": "DEBIT",
            "क्रेडिट": "CREDIT",
            "डेबिट": "DEBIT"
        ]

        // Token-level replacement for mixed-script strings
        var localeAware = normalizedDesc
        for (h, e) in hindiSynonyms {
            localeAware = localeAware.replacingOccurrences(of: h.uppercased(), with: e)
        }

        // Map common descriptions to standard codes (including variants)
        let descriptionMapping: [String: String] = [
            "BASIC PAY": "BPAY",
            "BASIC": "BPAY",
            "DA": "DA",
            "DEARNESS ALLOWANCE": "DA",
            "MSP": "MSP",
            "MILITARY SERVICE PAY": "MSP",
            "TPT ALLC": "TPTA",
            "TRANSPORT ALLOWANCE": "TPTA",
            "A/O DA": "DA_ARREARS",
            "A/O TRAN-I": "TRAN_ARREARS",
            "A/O TRAN-1": "TRAN_ARREARS",
            "L FEE": "L_FEE",
            "FUR": "FUR",
            "FURNITURE": "FUR",
            "DSOPF SUBN": "DSOP",
            "DSOPF": "DSOP",
            "DSOP": "DSOP",
            "AGIF": "AGIF",
            "INCM TAX": "ITAX",
            "INCOME TAX": "ITAX",
            "EDUC CESS": "EDUC_CESS",
            "R/O ELCT": "RO_ELCT",
            "BARRACK DAMAGE": "BARRACK_DAMAGE"
        ]

        if let mapped = descriptionMapping[localeAware] {
            return mapped
        }
        return localeAware.replacingOccurrences(of: " ", with: "_")
    }

    /// Collapses Unicode punctuation variants to simple ASCII spaces or slashes for consistent tokenization
    private func collapseUnicodePunctuation(_ s: String) -> String {
        var out = s
        let replacements: [String: String] = [
            "\u{2013}": "-", // en dash
            "\u{2014}": "-", // em dash
            "\u{2212}": "-", // minus sign
            "\u{00A0}": " ", // non-breaking space
            "\u{2009}": " ", // thin space
            "\u{200A}": " ", // hair space
            "\u{2002}": " ", // en space
            "\u{2003}": " ", // em space
            "\u{200B}": " ", // zero width space
            "\u{2044}": "/"  // fraction slash
        ]
        for (k, v) in replacements {
            out = out.replacingOccurrences(of: k, with: v)
        }
        // Collapse multiple spaces
        out = out.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extracts table totals
    private func extractTableTotals(from line: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        // Pattern to match total lines: "Total Credit ₹    263160"
        let totalPattern = "Total\\s+(Credit|Debit)\\s+[₹]?\\s*(\\d+(?:\\.\\d+)?)"
        
        guard let regex = try? NSRegularExpression(pattern: totalPattern, options: [.caseInsensitive]) else { return }
        
        let nsText = line as NSString
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let typeRange = match.range(at: 1)
                let amountRange = match.range(at: 2)
                
                let type = nsText.substring(with: typeRange).lowercased()
                let amountStr = nsText.substring(with: amountRange)
                
                if let amount = normalizeToDouble(amountStr) {
                    if type == "credit" {
                        earnings["TOTAL_CREDIT"] = amount
                        print("PCDATableParser: Found total credit: \(amount)")
                    } else if type == "debit" {
                        deductions["TOTAL_DEBIT"] = amount
                        print("PCDATableParser: Found total debit: \(amount)")
                    }
                }
            }
        }
    }
    
    /// Extracts remittance amount from line
    private func extractRemittanceAmount(from line: String) -> Double? {
        let pattern = "REMITTANCE\\s+[₹]?\\s*(\\d+(?:\\.\\d+)?)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        
        let nsText = line as NSString
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.numberOfRanges >= 2 {
                let amountStr = nsText.substring(with: match.range(at: 1))
                return normalizeToDouble(amountStr)
            }
        }
        
        return nil
    }
    
    /// Validates totals from text for consistency checking
    func validateTotals(from text: String, earnings: [String: Double], deductions: [String: Double]) {
        // Extract total amounts from text
        let totalCreditPattern = "Total Credit[\\s:]+([\\d,]+(?:\\.\\d+)?)"
        let totalDebitPattern = "Total Debit[\\s:]+([\\d,]+(?:\\.\\d+)?)"
        
        if let creditMatch = text.range(of: totalCreditPattern, options: .regularExpression) {
            let creditText = String(text[creditMatch])
            if let amount = extractNumericValue(from: creditText) {
                print("PCDATableParser: Total Credit found: \(amount)")
            }
        }
        
        if let debitMatch = text.range(of: totalDebitPattern, options: .regularExpression) {
            let debitText = String(text[debitMatch])
            if let amount = extractNumericValue(from: debitText) {
                print("PCDATableParser: Total Debit found: \(amount)")
            }
        }
    }
    
    /// Extracts numeric value from text
    private func extractNumericValue(from text: String) -> Double? {
        let numberPattern = "([\\d,]+(?:\\.\\d+)?)"
        if let match = text.range(of: numberPattern, options: .regularExpression) {
            let numberText = String(text[match])
            return normalizeToDouble(numberText)
        }
        return nil
    }
    
         /// Parses multi-line format specific to October 2023 payslips
     /// - Parameters:
     ///   - lines: Array of all lines from the payslip
     ///   - index: Starting index to process from
     /// - Returns: Tuple containing parsed items and number of lines processed
     private func parseMultiLineFormat(lines: [String], startingFrom index: Int) -> (items: [(String, Double, Bool)], linesProcessed: Int)? {
         guard index < lines.count else { return nil }
         
         let line = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
         
         // Handle the specific format: "Basic Pay DA MSP Tpt Allc A/o DA- A/o TRAN-1 Lic Fee Fur 136400"
         if line.contains("Basic Pay") && line.contains("DA") && line.contains("MSP") {
             return parseCreditLine(line: line, lines: lines, startingFrom: index)
         }
         
         // Handle the specific format: "DSOPF Subn AGIF Incm Tax Educ Cess R/o Etkt Lic Fee Fur Barrack Damage 40000"
         if line.contains("DSOPF") && line.contains("AGIF") && line.contains("Tax") {
             return parseDebitLine(line: line, lines: lines, startingFrom: index)
         }
         
         // Handle other specific patterns
         if line.contains("REMITTANCE") || line.contains("Total Credit") || line.contains("Total Debit") {
             if let amount = extractAmountFromEndOfLine(line) {
                 let isCredit = !line.uppercased().contains("DEBIT")
                 return (items: [(line, amount, isCredit)], linesProcessed: 1)
             }
         }
         
         return nil
     }
    
    /// Parses a description-amount pair that spans two lines
    private func parseDescriptionAmountPair(lines: [String], startingFrom index: Int) -> (String, Double, Bool)? {
        guard index + 1 < lines.count else { return nil }
        
        let descriptionLine = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
        let amountLine = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if first line looks like a description (contains letters but no numbers)
        let hasLetters = descriptionLine.rangeOfCharacter(from: .letters) != nil
        let hasNumbers = descriptionLine.rangeOfCharacter(from: .decimalDigits) != nil
        
        // Check if second line looks like an amount (contains only numbers and currency symbols)
        let amountPattern = "^[₹]?\\s*(\\d+(?:\\.\\d+)?)\\s*$"
        guard let amountRegex = try? NSRegularExpression(pattern: amountPattern, options: []) else { return nil }
        
        let amountNSText = amountLine as NSString
        let amountMatches = amountRegex.matches(in: amountLine, options: [], range: NSRange(location: 0, length: amountNSText.length))
        
        if hasLetters && !hasNumbers && !amountMatches.isEmpty {
            // Extract amount from second line
            let match = amountMatches[0]
            if match.numberOfRanges >= 2 {
                let amountStr = amountNSText.substring(with: match.range(at: 1))
                if let amount = Double(amountStr) {
                    let isCredit = isDescriptionAnEarning(descriptionLine)
                    return (descriptionLine, amount, isCredit)
                }
            }
        }
        
        return nil
    }
    
    /// Parses a complex line that contains multiple entries
    private func parseComplexMultiEntryLine(_ line: String) -> [(String, Double, Bool)]? {
        var entries: [(String, Double, Bool)] = []
        
        // Pattern to match multiple description-amount pairs in one line
        let complexPattern = "([A-Za-z][A-Za-z\\s/\\-\\.]+?)\\s+(\\d+(?:\\.\\d+)?)(?:\\s+|$)"
        
        guard let regex = try? NSRegularExpression(pattern: complexPattern, options: []) else { return nil }
        
        let nsText = line as NSString
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let description = nsText.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                let amountStr = nsText.substring(with: match.range(at: 2))
                
                if let amount = Double(amountStr) {
                    let isCredit = isDescriptionAnEarning(description)
                    entries.append((description, amount, isCredit))
                }
            }
        }
        
        return entries.isEmpty ? nil : entries
    }
    
    /// Parses a credit line in the multi-line format
    /// Handles lines like "Basic Pay DA MSP Tpt Allc A/o DA- A/o TRAN-1 Lic Fee Fur 136400"
    private func parseCreditLine(line: String, lines: [String], startingFrom index: Int) -> (items: [(String, Double, Bool)], linesProcessed: Int)? {
        guard let amount = extractAmountFromEndOfLine(line) else { return nil }
        
        // Extract descriptions from the line (everything except the amount at the end)
        let lineWithoutAmount = line.replacingOccurrences(of: String(Int(amount)), with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split descriptions and create entries
        let descriptions = lineWithoutAmount.components(separatedBy: " ").filter { !$0.isEmpty }
        var items: [(String, Double, Bool)] = []
        
        // Distribute the amount across all descriptions equally or use specific logic
        if !descriptions.isEmpty {
            // For credit lines, all entries are earnings (true)
            let amountPerItem = amount / Double(descriptions.count)
            for desc in descriptions {
                if !desc.isEmpty {
                    items.append((desc, amountPerItem, true))
                }
            }
        }
        
        return (items: items, linesProcessed: 1)
    }
    
    /// Parses a debit line in the multi-line format
    /// Handles lines like "DSOPF Subn AGIF Incm Tax Educ Cess R/o Etkt Lic Fee Fur Barrack Damage 40000"
    private func parseDebitLine(line: String, lines: [String], startingFrom index: Int) -> (items: [(String, Double, Bool)], linesProcessed: Int)? {
        guard let amount = extractAmountFromEndOfLine(line) else { return nil }
        
        // Extract descriptions from the line (everything except the amount at the end)
        let lineWithoutAmount = line.replacingOccurrences(of: String(Int(amount)), with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split descriptions and create entries
        let descriptions = lineWithoutAmount.components(separatedBy: " ").filter { !$0.isEmpty }
        var items: [(String, Double, Bool)] = []
        
        // Distribute the amount across all descriptions equally or use specific logic
        if !descriptions.isEmpty {
            // For debit lines, all entries are deductions (false)
            let amountPerItem = amount / Double(descriptions.count)
            for desc in descriptions {
                if !desc.isEmpty {
                    items.append((desc, amountPerItem, false))
                }
            }
        }
        
        return (items: items, linesProcessed: 1)
    }
    
    /// Extracts the amount from the end of a line
    /// Handles lines where the amount appears at the end like "Basic Pay DA MSP 136400"
    private func extractAmountFromEndOfLine(_ line: String) -> Double? {
        // Capture trailing token with currency/Unicode numerals and let normalizer decide
        let pattern = "([\\p{Sc}]?\\s*[\\p{N}0-9.,()\\-]+)\\s*$"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        
        let nsText = line as NSString
        let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsText.length))
        
        if let match = matches.first, match.numberOfRanges >= 2 {
            let amountStr = nsText.substring(with: match.range(at: 1))
            return normalizeToDouble(amountStr)
        }
        
        return nil
    }
} 