import Foundation
import CoreGraphics

/// Enhanced data extraction service that leverages spatial intelligence for better accuracy
/// Integrates with existing pipeline while adding positional element awareness
final class SpatialDataExtractionService {

    // MARK: - Properties

    /// Legacy pattern-based extractor for backward compatibility
    private let patternExtractor: FinancialPatternExtractor

    /// Spatial analyzer for understanding element relationships
    private let spatialAnalyzer: SpatialAnalyzerProtocol

    /// Column boundary detector for table structure analysis
    private let columnDetector: ColumnBoundaryDetector

    /// Row associator for organizing elements into rows
    private let rowAssociator: RowAssociator

    /// Section classifier for identifying earnings vs deductions
    private let sectionClassifier: SpatialSectionClassifier

    /// Utility service for extraction operations
    private let extractionUtilities: SpatialExtractionUtilities

    /// Universal systems integrator for Phase 5 integration
    private let universalIntegrator: UniversalSystemsIntegrator

    // MARK: - Initialization

    /// Initializes the spatial data extraction service with required dependencies
    /// - Parameters:
    ///   - patternExtractor: Legacy pattern extractor
    ///   - spatialAnalyzer: Spatial analysis service
    ///   - columnDetector: Column boundary detection service
    ///   - rowAssociator: Row association service
    ///   - sectionClassifier: Section classification service
    ///   - extractionUtilities: Utility service for extraction operations
    ///   - universalIntegrator: Universal systems integrator for Phase 5
    init(
        patternExtractor: FinancialPatternExtractor,
        spatialAnalyzer: SpatialAnalyzerProtocol,
        columnDetector: ColumnBoundaryDetector,
        rowAssociator: RowAssociator,
        sectionClassifier: SpatialSectionClassifier,
        extractionUtilities: SpatialExtractionUtilities = SpatialExtractionUtilities(),
        universalIntegrator: UniversalSystemsIntegrator
    ) {
        self.patternExtractor = patternExtractor
        self.spatialAnalyzer = spatialAnalyzer
        self.columnDetector = columnDetector
        self.rowAssociator = rowAssociator
        self.sectionClassifier = sectionClassifier
        self.extractionUtilities = extractionUtilities
        self.universalIntegrator = universalIntegrator
    }

    // MARK: - Public Interface

    /// Extracts financial data using spatial intelligence with fallback to legacy patterns
    /// - Parameters:
    ///   - structuredDocument: Document with positional elements
    ///   - fallbackText: Fallback text for legacy extraction (optional)
    /// - Returns: Dictionary mapping data keys to values
    /// - Throws: SpatialExtractionError for processing failures
    func extractFinancialDataWithStructure(
        from structuredDocument: StructuredDocument,
        fallbackText: String? = nil
    ) async throws -> [String: Double] {

        let startTime = Date()
        var extractedData = [String: Double]()

        do {
            // Step 1: Extract using spatial intelligence
            let spatialData = try await extractUsingSpatialAnalysis(structuredDocument)
            extractedData.merge(spatialData) { current, _ in current }

            print("[SpatialDataExtractionService] Spatial extraction found \(spatialData.count) items")

        } catch {
            print("[SpatialDataExtractionService] Spatial extraction failed: \(error), falling back to patterns")
        }

        // Step 2: If spatial extraction didn't find enough data, use universal systems
        if extractedData.count < 3 {
            let fallbackTextToUse = fallbackText ?? structuredDocument.originalText.values.joined(separator: " ")

            // Phase 5: Use universal systems integrator for comprehensive coverage
            extractedData = await universalIntegrator.enhanceExtractionWithUniversalSystems(
                existingData: extractedData,
                documentText: fallbackTextToUse,
                minimumThreshold: 3
            )
        }

        let processingTime = Date().timeIntervalSince(startTime)
        print("[SpatialDataExtractionService] Total extraction completed in \(String(format: "%.3f", processingTime))s")

        return extractedData
    }

    /// Extracts financial data from text using legacy patterns (backward compatibility)
    /// - Parameter text: Text to extract from
    /// - Returns: Dictionary mapping data keys to values
    func extractFinancialData(from text: String) -> [String: Double] {
        return patternExtractor.extractFinancialData(from: text)
    }

    /// Analyzes document structure and extracts section-aware data
    /// - Parameter structuredDocument: Document with positional elements
    /// - Returns: Section-categorized financial data
    /// - Throws: SpatialExtractionError for analysis failures
    func extractSectionAwareData(
        from structuredDocument: StructuredDocument
    ) async throws -> SectionAwareFinancialData {

        guard let firstPage = structuredDocument.pages.first else {
            throw SpatialExtractionError.noElementsFound
        }

        let elements = firstPage.elements

        // Step 1: Classify elements into sections
        let sectionClassification = try await sectionClassifier.classifyIntoSections(elements)

        // Step 2: Extract data from each section
        var earningsData: [String: Double] = [:]
        var deductionsData: [String: Double] = [:]

        if !sectionClassification.earningsElements.isEmpty {
            earningsData = try await extractFromElements(
                sectionClassification.earningsElements,
                expectedType: .earnings
            )
        }

        if !sectionClassification.deductionsElements.isEmpty {
            deductionsData = try await extractFromElements(
                sectionClassification.deductionsElements,
                expectedType: .deductions
            )
        }

        return SectionAwareFinancialData(
            earnings: earningsData,
            deductions: deductionsData,
            sectionConfidence: sectionClassification.confidence,
            metadata: [
                "earningsElementCount": String(sectionClassification.earningsElements.count),
                "deductionsElementCount": String(sectionClassification.deductionsElements.count)
            ]
        )
    }

