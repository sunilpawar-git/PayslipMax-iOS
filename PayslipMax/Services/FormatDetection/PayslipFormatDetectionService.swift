import Foundation
import PDFKit

/// Service responsible for detecting payslip formats
class PayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {

    // MARK: - Dependencies

    private let textExtractionService: TextExtractionServiceProtocol
    private let jcoORDetector: JCOORFormatDetectorProtocol
    private var userHint: PayslipUserHint = .auto

    // MARK: - Initialization

    /// Initializes the service with dependencies
    /// - Parameters:
    ///   - textExtractionService: Service for extracting text from PDFs
    ///   - jcoORDetector: Detector for JCO/OR format payslips
    init(
        textExtractionService: TextExtractionServiceProtocol,
        jcoORDetector: JCOORFormatDetectorProtocol = JCOORFormatDetector()
    ) {
        self.textExtractionService = textExtractionService
        self.jcoORDetector = jcoORDetector
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

        if userHint != .auto && !text.isEmpty {
            print("[PayslipFormatDetectionService] Applying user hint \(userHint.rawValue) → biasing to defense format")
            return .defense
        }

        // Unified defense keywords combining military, PCDA, and service-specific terms
        let defenseKeywords = [
            // Service branches
            "ARMY", "NAVY", "AIR FORCE", "DEFENCE", "MILITARY",
            // PCDA and defense accounting
            "PCDA", "PRINCIPAL CONTROLLER", "DEFENCE ACCOUNTS", "STATEMENT OF ACCOUNT",
            "STATEMENT OF ACCOUNT FOR MONTH ENDING", "PAO", "SUS NO", "TASK",
            // Service-specific identifiers (including bilingual headers common on JCO/OR slips)
            "SERVICE NO & NAME", "SERVICE NO", "RANK", "EMPLOYEE ID", "PAN",
            // Defense-specific financial components and anchors
            "DSOP", "AGIF", "MSP", "MILITARY SERVICE PAY", "AMOUNT CREDITED TO BANK"
        ]

        if defenseKeywords.contains(where: { text.uppercased().contains($0) }) {
            print("[PayslipFormatDetectionService] Detected defense format")
            return .defense
        }

        // Default to unknown format if no defense keywords are detected
        print("[PayslipFormatDetectionService] No defense format detected, using unknown")
        return .unknown
    }

    /// Enhanced format detection for text-based PDFs
    /// Integrates JCO/OR detection with existing logic
    /// - Parameters:
    ///   - text: The extracted text from a PDF
    ///   - pdfData: Optional PDF data for additional validation
    /// - Returns: The detected payslip format
    func detectFormatEnhanced(fromText text: String, pdfData: Data?) async -> PayslipFormat {
        print("[PayslipFormatDetectionService] Enhanced detection from \(text.count) characters")

        // User hint takes priority
        if userHint == .jcoOr {
            print("[PayslipFormatDetectionService] User hint: JCO/OR → returning .jcoOR")
            return .jcoOR
        }

        // Check for JCO/OR markers in text
        if await jcoORDetector.isJCOORFormat(text: text) {
            print("[PayslipFormatDetectionService] JCO/OR markers detected → returning .jcoOR")
            return .jcoOR
        }

        // Fallback to existing detection logic (Officer format)
        print("[PayslipFormatDetectionService] No JCO/OR markers → using standard detection")
        return detectFormat(fromText: text)
    }

    func updateUserHint(_ hint: PayslipUserHint) {
        userHint = hint
    }
}
