import Foundation
import CoreGraphics

/// Service responsible for handling pre-Nov 2023 payslip formats
/// Provides legacy compatibility while integrating with enhanced spatial processing
final class LegacyFormatHandler {
    
    // MARK: - Properties
    
    /// Enhanced military pattern extractor for spatial validation
    private let militaryExtractor: MilitaryPatternExtractor
    
    /// Spatial data extraction service for modern processing
    private let spatialExtractor: SpatialDataExtractionService?
    
    /// Validation service for legacy-specific rules
    private let validationService: LegacyValidationService
    
    // MARK: - Initialization
    
    /// Initializes the legacy format handler
    /// - Parameters:
    ///   - militaryExtractor: Military pattern extractor with spatial capabilities
    ///   - spatialExtractor: Optional spatial data extraction service
    ///   - validationService: Legacy validation service
    init(
        militaryExtractor: MilitaryPatternExtractor,
        spatialExtractor: SpatialDataExtractionService? = nil,
        validationService: LegacyValidationService = LegacyValidationService()
    ) {
        self.militaryExtractor = militaryExtractor
        self.spatialExtractor = spatialExtractor
        self.validationService = validationService
    }
    
    // MARK: - Public Interface
    
    /// Detects and processes legacy payslip formats with modern enhancements
    /// - Parameters:
    ///   - structuredDocument: Document with positional elements
    ///   - fallbackText: Fallback text for legacy processing
    /// - Returns: Extracted financial data optimized for legacy formats
    /// - Throws: LegacyFormatError for processing failures
    func processLegacyFormat(
        structuredDocument: StructuredDocument,
        fallbackText: String? = nil
    ) async throws -> [String: Double] {
        
        let formatType = detectFormatType(from: structuredDocument)
        print("[LegacyFormatHandler] Detected format type: \(formatType)")
        
        var extractedData: [String: Double] = [:]
        
        switch formatType {
        case .preNov2023Military:
            extractedData = try await processPreNov2023Military(
                document: structuredDocument,
                fallbackText: fallbackText
            )
            
        case .preNov2023Civilian:
            extractedData = try await processPreNov2023Civilian(
                document: structuredDocument,
                fallbackText: fallbackText
            )
            
        case .modernFormat:
            // Use enhanced spatial processing for modern formats
            if let spatialExtractor = spatialExtractor {
                extractedData = try await spatialExtractor.extractFinancialDataWithStructure(
                    from: structuredDocument,
                    fallbackText: fallbackText
                )
            } else {
                extractedData = militaryExtractor.extractFinancialDataLegacy(
                    from: fallbackText ?? ""
                )
            }
            
        case .unknown:
            // Fall back to comprehensive extraction
            extractedData = try await processUnknownFormat(
                document: structuredDocument,
                fallbackText: fallbackText
            )
        }
        
        // Apply legacy-specific validation and cleanup
        extractedData = validationService.applyLegacyFormatValidation(to: extractedData, formatType: formatType)
        
        return extractedData
    }
    
    /// Detects the payslip format type from document structure
    /// - Parameter document: Structured document to analyze
    /// - Returns: Detected format type
    func detectFormatType(from document: StructuredDocument) -> PayslipFormatType {
        guard let firstPage = document.pages.first else {
            return .unknown
        }
        
        let elements = firstPage.elements
        let combinedText = elements.map { $0.text }.joined(separator: " ").uppercased()
        
        // Check for format indicators
        let hasModernIndicators = combinedText.contains("PCDA") || 
                                 combinedText.contains("EPAYSLIP") ||
                                 combinedText.contains("DIGITAL")
        
        let hasMilitaryIndicators = combinedText.contains("ARMY") ||
                                   combinedText.contains("NAVY") ||
                                   combinedText.contains("AIR FORCE") ||
                                   combinedText.contains("DEFENCE")
        
        let hasCivilianIndicators = combinedText.contains("MINISTRY") ||
                                   combinedText.contains("DEPARTMENT") ||
                                   combinedText.contains("GOVERNMENT")
        
        // Date-based format detection
        let hasOldDateFormat = combinedText.contains("20[0-1][0-9]") || // 2010-2019
                              combinedText.contains("202[0-3]") // 2020-2023
        
        if hasModernIndicators && !hasOldDateFormat {
            return .modernFormat
        } else if hasMilitaryIndicators {
            return hasOldDateFormat ? .preNov2023Military : .modernFormat
        } else if hasCivilianIndicators {
            return hasOldDateFormat ? .preNov2023Civilian : .modernFormat
        }
        
        return .unknown
    }
    
