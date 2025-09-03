import Foundation
import PDFKit

/// AI-Enhanced parsing coordinator that bridges PDFParsingCoordinatorProtocol and AI integration
@MainActor
class AIEnhancedParsingCoordinator: PDFParsingCoordinatorProtocol {
    
    // MARK: - Properties
    
    private let enhancedPDFCoordinator: EnhancedPDFExtractionCoordinator
    private let basePDFOrchestrator: PDFParsingOrchestrator
    private let abbreviationManager: AbbreviationManager
    
    // MARK: - Initialization
    
    init(abbreviationManager: AbbreviationManager) {
        self.abbreviationManager = abbreviationManager
        self.basePDFOrchestrator = PDFParsingOrchestrator(abbreviationManager: abbreviationManager)
        
        // Create AI-enhanced coordinator with LiteRT integration
        let liteRTService = LiteRTService.shared
        let basePDFCoordinator = PDFExtractionCoordinator()
        
        self.enhancedPDFCoordinator = EnhancedPDFExtractionCoordinator(
            basePDFCoordinator: basePDFCoordinator,
            liteRTService: liteRTService,
            useLiteRTProcessing: true
        )
        
        print("[AIEnhancedParsingCoordinator] Initialized with AI-enhanced PDF processing")
    }
    
    // MARK: - PDFParsingCoordinatorProtocol Implementation
    
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem? {
        print("[AIEnhancedParsingCoordinator] Processing PDF with AI enhancement")
        
        // First try AI-enhanced extraction
        if let aiResult = enhancedPDFCoordinator.extractPayslipData(from: pdfDocument) {
            print("[AIEnhancedParsingCoordinator] ✅ AI extraction successful")
            return aiResult
        }
        
        print("[AIEnhancedParsingCoordinator] ⚠️ AI extraction failed, falling back to standard parsing")
        
        // Fallback to standard parsing
        return try await basePDFOrchestrator.parsePayslip(pdfDocument: pdfDocument)
    }
    
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipItem? {
        print("[AIEnhancedParsingCoordinator] Processing PDF with specific parser: \(parserName)")
        
        // Use the base orchestrator for parser-specific processing
        return try await basePDFOrchestrator.parsePayslip(pdfDocument: pdfDocument, using: parserName)
    }
    
    nonisolated func selectBestParser(for text: String) -> PayslipParser? {
        // Delegate to base orchestrator for parser selection
        return basePDFOrchestrator.selectBestParser(for: text)
    }
    
    nonisolated func extractFullText(from document: PDFDocument) -> String? {
        // For synchronous compatibility, use the standard extraction
        // AI-enhanced async extraction will be used automatically in parsePayslip methods
        return basePDFOrchestrator.extractFullText(from: document)
    }
    
    nonisolated func getAvailableParsers() -> [PayslipParser] {
        // Return available parsers from base orchestrator
        return basePDFOrchestrator.getAvailableParsers()
    }
}
