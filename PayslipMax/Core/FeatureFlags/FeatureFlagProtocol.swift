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
    
    /// Simplified payslip parsing with only essential fields (BPAY, DA, MSP, DSOP, AGIF, Tax)
    case simplifiedPayslipParsing

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

    // Experimental Features

    /// AI-powered payslip categorization
    case aiCategorization

    /// Document camera auto-capture with quality detection
    case smartCapture

    /// Cloud backup integration
    case cloudBackup

    // Phase 2: Dependency Injection Migration Flags

    /// Enables dependency injection for critical managers (Phase 2 rollout)
    case dependencyInjectionPhase2

    /// Enables DI for GlobalLoadingManager
    case diGlobalLoadingManager

    /// Enables DI for AnalyticsManager
    case diAnalyticsManager

    /// Enables DI for TabTransitionCoordinator
    case diTabTransitionCoordinator

    /// Enables DI for AppearanceManager
    case diAppearanceManager

    /// Enables DI for PerformanceMetrics
    case diPerformanceMetrics

    // Phase 2D: Remaining Service DI Flags

    // Analytics Services
    /// Enables DI for FirebaseAnalyticsProvider
    case diFirebaseAnalyticsProvider

    /// Enables DI for PerformanceAnalyticsService
    case diPerformanceAnalyticsService

    /// Enables DI for UserAnalyticsService
    case diUserAnalyticsService

    // PDF Processing Services
    /// Enables DI for PDFDocumentCache
    case diPDFDocumentCache

    /// Enables DI for PayslipPDFService
    case diPayslipPDFService

    /// Enables DI for PayslipPDFFormattingService
    case diPayslipPDFFormattingService

    /// Enables DI for PayslipPDFURLService
    case diPayslipPDFURLService

    /// Enables DI for PayslipShareService
    case diPayslipShareService

    /// Enables DI for PrintService
    case diPrintService

    // Performance & Monitoring Services
    /// Enables DI for BackgroundTaskCoordinator
    case diBackgroundTaskCoordinator

    /// Enables DI for ClassificationCacheManager
    case diClassificationCacheManager

    /// Enables DI for DualSectionPerformanceMonitor
    case diDualSectionPerformanceMonitor

    /// Enables DI for ParallelPayCodeProcessor
    case diParallelPayCodeProcessor

    /// Enables DI for TaskCoordinatorWrapper
    case diTaskCoordinatorWrapper

    /// Enables DI for TaskMonitor
    case diTaskMonitor

    /// Enables DI for ViewPerformanceTracker
    case diViewPerformanceTracker

    // UI & Appearance Services
    /// Enables DI for GlobalOverlaySystem
    case diGlobalOverlaySystem

    /// Enables DI for AppTheme
    case diAppTheme

    /// Enables DI for PerformanceDebugSettings
    case diPerformanceDebugSettings

    // Data & Utility Services
    /// Enables DI for ErrorHandlingUtility
    case diErrorHandlingUtility

    /// Enables DI for FinancialCalculationUtility
    case diFinancialCalculationUtility

    /// Enables DI for PayslipFormatterService
    case diPayslipFormatterService

    /// Enables DI for PDFValidationService
    case diPDFValidationService

    /// Enables DI for PDFProcessingCache
    case diPDFProcessingCache

    /// Enables DI for GamificationCoordinator
    case diGamificationCoordinator

    // Core System Services
    /// Enables DI for PayslipLearningSystem
    case diPayslipLearningSystem

    /// Enables DI for PayslipPatternManagerCompat
    case diPayslipPatternManagerCompat

    /// Enables DI for UnifiedPatternDefinitions
    case diUnifiedPatternDefinitions

    /// Enables DI for UnifiedPatternMatcher
    case diUnifiedPatternMatcher

    /// Enables DI for PDFManager
    case diPDFManager

    /// Enables DI for FeatureFlagConfiguration
    case diFeatureFlagConfiguration

    /// Enables DI for FeatureFlagManager
    case diFeatureFlagManager
}
