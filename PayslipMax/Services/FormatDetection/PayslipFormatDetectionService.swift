import Foundation
import PDFKit

/// Service responsible for detecting payslip formats
class PayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    
    // MARK: - Dependencies
    
    private let textExtractionService: TextExtractionServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes the service with dependencies
    /// - Parameter textExtractionService: Service for extracting text from PDFs
    init(textExtractionService: TextExtractionServiceProtocol) {
        self.textExtractionService = textExtractionService
    }
    
    // MARK: - Public Methods
    
    /// Detects the format of a payslip from PDF data. Handles text extraction asynchronously.
    /// - Parameter data: The PDF data to analyze
    /// - Returns: The detected payslip format
    func detectFormat(_ data: Data) async -> PayslipFormat {
        // Create PDF document
        guard let document = PDFDocument(data: data) else {
            print("[PayslipFormatDetectionService] Could not create PDF document")
            return .unknown // Return unknown format for invalid PDFs
        }
        
        // Extract text from PDF (now async)
        let extractedText = await textExtractionService.extractText(from: document)
        
        // Detect format from extracted text
        return detectFormat(fromText: extractedText)
    }
    
    /// Detects the format of a payslip from extracted text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: The detected payslip format
    func detectFormat(fromText text: String) -> PayslipFormat {
        print("[PayslipFormatDetectionService] Detecting format from \(text.count) characters of text")
        
        // Unified defense keywords combining military, PCDA, and service-specific terms
        let defenseKeywords = [
            // Service branches
            "ARMY", "NAVY", "AIR FORCE", "DEFENCE", "MILITARY",
            // PCDA and defense accounting
            "PCDA", "PRINCIPAL CONTROLLER", "DEFENCE ACCOUNTS", "STATEMENT OF ACCOUNT",
            // Service-specific identifiers
            "SERVICE NO & NAME", "SERVICE NO", "RANK",
            // Defense-specific financial components
            "DSOP", "AGIF", "MSP", "MILITARY SERVICE PAY"
        ]
        
        if defenseKeywords.contains(where: { text.uppercased().contains($0) }) {
            print("[PayslipFormatDetectionService] Detected defense format")
            return .defense
        }
        
        // Default to unknown format if no defense keywords are detected
        print("[PayslipFormatDetectionService] No defense format detected, using unknown")
        return .unknown
    }
} 