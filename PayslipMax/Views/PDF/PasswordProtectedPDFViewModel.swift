import Foundation
import PDFKit

/// ViewModel for PasswordProtectedPDFView.
/// Owns all unlock logic and holds injected services — the View is layout-only.
@MainActor
final class PasswordProtectedPDFViewModel: ObservableObject {

    // MARK: - Published State

    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isLikelyMilitaryPDF: Bool = false

    // MARK: - Callbacks

    /// Called when the PDF has been successfully unlocked.
    var onUnlock: ((Data, String) -> Void)?

    // MARK: - Private

    private let pdfData: Data
    private let pdfService: PDFServiceProtocol
    private let pcdaHandler: PCDAPayslipHandlerProtocol
    private var attemptCount: Int = 0

    // MARK: - Init

    init(
        pdfData: Data,
        pdfService: PDFServiceProtocol,
        pcdaHandler: PCDAPayslipHandlerProtocol
    ) {
        self.pdfData = pdfData
        self.pdfService = pdfService
        self.pcdaHandler = pcdaHandler
    }

    // MARK: - Public Methods

    /// Inspects the PDF metadata to determine whether it is likely a military PCDA file.
    func checkIfMilitaryPDF() {
        guard let pdfDocument = PDFDocument(data: pdfData) else { return }

        if let attributes = pdfDocument.documentAttributes {
            if let creator = attributes[PDFDocumentAttribute.creatorAttribute] as? String,
               creator.contains("PCDA") || creator.contains("Defence") {
                isLikelyMilitaryPDF = true
                return
            }
            if let title = attributes[PDFDocumentAttribute.titleAttribute] as? String,
               title.contains("Defence") || title.contains("Army") || title.contains("Military") {
                isLikelyMilitaryPDF = true
                return
            }
        }

        if let filename = pdfDocument.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String,
           filename.contains("PCDA") || filename.contains("PAY") ||
           filename.contains("Army") || filename.contains("ARMY") {
            isLikelyMilitaryPDF = true
        }
    }

    /// Attempts to unlock the PDF with the current `password`.
    func unlockPDF() async {
        guard !password.isEmpty else {
            errorMessage = "Password cannot be empty"
            return
        }

        isLoading = true
        errorMessage = nil
        attemptCount += 1

        // Military path: try PCDA handler first
        if isLikelyMilitaryPDF {
            let (unlockedData, successPassword) = await pcdaHandler.unlockPDF(
                data: pdfData,
                basePassword: password
            )
            if let unlockedData, let successPassword {
                onUnlock?(unlockedData, successPassword)
                isLoading = false
                return
            }
        }

        // Standard path
        do {
            let unlockedData = try await pdfService.unlockPDF(data: pdfData, password: password)
            onUnlock?(unlockedData, password)
        } catch PDFServiceError.incorrectPassword {
            if attemptCount >= 2 && !isLikelyMilitaryPDF {
                isLikelyMilitaryPDF = true
                errorMessage = "Incorrect password. This might be a military PDF — try your service number or PCDA password."
            } else if isLikelyMilitaryPDF {
                errorMessage = "Incorrect password. Try your service number or a PCDA-specific password."
            } else {
                errorMessage = "Incorrect password. Please try again."
            }
        } catch PDFServiceError.unsupportedEncryptionMethod {
            errorMessage = "This PDF uses an unsupported encryption method."
        } catch {
            errorMessage = "An error occurred while unlocking the PDF. Please try again."
        }

        isLoading = false
    }
}
