//
//  SpatialAnalysisProcessor.swift
//  PayslipMax
//
//  Created for spatial analysis processing of military payslips
//  Extracted from MilitaryPatternExtractor to maintain file size compliance
//

import Foundation

/// Processor for spatial analysis of military payslips
/// Handles spatial relationship validation and component extraction
final class SpatialAnalysisProcessor: SpatialAnalysisProcessorProtocol {

    // MARK: - Properties

    /// Validation service for military-specific rules
    private let validationService: MilitaryValidationService

    // MARK: - Initialization

    /// Initializes the spatial analysis processor
    /// - Parameter validationService: Military validation service
    init(validationService: MilitaryValidationService = MilitaryValidationService()) {
        self.validationService = validationService
    }

    // MARK: - Public Interface

    /// Extracts military financial data using spatial analysis
    /// - Parameter elements: Positional elements from document
    /// - Parameter analyzer: Spatial analyzer service
    /// - Returns: Dictionary of extracted military components
    /// - Throws: MilitaryExtractionError for processing failures
    func extractUsingSpatialAnalysis(
        elements: [PositionalElement],
        analyzer: SpatialAnalyzerProtocol
    ) async throws -> [String: Double] {

        // Step 1: Find element pairs using spatial relationships
        let elementPairs = try await analyzer.findRelatedElements(elements, tolerance: nil)

        // Step 2: Filter for military-specific patterns
        var militaryData: [String: Double] = [:]

        for pair in elementPairs where pair.isHighConfidence {
            let labelText = pair.label.text.uppercased()
            let valueText = pair.value.text

            // Check if this is a military pay component
            if let militaryCode = validationService.identifyMilitaryComponent(from: labelText),
               let amount = validationService.extractFinancialAmount(from: valueText) {

                // Validate spatial relationship for military payslips
                if validationService.isValidMilitaryPair(label: pair.label, value: pair.value, code: militaryCode) {
                    militaryData[militaryCode] = amount
                    print("[SpatialAnalysisProcessor] Spatial military pair: \(militaryCode) = \(amount)")
                }
            }
        }

        return militaryData
    }
}
