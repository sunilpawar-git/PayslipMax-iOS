import Foundation
import PDFKit

/// Enhanced PDF processor that combines legacy text extraction with spatial intelligence
/// Provides dual-mode processing with intelligent fallback mechanisms for maximum accuracy
/// Integrates seamlessly with existing ModularPayslipProcessingPipeline architecture
final class EnhancedPDFProcessor: PDFProcessorProtocol {
    
    // MARK: - Properties
    
    /// Legacy PDF service for backward compatibility
    private let legacyPDFService: PDFService
    
    /// Spatial data extraction service for enhanced processing
    private let spatialExtractionService: SpatialDataExtractionService
    
    /// Performance monitoring service
    private let performanceMonitor: PDFProcessingPerformanceMonitor
    
    /// Result merging service for combining legacy and enhanced results
    private let resultMerger: PDFResultMerger
    
    /// Configuration for processing operations
    private let configuration: EnhancedProcessingConfiguration
    
    // MARK: - Initialization
    
    /// Initializes the enhanced PDF processor with required dependencies
    /// - Parameters:
    ///   - legacyPDFService: Existing PDF service for backward compatibility
    ///   - spatialExtractionService: Enhanced spatial extraction service
    ///   - performanceMonitor: Performance monitoring service
    ///   - resultMerger: Service for merging legacy and enhanced results
    ///   - configuration: Processing configuration
    init(
        legacyPDFService: PDFService,
        spatialExtractionService: SpatialDataExtractionService,
        performanceMonitor: PDFProcessingPerformanceMonitor = PDFProcessingPerformanceMonitor(),
        resultMerger: PDFResultMerger = PDFResultMerger(),
        configuration: EnhancedProcessingConfiguration = .default
    ) {
        self.legacyPDFService = legacyPDFService
        self.spatialExtractionService = spatialExtractionService
        self.performanceMonitor = performanceMonitor
        self.resultMerger = resultMerger
        self.configuration = configuration
    }
    
    // MARK: - PDFProcessorProtocol Implementation
    
    /// Extracts text and data from PDF using dual-mode processing
    /// - Parameter pdfData: PDF data to process
    /// - Returns: Dictionary mapping data keys to string values
    func extract(_ pdfData: Data) async -> [String: String] {
        let processingId = UUID().uuidString
        performanceMonitor.startProcessing(id: processingId, dataSize: pdfData.count)
        
        do {
            // Step 1: Attempt enhanced spatial extraction
            let enhancedResult = try await extractWithSpatialIntelligence(pdfData)
            
            if isResultSufficient(enhancedResult) {
                performanceMonitor.recordSuccess(id: processingId, mode: .enhanced)
                print("[EnhancedPDFProcessor] Enhanced extraction successful: \(enhancedResult.count) items")
                return convertToStringDictionary(enhancedResult)
            }
            
            // Step 2: Fallback to dual-mode processing
            let dualModeResult = try await extractWithDualMode(pdfData)
            performanceMonitor.recordSuccess(id: processingId, mode: .dualMode)
            
            print("[EnhancedPDFProcessor] Dual-mode extraction completed: \(dualModeResult.count) items")
            return convertToStringDictionary(dualModeResult)
            
        } catch {
            print("[EnhancedPDFProcessor] Enhanced extraction failed: \(error), falling back to legacy")
            
            // Step 3: Final fallback to legacy extraction
            let legacyResult = legacyPDFService.extract(pdfData)
            performanceMonitor.recordFallback(id: processingId, error: error)
            
            return legacyResult
        }
    }
    
    // MARK: - Enhanced Extraction Methods
    
    /// Extracts data using spatial intelligence for maximum accuracy
    /// - Parameter pdfData: PDF data to process
    /// - Returns: Financial data dictionary
    /// - Throws: EnhancedProcessingError for extraction failures
    private func extractWithSpatialIntelligence(_ pdfData: Data) async throws -> [String: Double] {
        print("[EnhancedPDFProcessor] Starting spatial intelligence extraction")
        
        // Extract structured document with positional elements
        let structuredDocument = try await legacyPDFService.extractStructuredText(from: pdfData)
        
        // Validate structured document quality
        guard structuredDocument.pageCount > 0 else {
            throw EnhancedProcessingError.noStructureFound
        }
        
        // Extract financial data using spatial analysis
        let financialData = try await spatialExtractionService.extractFinancialDataWithStructure(
            from: structuredDocument
        )
        
        // Validate extraction quality
        guard !financialData.isEmpty else {
            throw EnhancedProcessingError.insufficientData
        }
        
        return financialData
    }
    
