//
//  SectionAwarePatternMatcher.swift
//  PayslipMax
//
//  Section-aware pattern matching with Universal RH and Arrears support
//  Handles dual-section components like RH12 appearing in both earnings and deductions
//

import Foundation
import os.log

protocol SectionAwarePatternMatcherProtocol {
    func extractFromSection(_ section: PayslipDocumentSection, using patterns: [PatternConfig]) async -> [FinancialItem]
    func handleDualSectionComponents(_ text: String) async -> [FinancialItem]
    func identifyDocumentSections(in text: String) -> [PayslipDocumentSection: String]
}

enum PayslipDocumentSection: String, CaseIterable {
    case earnings = "earnings"
    case deductions = "deductions" 
    case transactions = "transactions"
    case metadata = "metadata"
    
    var identificationPatterns: [String] {
        switch self {
        case .earnings:
            return ["EARNINGS", "आय", "CREDIT", "जमा", "INCOME", "PAY"]
        case .deductions:
            return ["DEDUCTIONS", "कटौती", "DEBIT", "नामे", "DEDUCTION", "RECOVERY"]
        case .transactions:
            return ["DETAILS OF TRANSACTIONS", "TRANSACTION", "DETAILS"]
        case .metadata:
            return ["Name:", "A/C No:", "PAN No:", "Employee", "Account"]
        }
    }
}

struct FinancialItem {
    let code: String
    let amount: Decimal
    let section: PayslipDocumentSection
    let confidence: Double
    let isRHCode: Bool
    let isArrearsCode: Bool
    let baseComponent: String?
    
    init(code: String, amount: Decimal, section: PayslipDocumentSection, confidence: Double = 0.9) {
        self.code = code
        self.amount = amount
        self.section = section
        self.confidence = confidence
        self.isRHCode = code.hasPrefix("RH") && code.count >= 4
        self.isArrearsCode = code.hasPrefix("ARR-") || code.hasPrefix("Arr-")
        self.baseComponent = isArrearsCode ? String(code.dropFirst(4)) : nil
    }
}

struct PatternConfig {
    let pattern: String
    let type: SectionType
    let confidence: Double
    let description: String
    let isUniversalPattern: Bool
    
    enum SectionType {
        case earnings
        case deductions
        case both
    }
}

