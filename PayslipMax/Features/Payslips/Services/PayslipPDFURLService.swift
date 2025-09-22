import Foundation
import PDFKit
import SwiftUI

/// Service responsible for managing PDF URLs for payslips
@MainActor
class PayslipPDFURLService: PayslipPDFURLServiceProtocol {
    // MARK: - Singleton Instance
    static let shared = PayslipPDFURLService()

    // MARK: - Dependencies
    private let repository: SendablePayslipRepository
    private let validationService: PDFValidationServiceProtocol
    private let formattingService: PayslipPDFFormattingServiceProtocol
    private let pdfManager: PDFManager

    // MARK: - Initialization
    init(repository: SendablePayslipRepository? = nil,
         validationService: PDFValidationServiceProtocol? = nil,
         formattingService: PayslipPDFFormattingServiceProtocol? = nil,
         pdfManager: PDFManager? = nil) {
        self.repository = repository ?? DIContainer.shared.makeSendablePayslipRepository()
        self.validationService = validationService ?? PDFValidationService.shared
        self.formattingService = formattingService ?? PayslipPDFFormattingService.shared
        self.pdfManager = pdfManager ?? PDFManager.shared
    }

    // MARK: - Public Methods

    /// Get the URL for the payslip PDF, creating or repairing it if needed
    func getPDFURL(for payslip: AnyPayslip) async throws -> URL? {
        // Try to cast to PayslipItem - this should work for all persisted payslips
        guard let payslipItem = payslip as? PayslipItem else {
            Logger.error("Cannot cast payslip to PayslipItem for PDF URL generation - payslip type: \(type(of: payslip))", category: "PDFURLService")

            // If casting fails, try to create a formatted PDF directly from protocol data
            Logger.info("Attempting direct PDF generation from protocol data for payslip \(payslip.id)", category: "PDFURLService")
            do {
                let payslipData = PayslipData(from: payslip)
                let pdfData = formattingService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

                // Save PDF with payslip ID and return URL
                let url = try pdfManager.savePDF(data: pdfData, identifier: payslip.id.uuidString)
                Logger.info("Successfully created PDF URL for protocol payslip: \(url)", category: "PDFURLService")
                return url
            } catch {
                Logger.error("Failed to create PDF from protocol data: \(error)", category: "PDFURLService")
                throw PDFStorageError.failedToSave
            }
        }

        Logger.info("Attempting to get PDF URL for payslip \(payslipItem.id)", category: "PDFURLService")

        do {
            return try await getPDFURLWithErrorHandling(for: payslipItem, payslip: payslip)
        } catch {
            Logger.error("All PDF generation attempts failed for payslip \(payslipItem.id): \(error)", category: "PDFURLService")

            // Last resort: try to create a minimal placeholder
            do {
                let payslipData = PayslipData(from: payslip)
                let lastResortPDF = formattingService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)
                let url = try pdfManager.savePDF(data: lastResortPDF, identifier: payslipItem.id.uuidString)
                Logger.info("Created last resort PDF for payslip \(payslipItem.id)", category: "PDFURLService")
                return url
            } catch {
                Logger.error("Last resort PDF creation failed: \(error)", category: "PDFURLService")
                throw PDFStorageError.failedToSave
            }
        }
    }

    /// Internal method with detailed error handling for PDF URL generation
    private func getPDFURLWithErrorHandling(for payslipItem: PayslipItem, payslip: AnyPayslip) async throws -> URL? {

        // First, check if the PDF already exists in the PDFManager
        if let url = pdfManager.getPDFURL(for: payslipItem.id.uuidString) {
            Logger.info("Found existing PDF at \(url.path)", category: "PDFURLService")

            // Verify the file has content and is a valid PDF
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[FileAttributeKey.size] as? Int, size > 100 {
                    Logger.info("Existing PDF has valid size: \(size) bytes", category: "PDFURLService")

                    // Additional verification - check if the PDF is valid
                    do {
                        let fileData = try Data(contentsOf: url)
                        if validationService.isPDFValid(data: fileData) {
                            Logger.info("Verified existing PDF is valid", category: "PDFURLService")
                            return url
                        } else {
                            Logger.info("Existing PDF is invalid, will create formatted PDF", category: "PDFURLService")

                            // Create and save a formatted PDF
                            let payslipData = PayslipData(from: payslip)
                            let formattedPDF = formattingService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)
                            let newUrl = try pdfManager.savePDF(data: formattedPDF, identifier: payslipItem.id.uuidString)

                            // Update payslip with formatted PDF using repository
                            let payslipDTO = PayslipDTO(from: payslipItem)
                            var updatedDTO = payslipDTO
                            updatedDTO.pdfData = formattedPDF
                            _ = try? await repository.savePayslip(updatedDTO)
                            return newUrl
                        }
                    } catch {
                        Logger.warning("Error reading existing PDF data: \(error)", category: "PDFURLService")

                        // Try to create a formatted PDF as fallback
                        do {
                            let payslipData = PayslipData(from: payslip)
                            let formattedPDF = formattingService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)
                            let newUrl = try pdfManager.savePDF(data: formattedPDF, identifier: payslipItem.id.uuidString)

                            // Update payslip with formatted PDF using repository
                            let payslipDTO = PayslipDTO(from: payslipItem)
                            var updatedDTO = payslipDTO
                            updatedDTO.pdfData = formattedPDF
                            _ = try? await repository.savePayslip(updatedDTO)

                            Logger.info("Created fallback formatted PDF", category: "PDFURLService")
                            return newUrl
                        } catch {
                            Logger.error("Failed to create fallback PDF: \(error)", category: "PDFURLService")
                        }
                    }
                } else {
                    Logger.warning("Existing PDF has invalid size, will recreate", category: "PDFURLService")
                }
            } catch {
                Logger.warning("Error checking existing PDF: \(error)", category: "PDFURLService")
            }
        }

        return try await createOrSavePDF(for: payslipItem, payslip: payslip)
    }

    // MARK: - Private Methods

    /// Creates or saves a PDF for a payslip
    private func createOrSavePDF(for payslipItem: PayslipItem, payslip: AnyPayslip) async throws -> URL? {
        // If we have PDF data in the PayslipItem, save it to the PDFManager
        if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
            Logger.info("Using PDF data from payslip item (\(pdfData.count) bytes)", category: "PDFURLService")

            // Check if this appears to be a military PDF
            let isMilitaryPDF = validationService.checkForMilitaryPDFFormat(pdfData)
            if isMilitaryPDF {
                Logger.info("Detected military PDF format", category: "PDFURLService")
            }

            // First check if this is a valid PDF
            if validationService.isPDFValid(data: pdfData) {
                Logger.info("PDF data appears valid, saving directly", category: "PDFURLService")
                // Save the PDF data
                do {
                    let url = try pdfManager.savePDF(data: pdfData, identifier: payslipItem.id.uuidString)
                    Logger.info("Saved PDF data to \(url.path)", category: "PDFURLService")
                    return url
                } catch {
                    Logger.error("Failed to save PDF data: \(error)", category: "PDFURLService")
                    // Don't throw here - continue to the placeholder creation
                }
            } else {
                Logger.info("PDF data is invalid, creating formatted placeholder", category: "PDFURLService")

                // Create a formatted PDF
                let payslipData = PayslipData(from: payslip)
                let formattedPDF = formattingService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)
                let url = try pdfManager.savePDF(data: formattedPDF, identifier: payslipItem.id.uuidString)

                // Update the PayslipItem with the formatted PDF using repository
                let payslipDTO = PayslipDTO(from: payslipItem)
                var updatedDTO = payslipDTO
                updatedDTO.pdfData = formattedPDF
                _ = try? await repository.savePayslip(updatedDTO)

                return url
            }
        }

        return try await createPlaceholderPDF(for: payslipItem, payslip: payslip)
    }

    /// Creates a placeholder PDF when no valid PDF data is available
    private func createPlaceholderPDF(for payslipItem: PayslipItem, payslip: AnyPayslip) async throws -> URL? {
        // No PDF data available, create a placeholder PDF
        Logger.info("No PDF data available, creating formatted placeholder", category: "PDFURLService")

        // Create a formatted PDF
        let payslipData = PayslipData(from: payslip)
        let formattedPDF = formattingService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

        do {
            let url = try pdfManager.savePDF(data: formattedPDF, identifier: payslipItem.id.uuidString)
            Logger.info("Saved placeholder PDF to \(url.path)", category: "PDFURLService")

            // Update the PayslipItem with the placeholder data using repository
            let payslipDTO = PayslipDTO(from: payslipItem)
            var updatedDTO = payslipDTO
            updatedDTO.pdfData = formattedPDF
            _ = try? await repository.savePayslip(updatedDTO)
            Logger.info("Updated PayslipItem with placeholder PDF data", category: "PDFURLService")

            return url
        } catch {
            Logger.error("Failed to save placeholder PDF: \(error)", category: "PDFURLService")
            throw error
        }
    }
}
