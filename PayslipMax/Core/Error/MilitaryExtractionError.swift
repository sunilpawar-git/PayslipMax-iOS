//
//  MilitaryExtractionError.swift
//  PayslipMax
//
//  Created for military extraction error types
//  Extracted from MilitaryPatternExtractor to maintain file size compliance
//

import Foundation

/// Error types for military extraction
public enum MilitaryExtractionError: Error, LocalizedError {
    case noElementsFound
    case insufficientElements(count: Int)
    case spatialAnalysisFailure(String)
    case validationFailure(String)

    public var errorDescription: String? {
        switch self {
        case .noElementsFound:
            return "No positional elements found for military extraction"
        case .insufficientElements(let count):
            return "Insufficient elements for military spatial extraction: \(count)"
        case .spatialAnalysisFailure(let message):
            return "Military spatial analysis failed: \(message)"
        case .validationFailure(let message):
            return "Military validation failed: \(message)"
        }
    }
}
