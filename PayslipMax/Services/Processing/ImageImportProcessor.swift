import Foundation
import UIKit

/// Shared helper to process imported images (camera scans or gallery) through the payslip pipeline.
@MainActor
final class ImageImportProcessor {
    private let pdfHandler: PDFProcessingHandler
    private let dataService: DataServiceProtocol

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

    /// Processes an image into a payslip and saves it.
    /// - Returns: `.success` on save or `.failure` with user-friendly message.
    func process(image: UIImage) async -> Result<Void, ImageImportError> {
        do {
            try await dataService.initialize()
        } catch {
            return .failure(.message("Failed to initialize data services: \(error.localizedDescription)"))
        }

        let result = await pdfHandler.processScannedImage(image)

        switch result {
        case .success(let payslip):
            do {
                try await dataService.save(payslip)
                return .success(())
            } catch {
                return .failure(.message("Failed to save scanned payslip: \(error.localizedDescription)"))
            }
        case .failure(let error):
            return .failure(.message("Failed to process scanned payslip: \(error.localizedDescription)"))
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

