import UIKit
import PDFKit

/// Service responsible for handling PDF printing operations
class PrintService {
    /// Shared instance of the print service
    static let shared = PrintService()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
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