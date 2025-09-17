//
//  MilitaryPatternExtractorProtocol.swift
//  PayslipMax
//
//  Created for military pattern extraction protocol
//  Enables dependency injection and SOLID compliance
//

import Foundation

/// Protocol for military pattern extraction services
/// Defines the interface for extracting financial data from military payslips
protocol MilitaryPatternExtractorProtocol {

    /// Extracts financial data with spatial validation from structured documents
    /// - Parameter structuredDocument: Document with positional elements
    /// - Returns: Dictionary mapping military pay component keys to values
    /// - Throws: MilitaryExtractionError for processing failures
    func extractFinancialDataWithSpatialValidation(
        from structuredDocument: StructuredDocument
    ) async throws -> [String: Double]

    /// Extracts financial data using legacy pattern matching
    /// - Parameter text: Raw text from military payslip
    /// - Returns: Dictionary mapping military pay component keys to values
    func extractFinancialDataLegacy(from text: String) -> [String: Double]
}

/// Protocol for spatial analysis processing
protocol SpatialAnalysisProcessorProtocol {

    /// Processes spatial analysis for military payslips
    /// - Parameter elements: Positional elements from document
    /// - Parameter analyzer: Spatial analyzer service
    /// - Returns: Dictionary of extracted military components
    /// - Throws: MilitaryExtractionError for processing failures
    func extractUsingSpatialAnalysis(
        elements: [PositionalElement],
        analyzer: SpatialAnalyzerProtocol
    ) async throws -> [String: Double]
}

/// Protocol for pattern matching processing
protocol PatternMatchingProcessorProtocol {

    /// Extracts amount using regex pattern
    /// - Parameter pattern: Regular expression pattern
    /// - Parameter text: Text to search in
    /// - Returns: Extracted amount or nil if not found
    func extractAmountWithPattern(_ pattern: String, from text: String) -> Double?
}

/// Protocol for grade inference service
protocol GradeInferenceServiceProtocol {

    /// Infers military grade from BasicPay amount
    /// - Parameter amount: BasicPay amount
    /// - Returns: Inferred grade string or nil if cannot determine
    func inferGradeFromBasicPay(_ amount: Double) -> String?
}
