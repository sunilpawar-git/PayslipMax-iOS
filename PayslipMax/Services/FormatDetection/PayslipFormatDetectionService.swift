import Foundation
import PDFKit

/// Service responsible for detecting payslip formats
class PayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {

    // MARK: - Dependencies

    private let textExtractionService: TextExtractionServiceProtocol
    private let smartFormatDetector: SmartFormatDetectorProtocol?

    // MARK: - Configuration

    private let useAI: Bool

    // MARK: - Initialization

    /// Initializes the service with dependencies
    /// - Parameter textExtractionService: Service for extracting text from PDFs
    /// - Parameter smartFormatDetector: Optional AI-powered format detector
    /// - Parameter useAI: Whether to use AI-powered detection when available
    init(textExtractionService: TextExtractionServiceProtocol,
         smartFormatDetector: SmartFormatDetectorProtocol? = nil,
         useAI: Bool = true) {
        self.textExtractionService = textExtractionService
        self.smartFormatDetector = smartFormatDetector
        self.useAI = useAI
    }
    
    // MARK: - Public Methods
    
    /// Detects the format of a payslip from PDF data. Handles text extraction asynchronously.
    /// - Parameter data: The PDF data to analyze
    /// - Returns: The detected payslip format
    func detectFormat(_ data: Data) async -> PayslipFormat {
        // Create PDF document
        guard let document = PDFDocument(data: data) else {
            print("[PayslipFormatDetectionService] Could not create PDF document")
            return .standard // Return standard format for invalid PDFs
        }

        return await detectFormat(from: document)
    }

    /// Detects the format of a payslip from PDF document using AI when available
    /// - Parameter document: The PDF document to analyze
    /// - Returns: The detected payslip format
    func detectFormat(from document: PDFDocument) async -> PayslipFormat {
        // Extract text from PDF
        let extractedText = await textExtractionService.extractText(from: document)

        // Use AI-powered detection if available and enabled
        if useAI, let smartDetector = smartFormatDetector {
            let (format, confidence) = await smartDetector.detectFormat(from: document)

            // Only use AI result if confidence is high enough
            if confidence > 0.7 {
                print("[PayslipFormatDetectionService] AI detected format: \(format.rawValue) with confidence: \(confidence)")
                return format
            } else {
                print("[PayslipFormatDetectionService] AI confidence too low (\(confidence)), falling back to rule-based detection")
            }
        }

        // Fallback to rule-based detection
        return detectFormat(fromText: extractedText)
    }

    /// Detects format with detailed analysis including confidence and reasoning
    /// - Parameter document: The PDF document to analyze
    /// - Returns: Detailed format detection result with confidence and reasoning
    func detectFormatDetailed(from document: PDFDocument) async -> FormatDetectionResult? {
        guard useAI, let smartDetector = smartFormatDetector else {
            return nil
        }

        let extractedText = await textExtractionService.extractText(from: document)
        return smartDetector.analyzeDocumentStructure(text: extractedText)
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