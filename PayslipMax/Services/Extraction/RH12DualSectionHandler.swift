//
//  RH12DualSectionHandler.swift
//  PayslipMax
//
//  Specialized handler for RH12 and all RH codes appearing in both earnings and deductions
//  Integrates with Universal RH Family and Section-Aware Pattern Matching
//

import Foundation
import os.log

protocol RH12DualSectionHandlerProtocol {
    func extractRH12Components(from text: String) async -> [RHComponent]
    func extractAllRHComponents(from text: String) async -> [RHComponent]
    func validateDualSectionConsistency(_ components: [RHComponent]) -> ValidationResult
}

struct RHComponent {
    let code: String                    // "RH12", "RH11", etc.
    let amount: Decimal
    let section: PayslipDocumentSection
    let confidence: Double
    let isEarnings: Bool
    let isDeduction: Bool
    let level: RHLevel
    
    var displayName: String {
        return getRiskHardshipDescription(for: code)
    }
}

enum RHLevel: Int, CaseIterable {
    case rh11 = 11, rh12 = 12, rh13 = 13
    case rh21 = 21, rh22 = 22, rh23 = 23  
    case rh31 = 31, rh32 = 32, rh33 = 33
    
    var displayName: String {
        switch self {
        case .rh11: return "RH11 (Highest Risk & Hardship)"
        case .rh12: return "RH12 (High Risk & Hardship)"
        case .rh13: return "RH13 (Moderate-High Risk & Hardship)"
        case .rh21: return "RH21 (Moderate Risk & Hardship)"
        case .rh22: return "RH22 (Moderate-Low Risk & Hardship)"
        case .rh23: return "RH23 (Low-Moderate Risk & Hardship)"
        case .rh31: return "RH31 (Low Risk & Hardship)"
        case .rh32: return "RH32 (Lower Risk & Hardship)"
        case .rh33: return "RH33 (Lowest Risk & Hardship)"
        }
    }
    
    var priority: Int {
        // RH11 = highest priority (1), RH33 = lowest priority (9)
        switch self {
        case .rh11: return 1
        case .rh12: return 2
        case .rh13: return 3
        case .rh21: return 4
        case .rh22: return 5
        case .rh23: return 6
        case .rh31: return 7
        case .rh32: return 8
        case .rh33: return 9
        }
    }
}

struct ValidationResult {
    let isValid: Bool
    let warnings: [String]
    let errors: [String]
    let suggestions: [String]
}

