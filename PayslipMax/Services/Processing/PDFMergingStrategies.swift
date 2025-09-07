import Foundation

/// Strategies for merging conflicting extraction results
enum ResultMergingStrategy: String, CaseIterable {
    /// Prefer enhanced spatial extraction results
    case enhancedPreferred = "Enhanced Preferred"
    /// Prefer legacy pattern-based extraction results
    case legacyPreferred = "Legacy Preferred"
    /// Always choose the higher numeric value
    case higherValue = "Higher Value"
    /// Always choose the lower numeric value
    case lowerValue = "Lower Value"
    /// Use intelligent selection based on context
    case intelligentSelection = "Intelligent Selection"
}

/// Handles conflict resolution strategies for PDF result merging
final class PDFMergingStrategies {
    
    // MARK: - Properties
    
    private let configuration: ResultMergingConfiguration
    
    // MARK: - Initialization
    
    init(configuration: ResultMergingConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Public Interface
    
    /// Resolves conflicts between numeric values using specified strategy
    /// - Parameters:
    ///   - key: Data key being resolved
    ///   - legacyValue: Value from legacy extraction
    ///   - enhancedValue: Value from enhanced extraction
    ///   - strategy: Resolution strategy
    /// - Returns: Resolved value or nil if both are nil
    func resolveValueConflict(
        key: String,
        legacyValue: Double?,
        enhancedValue: Double?,
        strategy: ResultMergingStrategy
    ) -> Double? {
        
        switch (legacyValue, enhancedValue) {
        case (nil, nil):
            return nil
            
        case (let value?, nil):
            print("[PDFMergingStrategies] Using legacy value for \(key): \(value)")
            return value
            
        case (nil, let value?):
            print("[PDFMergingStrategies] Using enhanced value for \(key): \(value)")
            return value
            
        case (let legacyVal?, let enhancedVal?):
            return resolveConflictingValues(
                key: key,
                legacy: legacyVal,
                enhanced: enhancedVal,
                strategy: strategy
            )
        }
    }
    
    /// Resolves conflicts between string values
    /// - Parameters:
    ///   - key: Data key being resolved
    ///   - legacyValue: Value from legacy extraction
    ///   - enhancedValue: Value from enhanced extraction
    ///   - strategy: Resolution strategy
    /// - Returns: Resolved string value or nil
    func resolveStringConflict(
        key: String,
        legacyValue: String?,
        enhancedValue: String?,
        strategy: ResultMergingStrategy
    ) -> String? {
        
        switch (legacyValue, enhancedValue) {
        case (nil, nil):
            return nil
        case (let value?, nil):
            return value
        case (nil, let value?):
            return value
        case (let legacy?, let enhanced?):
            return strategy == .legacyPreferred ? legacy : enhanced
        }
    }
    
    // MARK: - Private Implementation
    
    /// Resolves conflicts between two non-nil values
    /// - Parameters:
    ///   - key: Data key being resolved
    ///   - legacy: Legacy value
    ///   - enhanced: Enhanced value
    ///   - strategy: Resolution strategy
    /// - Returns: Resolved value
    private func resolveConflictingValues(
        key: String,
        legacy: Double,
        enhanced: Double,
        strategy: ResultMergingStrategy
    ) -> Double {
        
        let difference = abs(legacy - enhanced)
        let relativeDifference = difference / max(legacy, enhanced)
        
        // If values are very close, prefer enhanced
        if relativeDifference < configuration.conflictThreshold {
            print("[PDFMergingStrategies] Values close for \(key), using enhanced: \(enhanced)")
            return enhanced
        }
        
        // Apply strategy for conflicting values
        switch strategy {
        case .enhancedPreferred:
            print("[PDFMergingStrategies] Conflict for \(key) (L:\(legacy) E:\(enhanced)), using enhanced")
            return enhanced
            
        case .legacyPreferred:
            print("[PDFMergingStrategies] Conflict for \(key) (L:\(legacy) E:\(enhanced)), using legacy")
            return legacy
            
        case .higherValue:
            let chosen = max(legacy, enhanced)
            print("[PDFMergingStrategies] Conflict for \(key), using higher value: \(chosen)")
            return chosen
            
        case .lowerValue:
            let chosen = min(legacy, enhanced)
            print("[PDFMergingStrategies] Conflict for \(key), using lower value: \(chosen)")
            return chosen
            
        case .intelligentSelection:
            return selectIntelligentValue(key: key, legacy: legacy, enhanced: enhanced)
        }
    }
    
    /// Applies intelligent selection based on key characteristics and value patterns
    /// - Parameters:
    ///   - key: Data key being resolved
    ///   - legacy: Legacy value
    ///   - enhanced: Enhanced value
    /// - Returns: Intelligently selected value
    private func selectIntelligentValue(key: String, legacy: Double, enhanced: Double) -> Double {
        // For known financial codes, use domain knowledge
        if isEarningsCode(key) {
            // For earnings, enhanced extraction is typically more accurate due to spatial context
            print("[PDFMergingStrategies] Earnings code \(key), preferring enhanced: \(enhanced)")
            return enhanced
        } else if isDeductionCode(key) {
            // For deductions, also prefer enhanced due to better table parsing
            print("[PDFMergingStrategies] Deduction code \(key), preferring enhanced: \(enhanced)")
            return enhanced
        } else if isTotalCode(key) {
            // For totals, prefer the higher value as it's less likely to be a partial match
            let chosen = max(legacy, enhanced)
            print("[PDFMergingStrategies] Total code \(key), using higher value: \(chosen)")
            return chosen
        } else {
            // For unknown codes, prefer enhanced extraction
            print("[PDFMergingStrategies] Unknown code \(key), preferring enhanced: \(enhanced)")
            return enhanced
        }
    }
    
    /// Checks if a key represents an earnings code
    /// - Parameter key: Key to check
    /// - Returns: True if key is an earnings code
    private func isEarningsCode(_ key: String) -> Bool {
        let earningsCodes = ["BPAY", "DA", "MSP", "RH12", "TPTA", "TPTADA", "basic", "allowance"]
        return earningsCodes.contains { key.uppercased().contains($0.uppercased()) }
    }
    
    /// Checks if a key represents a deduction code
    /// - Parameter key: Key to check
    /// - Returns: True if key is a deduction code
    private func isDeductionCode(_ key: String) -> Bool {
        let deductionCodes = ["DSOP", "AGIF", "ITAX", "EHCESS", "tax", "deduction"]
        return deductionCodes.contains { key.uppercased().contains($0.uppercased()) }
    }
    
    /// Checks if a key represents a total/summary code
    /// - Parameter key: Key to check
    /// - Returns: True if key is a total code
    private func isTotalCode(_ key: String) -> Bool {
        let totalCodes = ["credits", "debits", "total", "gross", "net"]
        return totalCodes.contains { key.lowercased().contains($0.lowercased()) }
    }
}
