import UIKit
import Foundation

/// A specialized UIActivityItemProvider for sharing payslip PDF files
/// This ensures the PDF is prepared in the background and immediately available for the first share attempt
class PayslipShareItemProvider: UIActivityItemProvider {
    // MARK: - Properties
    
    /// The PDF data to share
    private let pdfData: Data
    
    /// The title of the payslip (used for the filename)
    private let title: String
    
    /// Temporary URL for the PDF file
    private var temporaryURL: URL
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipShareItemProvider with PDF data and title
    /// - Parameters:
    ///   - pdfData: The PDF data to share
    ///   - title: The title to use for the filename
    init(pdfData: Data, title: String) {
        self.pdfData = pdfData
        self.title = title.replacingOccurrences(of: " ", with: "_")
        
        // Create a temporary URL for the PDF
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(self.title).pdf"
        self.temporaryURL = tempDir.appendingPathComponent(fileName)
        
        // Initialize with a placeholder URL (will be written to when item is requested)
        super.init(placeholderItem: self.temporaryURL)
        
        // Write the PDF data to the temporary file immediately to ensure it's ready
        try? self.pdfData.write(to: self.temporaryURL)
        Logger.info("Prepared PDF for sharing at: \(self.temporaryURL.path)", category: "ShareProvider")
    }
    
    // MARK: - UIActivityItemProvider
    
    override var item: Any {
        // Return the URL to the temporary file
        Logger.info("Sharing PDF from: \(temporaryURL.path)", category: "ShareProvider")
        return temporaryURL
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        // Specify the file is a PDF
        return "com.adobe.pdf"
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Clean up temporary file
        try? FileManager.default.removeItem(at: temporaryURL)
        Logger.info("Cleaned up temporary PDF file", category: "ShareProvider")
    }
} 