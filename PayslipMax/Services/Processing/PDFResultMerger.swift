import Foundation

/// Service for merging legacy and enhanced PDF extraction results
/// Uses intelligent conflict resolution to produce optimal combined results
final class PDFResultMerger {
    
    // MARK: - Properties
    
    /// Configuration for merging operations
    private let configuration: ResultMergingConfiguration
    
    /// Strategies handler for conflict resolution
    private let strategies: PDFMergingStrategies
    
    /// Validation handler for result quality assurance
    private let validation: PDFMergingValidation
    
    // MARK: - Initialization
    
    /// Initializes the result merger with configuration and dependencies
    /// - Parameters:
    ///   - configuration: Merging configuration
    ///   - strategies: Strategies handler (optional, defaults to new instance)
    ///   - validation: Validation handler (optional, defaults to new instance)
    init(
        configuration: ResultMergingConfiguration = .default,
        strategies: PDFMergingStrategies? = nil,
        validation: PDFMergingValidation? = nil
    ) {
        self.configuration = configuration
        self.strategies = strategies ?? PDFMergingStrategies(configuration: configuration)
        self.validation = validation ?? PDFMergingValidation(configuration: configuration)
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
            
            let resolvedValue = strategies.resolveValueConflict(
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
        let validatedResult = await validation.validateMergedResults(mergedResult)
        
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
            
            let resolvedValue = strategies.resolveStringConflict(
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
    
}
