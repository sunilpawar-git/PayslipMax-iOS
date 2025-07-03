
import Foundation
import PDFKit

@MainActor
class PayslipProcessingService {
    private let pdfHandler: PDFProcessingHandler
    private let passwordHandler: PasswordProtectedPDFHandler

    init(pdfHandler: PDFProcessingHandler, passwordHandler: PasswordProtectedPDFHandler) {
        self.pdfHandler = pdfHandler
        self.passwordHandler = passwordHandler
    }

    func processPayslipPDF(from url: URL) async -> Result<PayslipItem, Error> {
        guard let pdfData = try? Data(contentsOf: url) else {
            return .failure(AppError.message("Failed to read PDF file"))
        }

        if pdfHandler.isPasswordProtected(pdfData) {
            passwordHandler.showPasswordEntry(for: pdfData)
            // This will be handled by the UI, which will then call processUnlockedPDF
            return .failure(AppError.passwordProtectedPDF("PDF is password protected"))
        }

        return await pdfHandler.processPDFData(pdfData, from: url)
    }

    func processUnlockedPDF(data: Data, from url: URL?) async -> Result<PayslipItem, Error> {
        return await pdfHandler.processPDFData(data, from: url)
    }
}
