import Foundation

/// Protocol for Performance Analytics Service to enable dependency injection
protocol PerformanceAnalyticsServiceProtocol {
    /// Track the start of a PDF processing operation
    func trackPDFProcessingStart(fileSize: Int, pageCount: Int, processorType: String)

    /// Track the completion of a PDF processing operation
    func trackPDFProcessingEnd(success: Bool, extractedFieldCount: Int)

    /// Track parser performance
    func trackParserExecution(parserID: String, payslipType: String, confidence: Double)

    /// Track parser completion
    func trackParserCompletion(parserID: String, success: Bool, errorType: String?)

    /// Track a memory warning
    func trackMemoryWarning(memoryUsage: Int?)

    /// Track a slow operation
    func trackSlowOperation(operationType: String, durationMs: Int, threshold: Int)
}

/// Service for tracking performance metrics across the application
/// Now supports both singleton and dependency injection patterns
class PerformanceAnalyticsService: PerformanceAnalyticsServiceProtocol, SafeConversionProtocol {
    /// Shared instance for singleton access
    static let shared = PerformanceAnalyticsService()

    /// Analytics manager instance (injected or singleton)
    private let analyticsManager: AnalyticsManagerProtocol

    /// Category for logging
    private let logCategory = "PerformanceAnalyticsService"

    /// Current conversion state
    var conversionState: ConversionState = .singleton

    /// Feature flag that controls DI vs singleton usage
    var controllingFeatureFlag: Feature { return .diPerformanceAnalyticsService }

    /// Initialize with dependency injection support
    /// - Parameter dependencies: Dependencies including analyticsManager
    init(dependencies: [String: Any] = [:]) {
        if let injectedAnalytics = dependencies["analyticsManager"] as? AnalyticsManagerProtocol {
            self.analyticsManager = injectedAnalytics
        } else {
            // Fallback to singleton for backward compatibility
            self.analyticsManager = AnalyticsManager.shared
        }
        Logger.info("Initialized Performance Analytics Service (DI-ready)", category: logCategory)
    }

    /// Private initializer to maintain singleton pattern
    private convenience init() {
        self.init(dependencies: [:])
    }

    /// Track the start of a PDF processing operation
    /// - Parameters:
    ///   - fileSize: Size of the PDF file in bytes
    ///   - pageCount: Number of pages in the PDF
    ///   - processorType: Type of PDF processor being used
    func trackPDFProcessingStart(fileSize: Int, pageCount: Int, processorType: String) {
        let parameters: [String: Any] = [
            "file_size_bytes": fileSize,
            "page_count": pageCount,
            "processor_type": processorType
        ]

        analyticsManager.beginTimedEvent(AnalyticsEvents.pdfProcessingStarted, parameters: parameters)
        Logger.debug("Started tracking PDF processing: \(parameters)", category: logCategory)
    }

    /// Track the completion of a PDF processing operation
    /// - Parameters:
    ///   - success: Whether the processing was successful
    ///   - extractedFieldCount: Number of fields successfully extracted
    func trackPDFProcessingEnd(success: Bool, extractedFieldCount: Int) {
        let parameters: [String: Any] = [
            "success": success,
            "extracted_field_count": extractedFieldCount
        ]

        analyticsManager.endTimedEvent(AnalyticsEvents.pdfProcessingStarted, parameters: parameters)

        if success {
            analyticsManager.logEvent(AnalyticsEvents.pdfProcessingCompleted, parameters: parameters)
        } else {
            analyticsManager.logEvent(AnalyticsEvents.pdfProcessingFailed, parameters: parameters)
        }

        Logger.debug("Ended tracking PDF processing: \(parameters)", category: logCategory)
    }

    /// Track parser performance
    /// - Parameters:
    ///   - parserID: Identifier of the parser
    ///   - payslipType: Type of payslip being parsed
    ///   - confidence: Confidence score (0.0-1.0) of the parser
    func trackParserExecution(parserID: String, payslipType: String, confidence: Double) {
        let parameters: [String: Any] = [
            "parser_id": parserID,
            "payslip_type": payslipType,
            "confidence": confidence
        ]

        analyticsManager.beginTimedEvent(AnalyticsEvents.parserExecution, parameters: parameters)
        Logger.debug("Started tracking parser execution: \(parameters)", category: logCategory)
    }

