import Foundation
import PDFKit

/// Container for PDF and extraction-related services.
@MainActor
class PDFServicesContainer {

    /// Whether to use mock implementations for testing.
    let useMocks: Bool

    init(useMocks: Bool = false) {
        self.useMocks = useMocks
    }

    /// Creates a PDF service.
    func makePDFService() -> PDFServiceProtocol {
        // Always use real implementation for now
        return PDFServiceAdapter(DefaultPDFService())
    }

    /// Creates a PDF extractor.
    func makePDFExtractor() -> PDFExtractorProtocol {
        // Use the adapter for the new Universal Parser system
        // This ensures we're using the single source of truth
        return PDFExtractorAdapter()
    }

    /// Creates a text extraction service
    func makeTextExtractionService() -> TextExtractionServiceProtocol {
        // Unified architecture: Use PDFTextExtractionService with adapter
        return PDFTextExtractionServiceAdapter(PDFTextExtractionService())
    }

    /// Creates a payslip format detection service
    func makePayslipFormatDetectionService() -> PayslipFormatDetectionServiceProtocol {
        return PayslipFormatDetectionService(textExtractionService: makeTextExtractionService())
    }

    /// Creates a document structure identifier service
    func makeDocumentStructureIdentifier() -> DocumentStructureIdentifierProtocol {
        return DocumentStructureIdentifier()
    }

    /// Creates a document section extractor service
    func makeDocumentSectionExtractor() -> DocumentSectionExtractorProtocol {
        return DocumentSectionExtractor()
    }

    /// Creates a personal info section parser service
    func makePersonalInfoSectionParser() -> PersonalInfoSectionParserProtocol {
        return PersonalInfoSectionParser()
    }

    /// Creates a financial data section parser service
    func makeFinancialDataSectionParser() -> FinancialDataSectionParserProtocol {
        return FinancialDataSectionParser()
    }

    /// Creates a contact info section parser service
    func makeContactInfoSectionParser() -> ContactInfoSectionParserProtocol {
        return ContactInfoSectionParser()
    }

    /// Creates a document metadata extractor service
    func makeDocumentMetadataExtractor() -> DocumentMetadataExtractorProtocol {
        return DocumentMetadataExtractor()
    }

    /// Creates a tabular data extractor service.
    func makeTabularDataExtractor() -> TabularDataExtractorProtocol {
        // Always return real implementation for now
        // TODO: Add mock support when MockTabularDataExtractor is implemented
        return TabularDataExtractor()
    }

    /// Creates a pattern matching service.
    func makePatternMatchingService() -> PatternMatchingServiceProtocol {
        // Always return real implementation for now
        // TODO: Add mock support when MockPatternMatchingService is implemented
        return PatternMatchingService()
    }

    /// Creates a PDF extraction trainer for ML training and improvement
    func makePDFExtractionTrainer(dataStore: TrainingDataStore) -> PDFExtractionTrainer {
        #if DEBUG
        if useMocks {
            return PDFExtractionTrainer(dataStore: dataStore)
        }
        #endif
        return PDFExtractionTrainer(dataStore: dataStore)
    }

    /// Creates a contact info extractor for payslip contact data extraction
    func makeContactInfoExtractor() -> ContactInfoExtractor {
        return ContactInfoExtractor()
    }
}
