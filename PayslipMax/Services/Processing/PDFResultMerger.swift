import Foundation

/// Service for merging legacy and enhanced PDF extraction results
/// Uses intelligent conflict resolution to produce optimal combined results
final class PDFResultMerger {
    
    // MARK: - Properties
    
    /// Configuration for merging operations
    private let configuration: ResultMergingConfiguration
    
    // MARK: - Initialization
    
    /// Initializes the result merger with configuration
    /// - Parameter configuration: Merging configuration
    init(configuration: ResultMergingConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Public Interface
    
    /// Merges financial results from legacy and enhanced extraction methods
    /// - Parameters:
    ///   - legacy: Results from legacy pattern-based extraction
    ///   - enhanced: Results from enhanced spatial extraction
    ///   - strategy: Strategy for resolving conflicts
    /// - Returns: Merged financial data dictionary
    func mergeFinancialResults(
        legacy: [String: Double],
        enhanced: [String: Double],
        strategy: ResultMergingStrategy
    ) async -> [String: Double] {
        
        let startTime = Date()
        var mergedResult: [String: Double] = [:]
        
        // Step 1: Add all unique keys from both sources
        let allKeys = Set(legacy.keys).union(Set(enhanced.keys))
        
        for key in allKeys {
            let legacyValue = legacy[key]
            let enhancedValue = enhanced[key]
            
            let resolvedValue = resolveValueConflict(
                key: key,
                legacyValue: legacyValue,
                enhancedValue: enhancedValue,
                strategy: strategy
            )
            
            if let value = resolvedValue {
                mergedResult[key] = value
            }
        }
        
        // Step 2: Validate merged results for consistency
        let validatedResult = await validateMergedResults(mergedResult)
        
        let processingTime = Date().timeIntervalSince(startTime)
        print("[PDFResultMerger] Merged results in \(String(format: "%.3f", processingTime))s: \(validatedResult.count) items")
        
        return validatedResult
    }
    
    /// Merges string-based results for backward compatibility
    /// - Parameters:
    ///   - legacy: Legacy string results
    ///   - enhanced: Enhanced string results
    ///   - strategy: Merging strategy
    /// - Returns: Merged string dictionary
    func mergeStringResults(
        legacy: [String: String],
        enhanced: [String: String],
        strategy: ResultMergingStrategy
    ) async -> [String: String] {
        
        var mergedResult: [String: String] = [:]
        let allKeys = Set(legacy.keys).union(Set(enhanced.keys))
        
        for key in allKeys {
            let legacyValue = legacy[key]
            let enhancedValue = enhanced[key]
            
            let resolvedValue = resolveStringConflict(
                key: key,
                legacyValue: legacyValue,
                enhancedValue: enhancedValue,
                strategy: strategy
            )
            
            if let value = resolvedValue {
                mergedResult[key] = value
            }
        }
        
        return mergedResult
    }
    
    // MARK: - Private Implementation
    
    /// Resolves conflicts between numeric values using specified strategy
    /// - Parameters:
    ///   - key: Data key being resolved
    ///   - legacyValue: Value from legacy extraction
    ///   - enhancedValue: Value from enhanced extraction
    ///   - strategy: Resolution strategy
    /// - Returns: Resolved value or nil if both are nil
    private func resolveValueConflict(
        key: String,
        legacyValue: Double?,
        enhancedValue: Double?,
        strategy: ResultMergingStrategy
    ) -> Double? {
        
        switch (legacyValue, enhancedValue) {
        case (nil, nil):
            return nil
            
        case (let value?, nil):
            print("[PDFResultMerger] Using legacy value for \(key): \(value)")
            return value
            
        case (nil, let value?):
            print("[PDFResultMerger] Using enhanced value for \(key): \(value)")
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
            print("[PDFResultMerger] Values close for \(key), using enhanced: \(enhanced)")
            return enhanced
        }
        
        // Apply strategy for conflicting values
        switch strategy {
        case .enhancedPreferred:
            print("[PDFResultMerger] Conflict for \(key) (L:\(legacy) E:\(enhanced)), using enhanced")
            return enhanced
            
        case .legacyPreferred:
            print("[PDFResultMerger] Conflict for \(key) (L:\(legacy) E:\(enhanced)), using legacy")
            return legacy
            
        case .higherValue:
            let chosen = max(legacy, enhanced)
            print("[PDFResultMerger] Conflict for \(key), using higher value: \(chosen)")
            return chosen
            
        case .lowerValue:
            let chosen = min(legacy, enhanced)
            print("[PDFResultMerger] Conflict for \(key), using lower value: \(chosen)")
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
            print("[PDFResultMerger] Earnings code \(key), preferring enhanced: \(enhanced)")
            return enhanced
        } else if isDeductionCode(key) {
            // For deductions, also prefer enhanced due to better table parsing
            print("[PDFResultMerger] Deduction code \(key), preferring enhanced: \(enhanced)")
            return enhanced
        } else if isTotalCode(key) {
            // For totals, prefer the higher value as it's less likely to be a partial match
            let chosen = max(legacy, enhanced)
            print("[PDFResultMerger] Total code \(key), using higher value: \(chosen)")
            return chosen
        } else {
            // For unknown codes, prefer enhanced extraction
            print("[PDFResultMerger] Unknown code \(key), preferring enhanced: \(enhanced)")
            return enhanced
        }
    }
    
    /// Resolves conflicts between string values
    /// - Parameters:
    ///   - key: Data key being resolved
    ///   - legacyValue: Value from legacy extraction
    ///   - enhancedValue: Value from enhanced extraction
    ///   - strategy: Resolution strategy
    /// - Returns: Resolved string value or nil
    private func resolveStringConflict(
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
    
    /// Validates merged results for consistency and quality
    /// - Parameter results: Merged results to validate
    /// - Returns: Validated results dictionary
    private func validateMergedResults(_ results: [String: Double]) async -> [String: Double] {
        var validatedResults = results
        
        // Remove obviously invalid values
        validatedResults = validatedResults.filter { key, value in
            guard value >= 0 else {
                print("[PDFResultMerger] Removing negative value for \(key): \(value)")
                return false
            }
            
            guard value <= configuration.maximumReasonableValue else {
                print("[PDFResultMerger] Removing unreasonably large value for \(key): \(value)")
                return false
            }
            
            return true
        }
        
        // Validate totals consistency if present
        validateTotalsConsistency(&validatedResults)
        
        return validatedResults
    }
    
    /// Validates that earnings and deductions totals are consistent with individual items
    /// - Parameter results: Results dictionary to validate (modified in place)
    private func validateTotalsConsistency(_ results: inout [String: Double]) {
        let earningsTotal = results["credits"] ?? results["gross_pay"]
        let deductionsTotal = results["debits"] ?? results["total_deductions"]
        
        if let expectedEarnings = earningsTotal {
            let actualEarnings = calculateEarningsSum(from: results)
            let difference = abs(expectedEarnings - actualEarnings)
            
            if difference > configuration.totalsToleranceAmount {
                print("[PDFResultMerger] Earnings total inconsistency: expected \(expectedEarnings), calculated \(actualEarnings)")
            }
        }
        
        if let expectedDeductions = deductionsTotal {
            let actualDeductions = calculateDeductionsSum(from: results)
            let difference = abs(expectedDeductions - actualDeductions)
            
            if difference > configuration.totalsToleranceAmount {
                print("[PDFResultMerger] Deductions total inconsistency: expected \(expectedDeductions), calculated \(actualDeductions)")
            }
        }
    }
    
    /// Calculates sum of earnings from individual items
    /// - Parameter results: Financial data dictionary
    /// - Returns: Sum of earnings items
    private func calculateEarningsSum(from results: [String: Double]) -> Double {
        let earningsCodes = ["BPAY", "DA", "MSP", "RH12", "TPTA", "TPTADA"]
        return earningsCodes.compactMap { results[$0] }.reduce(0, +)
    }
    
    /// Calculates sum of deductions from individual items
    /// - Parameter results: Financial data dictionary
    /// - Returns: Sum of deduction items
    private func calculateDeductionsSum(from results: [String: Double]) -> Double {
        let deductionCodes = ["DSOP", "AGIF", "ITAX", "EHCESS"]
        return deductionCodes.compactMap { results[$0] }.reduce(0, +)
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

// MARK: - Supporting Types

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

/// Configuration for result merging operations
struct ResultMergingConfiguration {
    /// Threshold for considering values as conflicting (relative difference)
    let conflictThreshold: Double
    /// Maximum reasonable value for financial data
    let maximumReasonableValue: Double
    /// Tolerance amount for totals validation
    let totalsToleranceAmount: Double
    
    /// Default configuration for payslip merging
    static let `default` = ResultMergingConfiguration(
        conflictThreshold: 0.05, // 5% difference threshold
        maximumReasonableValue: 1_000_000.0, // 10 lakh maximum
        totalsToleranceAmount: 1.0 // 1 rupee tolerance
    )
}
