import Foundation

/// Defines the interface for the feature flag system.
/// Feature flags allow for controlled rollout of features and A/B testing.
protocol FeatureFlagProtocol {
    /// Checks if a feature is enabled.
    /// - Parameter feature: The feature to check.
    /// - Returns: `true` if the feature is enabled, otherwise `false`.
    func isEnabled(_ feature: Feature) -> Bool
    
    /// Checks if a feature is enabled for a specific user.
    /// - Parameters:
    ///   - feature: The feature to check.
    ///   - userID: The ID of the user to check for.
    /// - Returns: `true` if the feature is enabled for the user, otherwise `false`.
    func isEnabled(_ feature: Feature, for userID: String) -> Bool
    
    /// Overrides the state of a feature flag.
    /// - Parameters:
    ///   - feature: The feature to override.
    ///   - enabled: Whether the feature should be enabled or disabled.
    func setOverride(_ feature: Feature, enabled: Bool)
    
    /// Clears any override for a feature flag, returning it to its default state.
    /// - Parameter feature: The feature to clear the override for.
    func clearOverride(_ feature: Feature)
    
    /// Clears all feature flag overrides.
    func clearAllOverrides()
    
    /// Refreshes the feature flag configuration from the remote source.
    /// - Parameter completion: A closure to call when the refresh is complete, with a boolean indicating success.
    func refreshConfiguration(completion: @escaping (Bool) -> Void)
}

/// Represents a feature that can be toggled.
enum Feature: String, CaseIterable {
    // Core Features
    
    /// Military parser optimization that reduces memory usage at the cost of speed
    case optimizedMilitaryParsing
    
    /// Use parallelized PDF text extraction on supported documents
    case parallelizedTextExtraction
    
    /// New pattern matching engine with improved accuracy
    case enhancedPatternMatching
    
    // User Interface Features
    
    /// New dashboard UI with graphical summaries
    case enhancedDashboard
    
    /// Military-specific insights and summaries
    case militaryInsights
    
    /// Detailed PDF annotation and markup capabilities
    case pdfAnnotation
    
    // Analytics Features
    
    /// Extended application analytics
    case enhancedAnalytics
    
    /// Payslip data aggregation for trends (anonymized)
    case dataAggregation
    
    /// Local-only, PII-safe diagnostics bundle generation and structured logs
    case localDiagnostics
    
    // Experimental Features
    
    /// AI-powered payslip categorization
    case aiCategorization
    
    /// Document camera auto-capture with quality detection
    case smartCapture
    
    /// Cloud backup integration
    case cloudBackup

    // Parsing Hardening (Legacy PCDA)
    /// Gate for legacy PCDA detector hardening (Phase 11)
    case pcdaLegacyHardening
    /// Gate for legacy PCDA spatial extractor hardening (Phase 12)
    case pcdaSpatialHardening
    /// Gate for validator enforcement in legacy PCDA path (Phase 13)
    case pcdaValidatorEnforcement
    /// Gate for builder gating & totals preference (Phase 14)
    case pcdaBuilderGating
    /// Gate for unified numeric & currency normalization (Phase 16)
     case numericNormalizationV2
} 