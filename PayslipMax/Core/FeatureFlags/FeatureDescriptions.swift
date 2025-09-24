import Foundation

/// Provides descriptions for feature flags in the UI
struct FeatureDescriptions {
    
    /// Gets a description for the given feature.
    /// - Parameter feature: The feature to get a description for.
    /// - Returns: A description of the feature.
    static func description(for feature: Feature) -> String {
        switch feature {
        case .optimizedMilitaryParsing:
            return "Reduces memory usage at the cost of speed"
        case .parallelizedTextExtraction:
            return "Uses multiple threads for faster PDF text extraction"
        case .enhancedPatternMatching:
            return "Improved pattern recognition for payslip data"
        case .enhancedDashboard:
            return "New dashboard with graphical summaries"
        case .militaryInsights:
            return "Military-specific insights and analysis"
        case .pdfAnnotation:
            return "Markup and annotation tools for PDF documents"
        case .enhancedAnalytics:
            return "Extended application analytics"
        case .dataAggregation:
            return "Anonymized data aggregation for trends"
        case .aiCategorization:
            return "AI-powered payslip categorization"
        case .smartCapture:
            return "Automatic document capture with quality detection"
        case .cloudBackup:
            return "Secure cloud backup functionality"
        case .dependencyInjectionPhase2:
            return "Enables Phase 2 dependency injection migration"
        case .diGlobalLoadingManager:
            return "DI migration for GlobalLoadingManager"
        case .diAnalyticsManager:
            return "DI migration for AnalyticsManager"
        case .diTabTransitionCoordinator:
            return "DI migration for TabTransitionCoordinator"
        case .diAppearanceManager:
            return "DI migration for AppearanceManager"
        case .diPerformanceMetrics:
            return "DI migration for PerformanceMetrics"
            
        // Phase 2D-Gamma: Critical Services (NEW!)
        case .diGlobalOverlaySystem:
            return "NEW! Global overlay system with dependency injection (Phase 2D-Gamma)"
        case .diPrintService:
            return "NEW! PDF printing service with dependency injection (Phase 2D-Gamma)"
            
        // Phase 2D-Beta: Analytics Services
        case .diFirebaseAnalyticsProvider:
            return "Firebase analytics provider with DI (Phase 2D-Beta)"
        case .diPerformanceAnalyticsService:
            return "Performance analytics service with DI (Phase 2D-Beta)"
        case .diUserAnalyticsService:
            return "User analytics service with DI (Phase 2D-Beta)"
            
        // Phase 2D-Beta: Utility Services
        case .diPDFDocumentCache:
            return "PDF document cache with DI (Phase 2D-Beta)"
        case .diPDFProcessingCache:
            return "PDF processing cache with DI (Phase 2D-Beta)"
        case .diErrorHandlingUtility:
            return "Error handling utility with DI (Phase 2D-Beta)"
        case .diFinancialCalculationUtility:
            return "Financial calculation utility with DI (Phase 2D-Beta)"
        case .diPayslipFormatterService:
            return "Payslip formatter service with DI (Phase 2D-Beta)"
        case .diPDFValidationService:
            return "PDF validation service with DI (Phase 2D-Beta)"
        case .diGamificationCoordinator:
            return "Gamification coordinator with DI (Phase 2D-Beta)"
            
        // Phase 2D: PDF Services
        case .diPayslipPDFService:
            return "Payslip PDF service with DI (Phase 2D)"
        case .diPayslipPDFFormattingService:
            return "PDF formatting service with DI (Phase 2D)"
        case .diPayslipPDFURLService:
            return "PDF URL service with DI (Phase 2D)"
        case .diPayslipShareService:
            return "Payslip share service with DI (Phase 2D)"
            
        // Phase 2D: Performance & Monitoring Services
        case .diBackgroundTaskCoordinator, .diClassificationCacheManager, .diDualSectionPerformanceMonitor,
             .diParallelPayCodeProcessor, .diTaskCoordinatorWrapper, .diTaskMonitor, .diViewPerformanceTracker:
            return "Performance & monitoring service with DI (Phase 2D)"
            
        // Phase 2D: UI Services
        case .diAppTheme:
            return "App theme service with DI (Phase 2D)"
        case .diPerformanceDebugSettings:
            return "Performance debug settings with DI (Phase 2D)"
            
        // Phase 2D: Core System Services
        case .diPayslipLearningSystem, .diPayslipPatternManagerCompat, .diUnifiedPatternDefinitions,
             .diUnifiedPatternMatcher, .diPDFManager, .diFeatureFlagConfiguration, .diFeatureFlagManager:
            return "Core system service with DI (Phase 2D)"
        }
    }
}
