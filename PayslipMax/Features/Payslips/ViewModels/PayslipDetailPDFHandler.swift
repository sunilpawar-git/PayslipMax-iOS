import SwiftUI
import SwiftData
import Foundation
import PDFKit

#if canImport(Vision)
import Vision
#endif

/// Handles PDF-specific operations for PayslipDetailViewModel
/// Responsible for PDF loading, regeneration, contact extraction, and URL management
@MainActor
class PayslipDetailPDFHandler: ObservableObject {

    // MARK: - Published Properties
    @Published var pdfData: Data?
    @Published var contactInfo: ContactInfo = ContactInfo()

    // MARK: - Private Properties
    private let payslip: AnyPayslip
    private let repository: SendablePayslipRepository
    private let pdfService: PayslipPDFService

    // MARK: - Cache Properties
    private var pdfUrlCache: URL?
    private var loadedAdditionalData = false

    // MARK: - Initialization

    init(payslip: AnyPayslip,
         repository: SendablePayslipRepository? = nil,
         pdfService: PayslipPDFService) {
        self.payslip = payslip
        self.repository = repository ?? DIContainer.shared.makeSendablePayslipRepository()
        self.pdfService = pdfService
    }

    // MARK: - Public Methods

    /// Loads additional data from the PDF if available.
    func loadAdditionalData() async {
        // Skip if we've already loaded additional data
        if loadedAdditionalData { return }

        defer { loadedAdditionalData = true }

        if let payslipItem = payslip as? PayslipItem, let pdfData = payslipItem.pdfData {
            // Set the pdfData property
            self.pdfData = pdfData

            // Use a cached PDFDocument if possible
            let pdfCacheKey = "pdf-\(payslip.id)"
            if let pdfDocument = PDFDocumentCache.shared.getDocument(for: pdfCacheKey) {
                // Use cached document
                // Unified architecture: Enhanced parsing already done during initial processing

                // Extract contact information from document text
                extractContactInfo(from: pdfDocument)
            } else {
                // Enhanced PDF document creation with better error handling for dual-section data
                if let pdfDocument = PDFDocument(data: pdfData) {
                    // Cache the PDF document for future use
                    PDFDocumentCache.shared.cacheDocument(pdfDocument, for: pdfCacheKey)

                    // Unified architecture: Enhanced parsing already done during initial processing

                    // Extract contact information from document text
                    extractContactInfo(from: pdfDocument)
                } else {
                    // PDF document creation failed - log but don't throw error
                    Logger.warning("Failed to create PDFDocument from data for payslip \(payslip.id)", category: "PayslipDetailPDFHandler")

                    // Still try to extract contact info from metadata as fallback
                    extractContactInfoFromMetadata(payslipItem)
                }
            }

            // Always check if contact info is already stored in metadata
            extractContactInfoFromMetadata(payslipItem)
        }
    }

