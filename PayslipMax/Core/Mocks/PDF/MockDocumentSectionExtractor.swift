import Foundation
import PDFKit

/// Mock implementation of DocumentSectionExtractorProtocol for testing purposes.
///
/// This mock service simulates document section extraction functionality without
/// requiring actual PDF processing. It provides controllable behavior
/// for testing section extraction scenarios.
///
/// - Note: This is exclusively for testing and should never be used in production code.
final class MockDocumentSectionExtractor: DocumentSectionExtractorProtocol {
    
    // MARK: - Properties
    
    /// The document sections to return from extraction operations
    var mockDocumentSections: [DocumentSection] = []
    
    /// Controls whether operations should fail
    var shouldFail = false
    
    // MARK: - Initialization
    
    init() {
        // Set up default mock sections
        setupDefaultMockSections()
    }
    
    // MARK: - Public Methods
    
    /// Resets all mock service state to default values.
    func reset() {
        setupDefaultMockSections()
        shouldFail = false
    }
    
    /// Mock implementation of document section extraction
    /// - Parameters:
    ///   - document: The PDF document (ignored in mock)
    ///   - structure: The identified document structure (used to determine mock response)
    /// - Returns: The configured mock document sections
    func extractDocumentSections(from document: PDFDocument, structure: DocumentStructure) -> [DocumentSection] {
        if shouldFail {
            return []
        }
        
        // Return different sections based on structure for more realistic testing
        switch structure {
        case .armyFormat:
            return mockDocumentSections.filter { ["personal", "earnings", "deductions", "contact"].contains($0.name) }
        case .navyFormat:
            return mockDocumentSections.filter { ["personal", "earnings", "deductions"].contains($0.name) }
        case .airForceFormat:
            return mockDocumentSections.filter { ["personal", "earnings", "contact"].contains($0.name) }
        case .genericFormat, .unknown:
            return mockDocumentSections
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up default mock sections for testing
    private func setupDefaultMockSections() {
        mockDocumentSections = [
            DocumentSection(
                name: "personal",
                text: "Name: John Doe\nRank: Captain\nService No: 12345",
                bounds: nil,
                pageIndex: 0
            ),
            DocumentSection(
                name: "earnings",
                text: "Basic Pay: 50000\nDA: 15000\nHRA: 12000",
                bounds: nil,
                pageIndex: 0
            ),
            DocumentSection(
                name: "deductions",
                text: "Income Tax: 5000\nPF: 3000\nESI: 500",
                bounds: nil,
                pageIndex: 0
            ),
            DocumentSection(
                name: "contact",
                text: "For queries: support@payslipmax.com\nPhone: (011) 1234-5678",
                bounds: nil,
                pageIndex: 0
            )
        ]
    }
}