class RH12DualSectionHandler: RH12DualSectionHandlerProtocol {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "PayslipMax", category: "RH12DualSectionHandler")
    private let sectionAwareMatcher: SectionAwarePatternMatcherProtocol
    private let universalRHCodes = ["RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33"]
    
    // MARK: - Initialization
    
    init(sectionAwareMatcher: SectionAwarePatternMatcherProtocol) {
        self.sectionAwareMatcher = sectionAwareMatcher
    }
    
    // MARK: - RH12 Specific Extraction
    
    func extractRH12Components(from text: String) async -> [RHComponent] {
        logger.debug("Starting RH12 dual-section extraction")
        
        let sections = sectionAwareMatcher.identifyDocumentSections(in: text)
        var rh12Components: [RHComponent] = []
        
        // Extract from earnings section
        if let earningsText = sections[.earnings] {
            let earningsRH12 = await extractRH12FromSection(earningsText, section: .earnings)
            rh12Components.append(contentsOf: earningsRH12)
        }
        
        // Extract from deductions section  
        if let deductionsText = sections[.deductions] {
            let deductionsRH12 = await extractRH12FromSection(deductionsText, section: .deductions)
            rh12Components.append(contentsOf: deductionsRH12)
        }
        
        logger.debug("Extracted \(rh12Components.count) RH12 components")
        return rh12Components
    }
    
    // MARK: - Universal RH Family Extraction
    
    func extractAllRHComponents(from text: String) async -> [RHComponent] {
        logger.debug("Starting Universal RH Family extraction for all codes: \(universalRHCodes.joined(separator: ", "))")
        
        let sections = sectionAwareMatcher.identifyDocumentSections(in: text)
        var allRHComponents: [RHComponent] = []
        
        // Process each section
        for (sectionType, sectionText) in sections {
            guard sectionType == .earnings || sectionType == .deductions else { continue }
            
            let sectionComponents = await extractUniversalRHFromSection(sectionText, section: sectionType)
            allRHComponents.append(contentsOf: sectionComponents)
            
            logger.debug("Section \(sectionType.rawValue): Found \(sectionComponents.count) RH components")
        }
        
        // Log detailed findings
        let rhCounts = Dictionary(grouping: allRHComponents, by: { $0.code })
            .mapValues { $0.count }
        
        logger.debug("Universal RH extraction complete: \(rhCounts)")
        return allRHComponents
    }
    
    // MARK: - Section-Specific Extraction
    
    private func extractRH12FromSection(_ text: String, section: PayslipDocumentSection) async -> [RHComponent] {
        let rh12Patterns = [
            "(?:RH12|RH-12)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,]+)",
            "(?:RISK\\s+(?:AND\\s+)?HARDSHIP|R&H)\\s*(?:12|2)?\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,]+)",
            "(?:RISK\\s+HARDSHIP\\s+ALLOWANCE|RHA)\\s*(?:12)?\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,]+)"
        ]
        
        return await extractRHComponentsUsingPatterns(rh12Patterns, rhCode: "RH12", from: text, in: section)
    }
    
    private func extractUniversalRHFromSection(_ text: String, section: PayslipDocumentSection) async -> [RHComponent] {
        var components: [RHComponent] = []
        
        for rhCode in universalRHCodes {
            let patterns = generateUniversalRHPatterns(for: rhCode)
            let rhComponents = await extractRHComponentsUsingPatterns(patterns, rhCode: rhCode, from: text, in: section)
            components.append(contentsOf: rhComponents)
        }
        
        return components
    }
    
    private func generateUniversalRHPatterns(for rhCode: String) -> [String] {
        return [
            // Exact code match
            "(?:\(rhCode))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,]+)",
            
            // With Risk & Hardship text
            "(?:RISK\\s+(?:AND\\s+)?HARDSHIP|R&H|RISK\\s+HARDSHIP)\\s+\(rhCode)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,]+)",
            
            // With allowance text
            "(?:RISK\\s+HARDSHIP\\s+ALLOWANCE|RHA)\\s+\(rhCode)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,]+)",
            
            // Military-style with level
            "(?:R&H|RH)\\s+(?:LEVEL\\s+)?\(String(rhCode.dropFirst(2)))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|INR|₹)?\\s*([0-9,]+)"
        ]
    }
    
    private func extractRHComponentsUsingPatterns(_ patterns: [String], rhCode: String, from text: String, in section: PayslipDocumentSection) async -> [RHComponent] {
        var components: [RHComponent] = []
        
        for pattern in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                let range = NSRange(text.startIndex..., in: text)
                
                regex.enumerateMatches(in: text, range: range) { match, _, _ in
                    guard let match = match,
                          let amountRange = Range(match.range(at: 1), in: text) else { return }
                    
                    let amountString = String(text[amountRange])
                    if let amount = parseAmount(amountString) {
                        let component = RHComponent(
                            code: rhCode,
                            amount: amount,
                            section: section,
                            confidence: calculateConfidence(for: pattern),
                            isEarnings: section == .earnings,
                            isDeduction: section == .deductions,
                            level: getRHLevel(from: rhCode)
                        )
                        components.append(component)
                    }
                }
            } catch {
                logger.error("Regex error for pattern \(pattern): \(error.localizedDescription)")
            }
        }
        
        return deduplicateRHComponents(components)
    }
    
    // MARK: - Validation
    
    func validateDualSectionConsistency(_ components: [RHComponent]) -> ValidationResult {
        var warnings: [String] = []
        var errors: [String] = []
        var suggestions: [String] = []
        
        // Group by RH code
        let groupedComponents = Dictionary(grouping: components, by: { $0.code })
        
        for (rhCode, codeComponents) in groupedComponents {
            let earningsComponents = codeComponents.filter { $0.isEarnings }
            let deductionComponents = codeComponents.filter { $0.isDeduction }
            
            // Validate dual-section logic
            if earningsComponents.count > 1 {
                warnings.append("Multiple \(rhCode) entries found in earnings section")
            }
            
            if deductionComponents.count > 1 {
                warnings.append("Multiple \(rhCode) entries found in deductions section")
            }
            
            // Check for balanced transactions
            if !earningsComponents.isEmpty && !deductionComponents.isEmpty {
                let totalEarnings = earningsComponents.reduce(Decimal.zero) { $0 + $1.amount }
                let totalDeductions = deductionComponents.reduce(Decimal.zero) { $0 + $1.amount }
                
                if totalEarnings > totalDeductions {
                    suggestions.append("\(rhCode): Earnings (₹\(totalEarnings)) > Deductions (₹\(totalDeductions)) - Net positive allowance")
                } else if totalDeductions > totalEarnings {
                    warnings.append("\(rhCode): Deductions (₹\(totalDeductions)) > Earnings (₹\(totalEarnings)) - Possible recovery")
                } else {
                    suggestions.append("\(rhCode): Balanced at ₹\(totalEarnings) - Perfect match")
                }
            }
        }
        
        let isValid = errors.isEmpty
        return ValidationResult(isValid: isValid, warnings: warnings, errors: errors, suggestions: suggestions)
    }
    
    // MARK: - Helper Methods
    
    private func parseAmount(_ amountString: String) -> Decimal? {
        let cleanAmount = amountString
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return Decimal(string: cleanAmount)
    }
    
    private func calculateConfidence(for pattern: String) -> Double {
        if pattern.contains("(?:RH\\d{2})") {
            return 0.95  // Exact code match
        } else if pattern.contains("RISK") {
            return 0.85  // Risk & Hardship text
        } else {
            return 0.75  // General pattern
        }
    }
    
    private func getRHLevel(from rhCode: String) -> RHLevel {
        switch rhCode {
        case "RH11": return .rh11
        case "RH12": return .rh12
        case "RH13": return .rh13
        case "RH21": return .rh21
        case "RH22": return .rh22
        case "RH23": return .rh23
        case "RH31": return .rh31
        case "RH32": return .rh32
        case "RH33": return .rh33
        default: return .rh12  // Default fallback
        }
    }
    
    private func deduplicateRHComponents(_ components: [RHComponent]) -> [RHComponent] {
        var uniqueComponents: [String: RHComponent] = [:]
        
        for component in components {
            let key = "\(component.code)_\(component.section.rawValue)"
            
            if let existing = uniqueComponents[key] {
                // Keep component with higher confidence
                if component.confidence > existing.confidence {
                    uniqueComponents[key] = component
                }
            } else {
                uniqueComponents[key] = component
            }
        }
        
        return Array(uniqueComponents.values)
    }
}

// MARK: - Helper Functions

private func getRiskHardshipDescription(for code: String) -> String {
    let descriptions = [
        "RH11": "Risk & Hardship Level 1 (Highest)",
        "RH12": "Risk & Hardship Level 2 (High)", 
        "RH13": "Risk & Hardship Level 3 (Moderate-High)",
        "RH21": "Risk & Hardship Level 2-1 (Moderate)",
        "RH22": "Risk & Hardship Level 2-2 (Moderate-Low)",
        "RH23": "Risk & Hardship Level 2-3 (Low-Moderate)",
        "RH31": "Risk & Hardship Level 3-1 (Low)",
        "RH32": "Risk & Hardship Level 3-2 (Lower)",
        "RH33": "Risk & Hardship Level 3-3 (Lowest)"
    ]
    
    return descriptions[code] ?? "Risk & Hardship Allowance"
}
