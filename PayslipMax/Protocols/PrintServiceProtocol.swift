import UIKit
import PDFKit

/// Protocol for handling PDF printing operations
/// Supports both singleton and dependency injection patterns
protocol PrintServiceProtocol {

    /// Prints a PDF document from PDF data or URL
    /// - Parameters:
    ///   - pdfData: The PDF data to print
    ///   - url: URL of the PDF to print (alternative to pdfData)
    ///   - jobName: Name of the print job
    ///   - viewController: The view controller to present from
    ///   - completion: Callback when printing is complete
    func printPDF(
        pdfData: Data?,
        url: URL?,
        jobName: String,
        from viewController: UIViewController,
        completion: (() -> Void)?
    )
}