    /// Forces regeneration of PDF data to apply updated formatting
    func forceRegeneratePDF() async {
        guard let payslipItem = payslip as? PayslipItem else { return }
        Logger.info("Forcing PDF regeneration for payslip: \(payslip.month) \(payslip.year)", category: "PayslipPDFRegeneration")
        pdfUrlCache = nil
        if let existingURL = PDFManager.shared.getPDFURL(for: payslipItem.id.uuidString) {
            try? FileManager.default.removeItem(at: existingURL)
        }
        let payslipData = PayslipData(from: payslip)
        let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)
        await MainActor.run { payslipItem.pdfData = newPDFData; self.pdfData = newPDFData }
        do {
            _ = try await repository.savePayslip(PayslipDTO(from: payslipItem))
            Logger.info("Successfully regenerated PDF", category: "PayslipPDFRegeneration")
        } catch {
            Logger.error("Failed to save regenerated PDF: \(error)", category: "PayslipPDFRegeneration")
        }
    }

    var needsPDFRegeneration: Bool {
        (payslip as? PayslipItem)?.source == "Manual Entry"
    }

    func handleAutomaticPDFRegeneration() async {
        if needsPDFRegeneration {
            await forceRegeneratePDF()
        }
    }

    /// Get the URL for the original PDF, creating or repairing it if needed
    func getPDFURL() async throws -> URL? {
        // Return cached URL if available
        if let pdfUrlCache = pdfUrlCache {
            return pdfUrlCache
        }

        do {
            // Check if this is a manual entry that needs regeneration and doesn't have valid PDF
            if needsPDFRegeneration, let payslipItem = payslip as? PayslipItem {
                if payslipItem.pdfData == nil || payslipItem.pdfData!.isEmpty {
                    Logger.info("Manual entry detected without PDF data - generating PDF for URL access", category: "PayslipPDFRegeneration")

                    // Generate PDF data if not available
                    let payslipData = PayslipData(from: payslip)
                    let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

                    // Update the payslip with new PDF data
                    await MainActor.run {
                        payslipItem.pdfData = newPDFData
                        self.pdfData = newPDFData
                    }
                }
            }

            // Get URL and cache it with enhanced error handling
            let url = try await pdfService.getPDFURL(for: payslip)
            pdfUrlCache = url
            return url
        } catch {
            // Enhanced error handling for dual-section payslips
            Logger.error("Failed to get PDF URL for payslip \(payslip.id): \(error)", category: "PayslipDetailPDFHandler")

            // If PDF URL access fails, try to generate a new formatted PDF
            if let payslipItem = payslip as? PayslipItem {
                Logger.info("Attempting to regenerate PDF for dual-section payslip", category: "PayslipDetailPDFHandler")

                do {
                    let payslipData = PayslipData(from: payslip)
                    let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

                    // Update the payslip with new PDF data
                    await MainActor.run {
                        payslipItem.pdfData = newPDFData
                        self.pdfData = newPDFData
                    }

                    // Try to get URL again with the new PDF data
                    let url = try await pdfService.getPDFURL(for: payslip)
                    pdfUrlCache = url
                    return url
                } catch {
                    Logger.error("Failed to regenerate PDF for dual-section payslip: \(error)", category: "PayslipDetailPDFHandler")
                    throw error
                }
            }

            throw error
        }
    }

    /// Get PDF data for sharing operations
    func getPDFDataForSharing() async -> Data? {
        // Check existing PDF data first
        if let payslipItem = payslip as? PayslipItem {
            // Check if this is a manual entry that needs regeneration and doesn't have valid PDF
            if needsPDFRegeneration && (payslipItem.pdfData == nil || payslipItem.pdfData!.isEmpty) {
                Logger.info("Manual entry detected without PDF data - generating new PDF", category: "PayslipSharing")

                // Generate PDF without saving to avoid context conflicts
                let payslipData = PayslipData(from: payslip)
                let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

                // Use the newly generated PDF data directly for sharing
                if !newPDFData.isEmpty {
                    Logger.info("Generated fresh PDF data for sharing (\(newPDFData.count) bytes)", category: "PayslipSharing")

                    // Update the payslip with the generated PDF for future use
                    await MainActor.run {
                        payslipItem.pdfData = newPDFData
                        self.pdfData = newPDFData
                    }

                    return newPDFData
                }
            } else if let pdfData = payslipItem.pdfData {
                // Use existing PDF data
                Logger.info("Found existing PDF data with size: \(pdfData.count) bytes", category: "PayslipSharing")

                // Validate PDF data is not empty and is valid
                if !pdfData.isEmpty && pdfData.count > 100 { // Basic size check
                    // Validate it's actually a PDF by checking header
                    let pdfHeader = Data([0x25, 0x50, 0x44, 0x46]) // %PDF in bytes
                    if pdfData.starts(with: pdfHeader) {
                        Logger.info("PDF data is valid", category: "PayslipSharing")
                        return pdfData
                    } else {
                        Logger.warning("PDF data found but doesn't have valid PDF header - regenerating", category: "PayslipSharing")

                        // Generate fresh PDF data for invalid header
                        let payslipData = PayslipData(from: payslip)
                        let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

                        if !newPDFData.isEmpty {
                            await MainActor.run {
                                payslipItem.pdfData = newPDFData
                                self.pdfData = newPDFData
                            }
                            return newPDFData
                        }
                    }
                } else {
                    Logger.warning("PDF data found but is too small (\(pdfData.count) bytes) - regenerating", category: "PayslipSharing")

                    // Generate fresh PDF data for small/invalid data
                    let payslipData = PayslipData(from: payslip)
                    let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

                    if !newPDFData.isEmpty {
                        await MainActor.run {
                            payslipItem.pdfData = newPDFData
                            self.pdfData = newPDFData
                        }
                        return newPDFData
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Private Methods

    /// Extract contact information directly from PDF text
    private func extractContactInfo(from pdfDocument: PDFDocument) {
        // Extract full text from PDF document
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                fullText += page.string ?? ""
                fullText += "\n\n"
            }
        }

        // Use the ContactInfoExtractor to get contact information
        let extractedContactInfo = ContactInfoExtractor.shared.extractContactInfo(from: fullText)

        // Merge with existing contact info
        if !extractedContactInfo.isEmpty {
            mergeContactInfo(from: extractedContactInfo)
        }
    }

    /// Merges new contact info with existing
    private func mergeContactInfo(from source: ContactInfo) {
        source.emails.forEach { if !contactInfo.emails.contains($0) { contactInfo.emails.append($0) } }
        source.phoneNumbers.forEach { if !contactInfo.phoneNumbers.contains($0) { contactInfo.phoneNumbers.append($0) } }
        source.websites.forEach { if !contactInfo.websites.contains($0) { contactInfo.websites.append($0) } }
    }

    /// Extract contact information from payslip metadata
    private func extractContactInfoFromMetadata(_ payslipItem: PayslipItem) {
        if let emails = payslipItem.getMetadata(for: "contactEmails"), !emails.isEmpty {
            emails.split(separator: "|").map(String.init).forEach { if !contactInfo.emails.contains($0) { contactInfo.emails.append($0) } }
        }
        if let phones = payslipItem.getMetadata(for: "contactPhones"), !phones.isEmpty {
            phones.split(separator: "|").map(String.init).forEach { if !contactInfo.phoneNumbers.contains($0) { contactInfo.phoneNumbers.append($0) } }
        }
        if let sites = payslipItem.getMetadata(for: "contactWebsites"), !sites.isEmpty {
            sites.split(separator: "|").map(String.init).forEach { if !contactInfo.websites.contains($0) { contactInfo.websites.append($0) } }
        }
    }
}
