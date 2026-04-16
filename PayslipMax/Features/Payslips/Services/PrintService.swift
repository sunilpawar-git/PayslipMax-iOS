import UIKit
import PDFKit

/// Service responsible for handling PDF printing operations
/// Phase 2D-Gamma: Converted to dual-mode pattern supporting both singleton and DI
class PrintService: PrintServiceProtocol {
    /// Shared instance of the print service
    /// Phase 2D-Gamma: Maintained for backward compatibility
    static let shared = PrintService()

    // MARK: - Initialization

    /// Phase 2D-Gamma: Private initializer for singleton pattern
    private init() {}

    /// Phase 2D-Gamma: Public initializer for dependency injection
    /// No dependencies required for this service
    init(dependencies: [String: Any] = [:]) {
        // PrintService has no external dependencies
    }

    /// Prints a PDF document from PDF data or URL
    /// - Parameters:
    ///   - pdfData: The PDF data to print
    ///   - url: URL of the PDF to print (alternative to pdfData)
    ///   - jobName: Name of the print job
    ///   - completion: Callback when printing is complete
    func printPDF(pdfData: Data? = nil, url: URL? = nil, jobName: String, from viewController: UIViewController, completion: (() -> Void)? = nil) {
        // Create a UIPrintInteractionController
        let printController = UIPrintInteractionController.shared

        // Configure print job
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = jobName
        printInfo.outputType = .general
        printController.printInfo = printInfo

        // Set the print content based on what's provided (data or URL)
        if let pdfData = pdfData {
            // Use PDF data if provided
            if let document = PDFDocument(data: pdfData) {
                printController.printingItem = document.dataRepresentation()
            } else {
                // If can't create PDFDocument, use the data directly
                printController.printingItem = pdfData
            }
        } else if let url = url {
            // Use URL if provided
            printController.printingItem = url
        } else {
            // Log error if neither was provided
            Logger.error("No valid PDF data or URL provided for printing", category: "PrintService")
            completion?()
            return
        }

        // Present the print controller
        printController.present(animated: true, completionHandler: { (controller, success, error) in
            if let error = error {
                Logger.error("Error printing PDF: \(error.localizedDescription)", category: "PrintService")
            } else if success {
                Logger.info("Print job completed successfully", category: "PrintService")
            } else {
                Logger.info("Print job was cancelled or failed", category: "PrintService")
            }

            completion?()
        })
    }

}
