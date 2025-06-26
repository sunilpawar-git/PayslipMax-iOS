import Foundation
import PDFKit

/// Main orchestrator for PDF parsing operations
/// Coordinates all parsing components while maintaining the original interface
@MainActor
final class PDFParsingOrchestrator: PDFParsingCoordinatorProtocol, PDFTextExtractionDelegate {
    
    // MARK: - Dependencies
    
    nonisolated private let parserSelector: PDFParserSelector
    nonisolated private let textExtractor: PDFTextExtractionWrapper
    private let parsingEngine: PDFParsingEngine
    private let resultCache: PDFParsingCache
    nonisolated private let memoryTracker: PDFMemoryTracker
    private let militaryHandler: MilitaryPayslipHandler
    
    // MARK: - Initialization
    
    init(
        abbreviationManager: AbbreviationManager,
        parserRegistry: PayslipParserRegistry? = nil,
        textExtractionService: PDFTextExtractionService? = nil
    ) {
        self.parserSelector = PDFParserSelector(
            parserRegistry: parserRegistry ?? StandardPayslipParserRegistry(),
            abbreviationManager: abbreviationManager
        )
        self.textExtractor = PDFTextExtractionWrapper(
            textExtractionService: textExtractionService ?? PDFTextExtractionService()
        )
        self.parsingEngine = PDFParsingEngine()
        self.resultCache = PDFParsingCache()
        self.memoryTracker = PDFMemoryTracker()
        self.militaryHandler = MilitaryPayslipHandler()
        
        // Set up delegation
        self.textExtractor.delegate = self
    }
    
    // MARK: - PDFParsingCoordinatorProtocol Implementation
    
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem? {
        // Check cache first
        if let cachedResult = resultCache.getCachedResult(for: pdfDocument) {
            print("[PDFParsingOrchestrator] Using cached result")
            return cachedResult.payslipItem
        }
        
        // Extract text
        guard let fullText = textExtractor.extractFullText(from: pdfDocument) else {
            print("[PDFParsingOrchestrator] Failed to extract text from PDF")
            return nil
        }
        
        // Select and run parsers
        let parsingResult = try await parsingEngine.parseWithMultipleParsers(
            pdfDocument: pdfDocument,
            fullText: fullText,
            parserSelector: parserSelector
        )
        
        // Handle military format fallback if needed
        let finalResult = try await militaryHandler.handleMilitaryFallback(
            currentResult: parsingResult,
            pdfDocument: pdfDocument,
            fullText: fullText
        )
        
        // Cache successful results
        if let result = finalResult, result.confidence > .low {
            resultCache.cacheResult(result, for: pdfDocument)
        }
        
        return finalResult?.payslipItem
    }
    
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipItem? {
        return try await parsingEngine.parseWithSpecificParser(
            pdfDocument: pdfDocument,
            parserName: parserName,
            parserSelector: parserSelector
        )
    }
    
    nonisolated func selectBestParser(for text: String) -> PayslipParser? {
        return parserSelector.selectBestParser(for: text)
    }
    
    func clearCache() {
        resultCache.clearCache()
    }
    
    nonisolated func getAvailableParsers() -> [PayslipParser] {
        return parserSelector.getAllParsers()
    }
    
    nonisolated func extractFullText(from document: PDFDocument) -> String? {
        return textExtractor.extractFullText(from: document)
    }
    
    // MARK: - PDFTextExtractionDelegate
    
    nonisolated func textExtraction(didUpdateMemoryUsage memoryUsage: UInt64, delta: UInt64) {
        memoryTracker.trackMemoryUsage(memoryUsage: memoryUsage, delta: delta)
    }
} 