import Foundation
import UIKit

/// Shared helper to process imported images (camera scans or gallery) through the payslip pipeline.
@MainActor
final class ImageImportProcessor {
    private let pdfHandler: PDFProcessingHandler
    private let dataService: DataServiceProtocol
    private var userHint: PayslipUserHint = .auto

    init(
        pdfHandler: PDFProcessingHandler,
        dataService: DataServiceProtocol
    ) {
        self.pdfHandler = pdfHandler
        self.dataService = dataService
    }

    static func makeDefault() -> ImageImportProcessor {
        ImageImportProcessor(
            pdfHandler: DIContainer.shared.makePDFProcessingHandler(),
            dataService: DIContainer.shared.makeDataService()
        )
    }

    func updateUserHint(_ hint: PayslipUserHint) {
        userHint = hint
    }

    /// Processes an image into a payslip and saves it.
    /// - Returns: `.success` on save or `.failure` with user-friendly message.
    func process(image: UIImage) async -> Result<Void, ImageImportError> {
        do {
            try await dataService.initialize()
        } catch {
            return .failure(.message("Failed to initialize data services: \(error.localizedDescription)"))
        }

        let result = await pdfHandler.processScannedImage(image, hint: userHint)

        switch result {
        case .success(let payslip):
            do {
                try await dataService.save(payslip)
                PayslipEvents.notifyForcedRefreshRequired()
                return .success(())
            } catch {
                return .failure(.message("Failed to save scanned payslip: \(error.localizedDescription)"))
            }
        case .failure(let error):
            return .failure(.message("Failed to process scanned payslip: \(error.localizedDescription)"))
        }
    }

    /// Processes a cropped image through OCR + LLM only and saves it.
    /// Skips the full modular pipeline and regex gating to prioritize the LLM path.
    func processCroppedImageLLMOnly(_ image: UIImage) async -> Result<Void, ImageImportError> {
        do {
            try await dataService.initialize()
        } catch {
            return .failure(.message("Failed to initialize data services: \(error.localizedDescription)"))
        }

        let result = await pdfHandler.processScannedImageLLMOnly(image, hint: userHint)

        switch result {
        case .success(let payslip):
            do {
                try await dataService.save(payslip)
                PayslipEvents.notifyForcedRefreshRequired()
                return .success(())
            } catch {
                return .failure(.message("Failed to save scanned payslip: \(error.localizedDescription)"))
            }
        case .failure(let error):
            return .failure(.message("Failed to process cropped payslip: \(error.localizedDescription)"))
        }
    }
}

enum ImageImportError: Error, LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let message): return message
        }
    }
}

