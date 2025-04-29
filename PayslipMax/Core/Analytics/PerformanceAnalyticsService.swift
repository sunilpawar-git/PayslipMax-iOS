import Foundation

/// Service for tracking performance metrics across the application
class PerformanceAnalyticsService {
    /// Shared instance for singleton access
    static let shared = PerformanceAnalyticsService()
    
    /// Analytics manager instance
    private let analyticsManager = AnalyticsManager.shared
    
    /// Category for logging
    private let logCategory = "PerformanceAnalyticsService"
    
    /// Private initializer to enforce singleton pattern
    private init() {
        Logger.info("Initialized Performance Analytics Service", category: logCategory)
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
} 