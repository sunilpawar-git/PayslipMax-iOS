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
    
    /// Detects the format of a payslip from PDF data
    /// - Parameter data: The PDF data to analyze
    /// - Returns: The detected payslip format
    func detectFormat(_ data: Data) -> PayslipFormat {
        // Create PDF document
        guard let document = PDFDocument(data: data) else {
            print("[PayslipFormatDetectionService] Could not create PDF document")
            return .standard // Return standard format for invalid PDFs
        }
        
        // Extract text from PDF
        let extractedText = textExtractionService.extractText(from: document)
        
        // Detect format from extracted text
        return detectFormat(fromText: extractedText)
    }
    
    /// Detects the format of a payslip from extracted text
    /// - Parameter text: The text extracted from a PDF
    /// - Returns: The detected payslip format
    func detectFormat(fromText text: String) -> PayslipFormat {
        print("[PayslipFormatDetectionService] Detecting format from \(text.count) characters of text")
        
        // Check for military-specific keywords
        let militaryKeywords = ["ARMY", "NAVY", "AIR FORCE", "DEFENCE", "MILITARY", "SERVICE NO & NAME"]
        if militaryKeywords.contains(where: { text.uppercased().contains($0) }) {
            print("[PayslipFormatDetectionService] Detected military format")
            return .military
        }
        
        // Check for PCDA-specific keywords
        let pcdaKeywords = ["PCDA", "PRINCIPAL CONTROLLER", "DEFENCE ACCOUNTS", "STATEMENT OF ACCOUNT"]
        if pcdaKeywords.contains(where: { text.uppercased().contains($0) }) {
            print("[PayslipFormatDetectionService] Detected PCDA format")
            return .pcda
        }
        
        // Check for standard format keywords
        let standardKeywords = [
            "PAYSLIP", "SALARY", "INCOME", "EARNINGS", "DEDUCTIONS",
            "PAY DATE", "EMPLOYEE NAME", "GROSS PAY", "NET PAY",
            "BASIC PAY", "TOTAL EARNINGS", "TOTAL DEDUCTIONS"
        ]
        
        // If text is empty or contains standard keywords, return standard format
        if text.isEmpty || standardKeywords.contains(where: { text.uppercased().contains($0) }) {
            print("[PayslipFormatDetectionService] Detected standard format")
            return .standard
        }
        
        // Default to unknown format if no specific format is detected
        print("[PayslipFormatDetectionService] No specific format detected, using unknown")
        return .unknown
    }
} 