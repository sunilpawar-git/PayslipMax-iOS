import Foundation
import PDFKit

// MARK: - PDFProcessingServiceProtocol Implementation

@MainActor
extension PDFProcessingService {

    /// Processes a PDF file specified by a URL.
    func processPDF(from url: URL) async -> Result<Data, PDFProcessingError> {
        print("[PDFProcessingService] Processing PDF file from URL: \(url)")

        do {
            let data = try await pdfService.process(url)

            switch await processingPipeline.validatePDF(data) {
            case .success(let validData):
                return .success(validData)
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            print("[PDFProcessingService] Error loading PDF file: \(error)")
            return .failure(.fileAccessError(error.localizedDescription))
        }
    }

    /// Processes raw PDF data through smart routing based on format detection.
    func processPDFData(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        print("[PDFProcessingService] Processing PDF of size: \(data.count) bytes")

        guard let document = PDFDocument(data: data) else {
            print("[PDFProcessingService] Could not create PDF document")
            return await processingPipeline.executePipeline(data)
        }

        guard let text = parsingCoordinator.extractFullText(from: document) else {
            print("[PDFProcessingService] Could not extract text from PDF")
            return await processingPipeline.executePipeline(data)
        }

        let format = await formatDetectionService.detectFormatEnhanced(
            fromText: text,
            pdfData: data
        )

        print("[PDFProcessingService] Enhanced format detection: \(format)")

        switch format {
        case .jcoOR:
            print("[PDFProcessingService] JCO/OR format detected → routing to Vision LLM")
            guard let image = convertPDFToImage(data) else {
                print("[PDFProcessingService] Failed to convert PDF to image, falling back to pipeline")
                return await processingPipeline.executePipeline(data)
            }
            return await processWithVisionLLM(image: image, hint: userHint)

        case .defense, .unknown:
            print("[PDFProcessingService] Officer/unknown format → routing to hybrid pipeline")
            return await processingPipeline.executePipeline(data)
        }
    }

    /// Checks if the provided PDF data is password protected.
    func isPasswordProtected(_ data: Data) -> Bool {
        return validationService.isPDFPasswordProtected(data)
    }

    /// Unlocks a password-protected PDF using the provided password.
    func unlockPDF(_ data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        do {
            let unlockedData = try await pdfService.unlockPDF(data: data, password: password)
            return .success(unlockedData)
        } catch {
            print("[PDFProcessingService] Error unlocking PDF: \(error)")
            return .failure(.incorrectPassword)
        }
    }

    /// Detects the format of a defense personnel payslip PDF.
    func detectPayslipFormat(_ data: Data) -> PayslipFormat {
        guard let document = PDFDocument(data: data),
              let text = parsingCoordinator.extractFullText(from: document) else {
            return .unknown
        }

        let format = formatDetectionService.detectFormat(fromText: text)
        return format
    }

    /// Validates that the PDF data contains recognizable payslip content.
    func validatePayslipContent(_ data: Data) -> PayslipContentValidationResult {
        guard let document = PDFDocument(data: data),
              let text = parsingCoordinator.extractFullText(from: document) else {
            return PayslipContentValidationResult(isValid: false, confidence: 0, detectedFields: [], missingRequiredFields: ["Valid PDF"])
        }

        return validationService.validatePayslipContent(text)
    }

    /// Gets the detected format for a payslip based on previously extracted text.
    func getPayslipFormat(from text: String) -> PayslipFormat? {
        return formatDetectionService.detectFormat(fromText: text)
    }

    func updateUserHint(_ hint: PayslipUserHint) {
        userHint = hint
        formatDetectionService.updateUserHint(hint)
    }

    /// Gets a list of all payslip formats supported by the configured processors.
    func supportedFormats() -> [PayslipFormat] {
        let processors = processorFactory.getAllProcessors()
        return processors.map { $0.handlesFormat }
    }
}