    // MARK: - Private Implementation
    
    /// Processes pre-Nov 2023 military payslip format
    private func processPreNov2023Military(
        document: StructuredDocument,
        fallbackText: String?
    ) async throws -> [String: Double] {
        
        print("[LegacyFormatHandler] Processing pre-Nov 2023 military format")
        
        // Step 1: Try enhanced spatial extraction first
        var extractedData: [String: Double] = [:]
        
        do {
            extractedData = try await militaryExtractor.extractFinancialDataWithSpatialValidation(
                from: document
            )
            print("[LegacyFormatHandler] Spatial extraction found \(extractedData.count) components")
        } catch {
            print("[LegacyFormatHandler] Spatial extraction failed for legacy military: \(error)")
        }
        
        // Step 2: Enhance with legacy-specific patterns
        let legacyText = fallbackText ?? document.originalText.values.joined(separator: " ")
        let legacyData = extractLegacyMilitaryPatterns(from: legacyText)
        
        // Merge results, prioritizing spatial extraction
        for (key, value) in legacyData {
            if extractedData[key] == nil {
                extractedData[key] = value
            }
        }
        
        return extractedData
    }
    
    /// Processes pre-Nov 2023 civilian payslip format
    private func processPreNov2023Civilian(
        document: StructuredDocument,
        fallbackText: String?
    ) async throws -> [String: Double] {
        
        print("[LegacyFormatHandler] Processing pre-Nov 2023 civilian format")
        
        // Civilian payslips have different structure - use pattern-based extraction
        let text = fallbackText ?? document.originalText.values.joined(separator: " ")
        return validationService.extractLegacyCivilianPatterns(from: text)
    }
    
    /// Processes unknown format with comprehensive extraction
    private func processUnknownFormat(
        document: StructuredDocument,
        fallbackText: String?
    ) async throws -> [String: Double] {
        
        print("[LegacyFormatHandler] Processing unknown format with comprehensive extraction")
        
        var extractedData: [String: Double] = [:]
        
        // Try spatial extraction first if available
        if let spatialExtractor = spatialExtractor {
            do {
                extractedData = try await spatialExtractor.extractFinancialDataWithStructure(
                    from: document,
                    fallbackText: fallbackText
                )
            } catch {
                print("[LegacyFormatHandler] Spatial extraction failed for unknown format: \(error)")
            }
        }
        
        // Enhance with military patterns
        let text = fallbackText ?? document.originalText.values.joined(separator: " ")
        let militaryData = militaryExtractor.extractFinancialDataLegacy(from: text)
        
        // Merge results
        for (key, value) in militaryData {
            if extractedData[key] == nil {
                extractedData[key] = value
            }
        }
        
        return extractedData
    }
    
    /// Extracts data using legacy military patterns
    private func extractLegacyMilitaryPatterns(from text: String) -> [String: Double] {
        return militaryExtractor.extractFinancialDataLegacy(from: text)
    }
    
}

// MARK: - Supporting Types

/// Types of payslip formats for legacy support
enum PayslipFormatType: String, CaseIterable {
    case preNov2023Military = "pre_nov_2023_military"
    case preNov2023Civilian = "pre_nov_2023_civilian"
    case modernFormat = "modern_format"
    case unknown = "unknown"
    
    var description: String {
        switch self {
        case .preNov2023Military:
            return "Pre-November 2023 Military Format"
        case .preNov2023Civilian:
            return "Pre-November 2023 Civilian Format"
        case .modernFormat:
            return "Modern Format (Post-November 2023)"
        case .unknown:
            return "Unknown Format"
        }
    }
}

/// Error types for legacy format processing
enum LegacyFormatError: Error, LocalizedError {
    case formatDetectionFailure
    case unsupportedFormat(String)
    case processingFailure(String)
    
    var errorDescription: String? {
        switch self {
        case .formatDetectionFailure:
            return "Failed to detect payslip format type"
        case .unsupportedFormat(let format):
            return "Unsupported format: \(format)"
        case .processingFailure(let message):
            return "Legacy format processing failed: \(message)"
        }
    }
}