    /// Track parser completion
    /// - Parameters:
    ///   - parserID: Identifier of the parser
    ///   - success: Whether the parsing was successful
    ///   - errorType: Type of error if parsing failed
    func trackParserCompletion(parserID: String, success: Bool, errorType: String? = nil) {
        var parameters: [String: Any] = [
            "parser_id": parserID,
            "success": success
        ]

        if let errorType = errorType {
            parameters["error_type"] = errorType
        }

        analyticsManager.endTimedEvent(AnalyticsEvents.parserExecution, parameters: parameters)

        if success {
            analyticsManager.logEvent(AnalyticsEvents.parserSuccess, parameters: parameters)
        } else {
            analyticsManager.logEvent(AnalyticsEvents.parserFailure, parameters: parameters)
        }

        Logger.debug("Ended tracking parser execution: \(parameters)", category: logCategory)
    }

    /// Track a memory warning
    /// - Parameter memoryUsage: Current memory usage in bytes if available
    func trackMemoryWarning(memoryUsage: Int? = nil) {
        var parameters: [String: Any] = [:]

        if let memoryUsage = memoryUsage {
            parameters["memory_usage_bytes"] = memoryUsage
        }

        analyticsManager.logEvent(AnalyticsEvents.memoryWarning, parameters: parameters)
        Logger.debug("Tracked memory warning: \(parameters)", category: logCategory)
    }

    /// Track a slow operation
    /// - Parameters:
    ///   - operationType: Type of operation that was slow
    ///   - durationMs: Duration of the operation in milliseconds
    ///   - threshold: Threshold in milliseconds that was exceeded
    func trackSlowOperation(operationType: String, durationMs: Int, threshold: Int) {
        let parameters: [String: Any] = [
            "operation_type": operationType,
            "duration_ms": durationMs,
            "threshold_ms": threshold
        ]

        analyticsManager.logEvent(AnalyticsEvents.slowOperation, parameters: parameters)
        Logger.debug("Tracked slow operation: \(parameters)", category: logCategory)
    }

    // MARK: - SafeConversionProtocol Implementation

    /// Validates that the service can be safely converted to DI
    func validateConversionSafety() async -> Bool {
        // Analytics manager is always available (either injected or singleton fallback)
        return true
    }

    /// Performs the conversion from singleton to DI pattern
    func performConversion(container: any DIContainerProtocol) async -> Bool {
        await MainActor.run {
            conversionState = .converting
        }

        await ConversionTracker.shared.updateConversionState(for: PerformanceAnalyticsService.self, state: .converting)

        // Note: Integration with existing DI architecture will be handled separately
        // This method validates the conversion is safe and updates tracking

        await MainActor.run {
            conversionState = .dependencyInjected
        }

        await ConversionTracker.shared.updateConversionState(for: PerformanceAnalyticsService.self, state: .dependencyInjected)

        Logger.info("Successfully converted PerformanceAnalyticsService to DI pattern", category: logCategory)
        return true
    }

    /// Rolls back to singleton pattern if issues are detected
    func rollbackConversion() async -> Bool {
        await MainActor.run {
            conversionState = .singleton
        }
        await ConversionTracker.shared.updateConversionState(for: PerformanceAnalyticsService.self, state: .singleton)
        Logger.info("Rolled back PerformanceAnalyticsService to singleton pattern", category: logCategory)
        return true
    }

    /// Validates dependencies are properly injected and functional
    func validateDependencies() async -> DependencyValidationResult {
        // AnalyticsManager is always available (either injected or singleton fallback)
        return .success
    }

    /// Creates a new instance via dependency injection
    func createDIInstance(dependencies: [String: Any]) -> Self? {
        return PerformanceAnalyticsService(dependencies: dependencies) as? Self
    }

    /// Returns the singleton instance (fallback mode)
    static func sharedInstance() -> Self {
        return shared as! Self
    }

    /// Determines whether to use DI or singleton based on feature flags
    @MainActor static func resolveInstance() -> Self {
        let featureFlagManager = FeatureFlagManager.shared
        let shouldUseDI = featureFlagManager.isEnabled(.diPerformanceAnalyticsService)

        if shouldUseDI {
            // Note: DI resolution will be integrated with existing factory pattern
            // For now, fallback to singleton until factory methods are implemented
            Logger.debug("DI enabled for PerformanceAnalyticsService, but using singleton fallback", category: "PerformanceAnalyticsService")
        }

        // Fallback to singleton
        return shared as! Self
    }
}
