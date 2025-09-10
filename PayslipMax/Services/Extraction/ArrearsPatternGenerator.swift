//
//  ArrearsPatternGenerator.swift
//  PayslipMax
//
//  Created for Phase 3: Universal Arrears System - Pattern Generation Component
//  Extracted to maintain <300 line limit per architectural constraints
//

import Foundation

/// Service responsible for generating dynamic arrears patterns
/// Extracted component to maintain single responsibility and file size limits
class ArrearsPatternGenerator {
    
    // MARK: - Properties
    
    /// Known military pay codes for pattern generation
    private let knownPayCodes: Set<String>
    
    // MARK: - Initialization
    
    init() {
        self.knownPayCodes = Self.buildKnownPayCodes()
        print("[ArrearsPatternGenerator] Initialized with \(knownPayCodes.count) known pay codes")
    }
    
    // MARK: - Public Methods
    
    /// Generates dynamic arrears patterns for all known pay codes
    /// Returns patterns in format: ARR-{CODE} with multiple pattern variations
    func generateDynamicArrearsPatterns() -> [String: [String]] {
        var patterns: [String: [String]] = [:]
        
        for payCode in knownPayCodes {
            let arrearsKey = "ARR-\(payCode)"
            patterns[arrearsKey] = [
                // ARR-CODE format
                "(?:ARR-\(payCode))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
                // Arr-CODE format  
                "(?:Arr-\(payCode))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
                // ARREARS CODE format
                "(?:ARREARS\\s+\(payCode))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
                // ARREARS.*CODE format (flexible spacing)
                "(?:ARREARS.*\(payCode))\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
            ]
        }
        
        return patterns
    }
    
    /// Gets universal arrears patterns for flexible matching
    /// These patterns capture any code after ARR/ARREARS for unknown combinations
    func getUniversalArrearsPatterns() -> [String] {
        return [
            "(?:ARR-)([A-Z0-9]+)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:Arr-)([A-Z0-9]+)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:ARREARS\\s+)([A-Z0-9]+)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)",
            "(?:ARREARS)\\s+([A-Z0-9]+)\\s*(?:[:-]?\\s*)?(?:Rs\\.?|₹)?\\s*([0-9,.]+)"
        ]
    }
    
    /// Validates if a pay code is known in the military system
    func isKnownPayCode(_ code: String) -> Bool {
        return knownPayCodes.contains(code.uppercased())
    }
    
    /// Gets all known pay codes for external validation
    func getAllKnownPayCodes() -> Set<String> {
        return knownPayCodes
    }
    
    // MARK: - Private Methods
    
    /// Builds comprehensive database of known military pay codes
    private static func buildKnownPayCodes() -> Set<String> {
        return Set([
            // Basic pay components
            "BPAY", "BASICPAY", "MSP",
            
            // Allowances
            "DA", "HRA", "TPTA", "TPTADA", "CEA", "CCA", "RSHNA",
            
            // Risk and Hardship codes
            "RH11", "RH12", "RH13", "RH21", "RH22", "RH23", "RH31", "RH32", "RH33",
            
            // Special allowances
            "SPLALLOW", "FIELDALLOW", "TECPAY", "FLYALLOW", "SUBALLOW",
            
            // Deductions
            "DSOP", "AGIF", "AFPF", "ITAX", "IT", "EHCESS", "PF", "GPF",
            
            // Other components
            "CONVALLOW", "WASHALLOW", "KIALLOW", "HAIRCUTALLOW",
            
            // Extended military codes
            "UNIFORM", "MESS", "CLUB", "CANTEEN", "MEDICAL", "FAMILY",
            "EDUCATION", "TRANSPORT", "FUEL", "MAINTENANCE", "INSURANCE"
        ])
    }
}