class SectionAwarePatternMatcher: SectionAwarePatternMatcherProtocol {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "PayslipMax", category: "SectionAwarePatternMatcher")
    private let universalRHCodes = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]
    
    // MARK: - Section Identification
    
    func identifyDocumentSections(in text: String) -> [PayslipDocumentSection: String] {
        var sections: [PayslipDocumentSection: String] = [:]
        let lines = text.components(separatedBy: .newlines)
        
        var currentSection: PayslipDocumentSection?
        var sectionContent: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this line indicates a new section
            if let detectedSection = detectSection(from: trimmedLine) {
                // Save previous section if exists
                if let current = currentSection, !sectionContent.isEmpty {
                    sections[current] = sectionContent.joined(separator: "\n")
                }
                
                // Start new section
                currentSection = detectedSection
                sectionContent = [trimmedLine]
            } else if let current = currentSection {
                // Add to current section
                sectionContent.append(trimmedLine)
            }
        }
        
        // Save final section
        if let current = currentSection, !sectionContent.isEmpty {
            sections[current] = sectionContent.joined(separator: "\n")
        }
        
        return sections
    }
    
    private func detectSection(from line: String) -> PayslipDocumentSection? {
        let upperLine = line.uppercased()
        
        for section in PayslipDocumentSection.allCases {
            for pattern in section.identificationPatterns {
                if upperLine.contains(pattern.uppercased()) {
                    return section
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Pattern Extraction
    
    func extractFromSection(_ section: PayslipDocumentSection, using patterns: [PatternConfig]) async -> [FinancialItem] {
        guard let sectionText = identifyDocumentSections(in: "")[section] else {
            return []
        }
        
        var extractedItems: [FinancialItem] = []
        
        // Process regular patterns
        for pattern in patterns {
            let items = await extractUsingPattern(pattern, from: sectionText, in: section)
            extractedItems.append(contentsOf: items)
        }
        
        // Process Universal RH patterns
        let rhItems = await extractUniversalRHCodes(from: sectionText, in: section)
        extractedItems.append(contentsOf: rhItems)
        
        // Process Universal Arrears patterns
        let arrearsItems = await extractUniversalArrears(from: sectionText, in: section)
        extractedItems.append(contentsOf: arrearsItems)
        
        return deduplicateItems(extractedItems)
    }
    
    // MARK: - Universal RH Code Extraction
    
    private func extractUniversalRHCodes(from text: String, in section: PayslipDocumentSection) async -> [FinancialItem] {
        var rhItems: [FinancialItem] = []
        
        for rhCode in universalRHCodes {
            let patterns = generateRHPatterns(for: rhCode)
            
            for pattern in patterns {
                let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(text.startIndex..., in: text)
                
                regex?.enumerateMatches(in: text, range: range) { match, _, _ in
                    guard let match = match,
                          let amountRange = Range(match.range(at: 1), in: text) else { return }
                    
                    let amountString = String(text[amountRange])
                    if let amount = parseAmount(amountString) {
                        let item = FinancialItem(
                            code: rhCode,
                            amount: amount,
                            section: section,
                            confidence: 0.9
                        )
                        rhItems.append(item)
                    }
                }
            }
        }
        
        return rhItems
    }
    
    private func generateRHPatterns(for rhCode: String) -> [String] {
        return [
            "(?:\(rhCode))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,.]+)",
            "(?:RISK\\s+(?:AND\\s+)?HARDSHIP|R&H|RISK\\s+HARDSHIP)\\s+\(rhCode)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,.]+)",
            "(?:RH\\s+ALLOWANCE|RISK\\s+HARDSHIP\\s+ALLOWANCE)\\s+\(rhCode)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,.]+)"
        ]
    }
    
    // MARK: - Universal Arrears Extraction
    
    private func extractUniversalArrears(from text: String, in section: PayslipDocumentSection) async -> [FinancialItem] {
        let arrearsPatterns = [
            "ARR-([A-Z]{2,8})\\s*[:\\s]*₹?([0-9,]+)",
            "Arr-([A-Z]{2,8})\\s*[:\\s]*₹?([0-9,]+)",
            "ARREARS\\s+([A-Z]{2,8})\\s*[:\\s]*₹?([0-9,]+)",
            "ARR\\s+([A-Z]{2,8})\\s*[:\\s]*₹?([0-9,]+)"
        ]
        
        var arrearsItems: [FinancialItem] = []
        
        for patternString in arrearsPatterns {
            let regex = try? NSRegularExpression(pattern: patternString, options: .caseInsensitive)
            let range = NSRange(text.startIndex..., in: text)
            
            regex?.enumerateMatches(in: text, range: range) { match, _, _ in
                guard let match = match,
                      let codeRange = Range(match.range(at: 1), in: text),
                      let amountRange = Range(match.range(at: 2), in: text) else { return }
                
                let baseCode = String(text[codeRange])
                let amountString = String(text[amountRange])
                
                // Validate base code and parse amount
                if isValidPayCode(baseCode), let amount = parseAmount(amountString) {
                    let item = FinancialItem(
                        code: "ARR-\(baseCode)",
                        amount: amount,
                        section: section,
                        confidence: 0.85
                    )
                    arrearsItems.append(item)
                }
            }
        }
        
        return arrearsItems
    }
    
    // MARK: - Dual-Section Component Handling
    
    func handleDualSectionComponents(_ text: String) async -> [FinancialItem] {
        let sections = identifyDocumentSections(in: text)
        var allComponents: [FinancialItem] = []
        
        // Process each section separately
        for (sectionType, sectionText) in sections {
            // Extract RH codes from this section
            let rhComponents = await extractUniversalRHCodes(from: sectionText, in: sectionType)
            allComponents.append(contentsOf: rhComponents)
            
            // Extract arrears from this section  
            let arrearsComponents = await extractUniversalArrears(from: sectionText, in: sectionType)
            allComponents.append(contentsOf: arrearsComponents)
            
            logger.debug("Section \(sectionType.rawValue): Found \(rhComponents.count) RH codes, \(arrearsComponents.count) arrears")
        }
        
        return allComponents
    }
    
    // MARK: - Helper Methods
    
    private func extractUsingPattern(_ pattern: PatternConfig, from text: String, in section: PayslipDocumentSection) async -> [FinancialItem] {
        // Implementation for regular pattern extraction
        return []
    }
    
    private func isValidPayCode(_ code: String) -> Bool {
        let validCodes = [
            "BPAY", "DA", "MSP", "HRA", "CCA", "TPTA", "TPTADA", "CEA",
            "DSOP", "AGIF", "ITAX", "EHCESS", "CGHS", "PLI", "RSHNA"
        ] + universalRHCodes
        
        return validCodes.contains(code)
    }
    
    private func parseAmount(_ amountString: String) -> Decimal? {
        let cleanAmount = amountString
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Decimal(string: cleanAmount)
    }
    
    private func deduplicateItems(_ items: [FinancialItem]) -> [FinancialItem] {
        var uniqueItems: [String: FinancialItem] = [:]
        
        for item in items {
            let key = "\(item.code)_\(item.section.rawValue)"
            
            if let existing = uniqueItems[key] {
                // Keep item with higher confidence
                if item.confidence > existing.confidence {
                    uniqueItems[key] = item
                }
            } else {
                uniqueItems[key] = item
            }
        }
        
        return Array(uniqueItems.values)
    }
}