    // MARK: - Private Implementation

    /// Extracts financial data using spatial analysis
    private func extractUsingSpatialAnalysis(
        _ structuredDocument: StructuredDocument
    ) async throws -> [String: Double] {

        guard let firstPage = structuredDocument.pages.first else {
            throw SpatialExtractionError.noElementsFound
        }

        let elements = firstPage.elements
        guard elements.count >= 4 else {
            throw SpatialExtractionError.insufficientElements(count: elements.count)
        }

        // Step 1: Find element pairs using spatial relationships
        let elementPairs = try await spatialAnalyzer.findRelatedElements(elements, tolerance: nil)

        // Step 2: Extract financial data from high-confidence pairs
        var extractedData: [String: Double] = [:]

        for pair in elementPairs where pair.isHighConfidence {
            if let amount = extractionUtilities.extractFinancialAmount(from: pair.value.text) {
                let code = extractionUtilities.cleanFinancialCode(pair.label.text)

                if extractionUtilities.isValidFinancialCode(code) {
                    extractedData[code] = amount
                    print("[SpatialDataExtractionService] Spatial pair: \(code) = \(amount)")
                }
            }
        }

        // Step 3: If we have table structure, use enhanced table extraction
        if extractedData.count >= 2 {
            let tableData = try await extractFromTableStructure(elements)

            // Merge table data, prioritizing spatial pairs for conflicts
            for (key, value) in tableData {
                if extractedData[key] == nil {
                    extractedData[key] = value
                }
            }
        }

        // Step 4: Phase 5 Enhancement - Use universal systems for comprehensive coverage
        // Even with spatial analysis, we might miss some codes that universal search can find
        if extractedData.count < 10 { // Only if we haven't found many components yet
            let documentText = structuredDocument.originalText.values.joined(separator: " ")

            // Use universal systems integrator to complement spatial analysis
            extractedData = await universalIntegrator.complementSpatialAnalysis(
                spatialData: extractedData,
                documentText: documentText
            )
        }

        return extractedData
    }

    /// Extracts data from table structure using column/row analysis
    private func extractFromTableStructure(
        _ elements: [PositionalElement]
    ) async throws -> [String: Double] {

        // Step 1: Detect column boundaries
        let _ = try await columnDetector.detectColumnBoundaries(from: elements)

        // Step 2: Associate elements into rows
        let tableRows = try await rowAssociator.associateElementsIntoRows(elements)

        // Step 3: Extract data from structured table
        var tableData: [String: Double] = [:]

        for row in tableRows {
            let rowElements = row.elements

            // Look for label-value pairs within the row
            for i in 0..<(rowElements.count - 1) {
                let labelElement = rowElements[i]
                let valueElement = rowElements[i + 1]

                if let amount = extractionUtilities.extractFinancialAmount(from: valueElement.text) {
                    let code = extractionUtilities.cleanFinancialCode(labelElement.text)

                    if extractionUtilities.isValidFinancialCode(code) {
                        tableData[code] = amount
                    }
                }
            }
        }

        return tableData
    }

    /// Extracts financial data from a specific set of elements
    private func extractFromElements(
        _ elements: [PositionalElement],
        expectedType: FinancialDataType
    ) async throws -> [String: Double] {

        var sectionData: [String: Double] = [:]

        // Find element pairs within this section
        let elementPairs = try await spatialAnalyzer.findRelatedElements(elements, tolerance: nil)

        for pair in elementPairs where pair.confidence >= 0.6 {
            if let amount = extractionUtilities.extractFinancialAmount(from: pair.value.text) {
                let code = extractionUtilities.cleanFinancialCode(pair.label.text)

                if extractionUtilities.isValidFinancialCode(code) && extractionUtilities.isCodeForType(code, type: expectedType) {
                    sectionData[code] = amount
                }
            }
        }

        return sectionData
    }

}

// MARK: - Supporting Types

/// Section-aware financial data result
struct SectionAwareFinancialData {
    let earnings: [String: Double]
    let deductions: [String: Double]
    let sectionConfidence: Double
    let metadata: [String: String]
}

/// Error types for spatial extraction
enum SpatialExtractionError: Error, LocalizedError {
    case noElementsFound
    case insufficientElements(count: Int)
    case spatialAnalysisFailure(String)
    case sectionClassificationFailure(String)

    var errorDescription: String? {
        switch self {
        case .noElementsFound:
            return "No positional elements found for extraction"
        case .insufficientElements(let count):
            return "Insufficient elements for spatial extraction: \(count)"
        case .spatialAnalysisFailure(let message):
            return "Spatial analysis failed: \(message)"
        case .sectionClassificationFailure(let message):
            return "Section classification failed: \(message)"
        }
    }
}