    /// Extracts data using both legacy and enhanced methods for best results
    /// - Parameter pdfData: PDF data to process
    /// - Returns: Merged financial data dictionary
    /// - Throws: EnhancedProcessingError for extraction failures
    private func extractWithDualMode(_ pdfData: Data) async throws -> [String: Double] {
        print("[EnhancedPDFProcessor] Starting dual-mode extraction")
        
        async let legacyTask = extractLegacyData(pdfData)
        async let enhancedTask = extractSpatialData(pdfData)
        
        let (legacyData, spatialData) = try await (legacyTask, enhancedTask)
        
        // Merge results with intelligent conflict resolution
        let mergedData = await resultMerger.mergeFinancialResults(
            legacy: legacyData,
            enhanced: spatialData,
            strategy: configuration.mergingStrategy
        )
        
        return mergedData
    }
    
    /// Extracts data using legacy text-based patterns
    /// - Parameter pdfData: PDF data to process
    /// - Returns: Legacy financial data dictionary
    /// - Throws: EnhancedProcessingError for extraction failures
    private func extractLegacyData(_ pdfData: Data) async throws -> [String: Double] {
        let textResult = legacyPDFService.extract(pdfData)
        let combinedText = textResult.values.joined(separator: " ")
        
        guard !combinedText.isEmpty else {
            throw EnhancedProcessingError.noTextFound
        }
        
        return spatialExtractionService.extractFinancialData(from: combinedText)
    }
    
    /// Extracts data using spatial processing with fallback handling
    /// - Parameter pdfData: PDF data to process
    /// - Returns: Spatial financial data dictionary
    /// - Throws: EnhancedProcessingError for extraction failures
    private func extractSpatialData(_ pdfData: Data) async throws -> [String: Double] {
        do {
            let structuredDocument = try await legacyPDFService.extractStructuredText(from: pdfData)
            return try await spatialExtractionService.extractFinancialDataWithStructure(from: structuredDocument)
        } catch {
            // Return empty data rather than throwing, to allow dual-mode merging
            print("[EnhancedPDFProcessor] Spatial extraction failed: \(error)")
            return [:]
        }
    }
    
    // MARK: - Utility Methods
    
    /// Checks if extraction result contains sufficient data for processing
    /// - Parameter result: Financial data dictionary to validate
    /// - Returns: True if result is sufficient, false otherwise
    private func isResultSufficient(_ result: [String: Double]) -> Bool {
        return result.count >= configuration.minimumDataItemsRequired &&
               result.values.contains { $0 > 0 }
    }
    
    /// Converts numeric financial data to string dictionary for compatibility
    /// - Parameter financialData: Numeric financial data
    /// - Returns: String-based dictionary
    private func convertToStringDictionary(_ financialData: [String: Double]) -> [String: String] {
        var stringResult: [String: String] = [:]
        
        for (key, value) in financialData {
            stringResult[key] = String(format: "%.2f", value)
        }
        
        return stringResult
    }
}

// MARK: - Supporting Types

/// Configuration for enhanced PDF processing operations
struct EnhancedProcessingConfiguration {
    /// Minimum number of data items required for successful extraction
    let minimumDataItemsRequired: Int
    /// Strategy for merging legacy and enhanced results
    let mergingStrategy: ResultMergingStrategy
    /// Timeout for processing operations in seconds
    let processingTimeoutSeconds: TimeInterval
    /// Whether to enable performance monitoring
    let enablePerformanceMonitoring: Bool
    
    /// Default configuration optimized for payslip processing
    static let `default` = EnhancedProcessingConfiguration(
        minimumDataItemsRequired: 3,
        mergingStrategy: .enhancedPreferred,
        processingTimeoutSeconds: 60.0,
        enablePerformanceMonitoring: true
    )
}

/// Processing mode used for performance tracking
enum PDFProcessingMode: String {
    case enhanced = "Enhanced"
    case dualMode = "Dual Mode"
    case legacy = "Legacy"
}

/// Errors that can occur during enhanced PDF processing
enum EnhancedProcessingError: Error, LocalizedError {
    case noStructureFound
    case insufficientData
    case noTextFound
    case timeout
    case memoryError
    
    var errorDescription: String? {
        switch self {
        case .noStructureFound:
            return "No document structure found for spatial analysis"
        case .insufficientData:
            return "Insufficient data extracted from document"
        case .noTextFound:
            return "No text content found in document"
        case .timeout:
            return "Processing timeout exceeded"
        case .memoryError:
            return "Memory error during processing"
        }
    }
}

/// Protocol for PDF processing with enhanced capabilities
protocol PDFProcessorProtocol {
    /// Extracts data from PDF using available processing methods
    /// - Parameter pdfData: PDF data to process
    /// - Returns: Dictionary mapping data keys to string values
    func extract(_ pdfData: Data) async -> [String: String]
}
