import Foundation
import SwiftData
import PDFKit

// MARK: - Component Imports
// Import the modular components that make up the PayslipItem architecture
//
// This file serves as the main entry point for PayslipItem, importing all
// the modular components that were extracted to maintain the 300-line rule:
//
// - PayslipItemProtocols.swift: All protocol definitions and extensions
// - PayslipItemCore.swift: Core model class with basic properties
// - PayslipItemExtensions.swift: Codable implementation and protocol methods
// - PayslipItemFactory.swift: Factory methods and complex initialization
//
// Architecture Benefits:
// ✅ Each file under 300 lines (architecture compliant)
// ✅ Single responsibility per file
// ✅ MVVM/SOLID principles maintained
// ✅ Protocol-based design
// ✅ Zero breaking changes to public API
// ✅ Async/await patterns preserved
// ✅ DI container compatibility maintained

// The main PayslipItem class is now defined in PayslipItemCore.swift
// All extensions and factory methods are in their respective files
// This maintains backward compatibility while following architectural rules

// MARK: - Type Aliases for Backward Compatibility
/// Legacy type alias for backward compatibility
typealias PayslipItemLegacy = PayslipItem

// MARK: - Global Helper Functions
/// Creates a sample payslip for testing purposes.
/// This is a convenience function that delegates to the factory service.
func createSamplePayslip(for month: String, year: Int) -> PayslipItem {
    return PayslipItemFactory.createSample()
}

/// Creates a payslip from PDF extraction results.
/// This is a convenience function that delegates to the factory service.
func createPayslipFromExtraction(_ extractionResult: [String: Any],
                                pdfData: Data,
                                pdfURL: URL? = nil) -> PayslipItem? {
    return PayslipItemFactory.createFromExtraction(extractionResult: extractionResult,
                                                 pdfData: pdfData,
                                                 pdfURL: pdfURL)
}