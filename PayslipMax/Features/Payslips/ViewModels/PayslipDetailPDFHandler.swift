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
                do {
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
                } catch {
                    // Catch any exceptions during PDF processing
                    Logger.warning("Error processing PDF document for payslip \(payslip.id): \(error)", category: "PayslipDetailPDFHandler")

                    // Still try to extract contact info from metadata as fallback
                    extractContactInfoFromMetadata(payslipItem)
                }
            }

            // Always check if contact info is already stored in metadata
            extractContactInfoFromMetadata(payslipItem)
        }
    }

    /// Forces regeneration of PDF data to apply updated formatting (useful after currency fixes)
    func forceRegeneratePDF() async {
        guard let payslipItem = payslip as? PayslipItem else { return }

        Logger.info("Forcing PDF regeneration for payslip: \(payslip.month) \(payslip.year)", category: "PayslipPDFRegeneration")

        // Clear existing cached data
        pdfUrlCache = nil

        // Remove existing PDF file if it exists
        if let existingURL = PDFManager.shared.getPDFURL(for: payslipItem.id.uuidString) {
            try? FileManager.default.removeItem(at: existingURL)
            Logger.info("Removed existing PDF file", category: "PayslipPDFRegeneration")
        }

        // Generate new PDF with current formatting
        let payslipData = PayslipData(from: payslip)
        let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

        // Update the payslip with new PDF data - do this synchronously to avoid context issues
        await MainActor.run {
            payslipItem.pdfData = newPDFData
            self.pdfData = newPDFData
        }

        // Save the updated payslip with proper context handling
        do {
            // Save updated payslip using Sendable repository
            let payslipDTO = PayslipDTO(from: payslipItem)
            _ = try await repository.savePayslip(payslipDTO)
            Logger.info("Successfully regenerated and saved PDF with updated formatting", category: "PayslipPDFRegeneration")
        } catch {
            Logger.error("Failed to save payslip with regenerated PDF: \(error)", category: "PayslipPDFRegeneration")
        }
    }

    /// Checks if this payslip is a manual entry that needs PDF regeneration
    var needsPDFRegeneration: Bool {
        guard let payslipItem = payslip as? PayslipItem else { return false }
        return payslipItem.source == "Manual Entry"
    }

    /// Automatically handles PDF regeneration if needed (for manual entries)
    func handleAutomaticPDFRegeneration() async {
        if needsPDFRegeneration {
            Logger.info("Auto-regenerating PDF for manual entry", category: "PayslipPDFRegeneration")
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

        // Merge with any existing contact info
        if !extractedContactInfo.isEmpty {
            // Add any new emails that aren't already in our contact info
            for email in extractedContactInfo.emails {
                if !contactInfo.emails.contains(email) {
                    contactInfo.emails.append(email)
                }
            }

            // Add any new phone numbers that aren't already in our contact info
            for phone in extractedContactInfo.phoneNumbers {
                if !contactInfo.phoneNumbers.contains(phone) {
                    contactInfo.phoneNumbers.append(phone)
                }
            }

            // Add any new websites that aren't already in our contact info
            for website in extractedContactInfo.websites {
                if !contactInfo.websites.contains(website) {
                    contactInfo.websites.append(website)
                }
            }
        }
    }

    /// Extract contact information from payslip metadata
    private func extractContactInfoFromMetadata(_ payslipItem: PayslipItem) {
        // Extract emails
        if let emailsString = payslipItem.getMetadata(for: "contactEmails"), !emailsString.isEmpty {
            let emails = emailsString.split(separator: "|").map(String.init)
            for email in emails {
                if !contactInfo.emails.contains(email) {
                    contactInfo.emails.append(email)
                }
            }
        }

        // Extract phone numbers
        if let phonesString = payslipItem.getMetadata(for: "contactPhones"), !phonesString.isEmpty {
            let phones = phonesString.split(separator: "|").map(String.init)
            for phone in phones {
                if !contactInfo.phoneNumbers.contains(phone) {
                    contactInfo.phoneNumbers.append(phone)
                }
            }
        }

        // Extract websites
        if let websitesString = payslipItem.getMetadata(for: "contactWebsites"), !websitesString.isEmpty {
            let websites = websitesString.split(separator: "|").map(String.init)
            for website in websites {
                if !contactInfo.websites.contains(website) {
                    contactInfo.websites.append(website)
                }
            }
        }
    }
}
