import UIKit
import Foundation

/// A specialized UIActivityItemProvider for sharing payslip PDF files
/// This ensures the PDF is prepared in the background and immediately available for the first share attempt
class PayslipShareItemProvider: UIActivityItemProvider, @unchecked Sendable {
    // MARK: - Properties
    
    /// The PDF data to share
    private let pdfData: Data
    
    /// The title of the payslip (used for the filename)
    private let title: String
    
    /// Temporary URL for the PDF file
    private var temporaryURL: URL
    
    /// Track if file was successfully written
    private var fileWritten: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes a new PayslipShareItemProvider with PDF data and title
    /// - Parameters:
    ///   - pdfData: The PDF data to share
    ///   - title: The title to use for the filename
    init(pdfData: Data, title: String) {
        self.pdfData = pdfData
        self.title = title.replacingOccurrences(of: " ", with: "_")
        
        // Create a temporary URL for the PDF using Documents directory for better permissions
        let tempDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let fileName = "\(self.title).pdf"
        self.temporaryURL = tempDir.appendingPathComponent(fileName)
        
        // Initialize with a placeholder URL (will be written to when item is requested)
        super.init(placeholderItem: self.temporaryURL)
        
        // Write the PDF data to the temporary file immediately to ensure it's ready
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: temporaryURL.path) {
                try FileManager.default.removeItem(at: temporaryURL)
            }
            
            // Write new PDF data
            try self.pdfData.write(to: self.temporaryURL)
            
            // Set file attributes for sharing
            try FileManager.default.setAttributes([
                .posixPermissions: 0o644
            ], ofItemAtPath: temporaryURL.path)
            
            self.fileWritten = true
            Logger.info("Successfully prepared PDF for sharing at: \(self.temporaryURL.path)", category: "ShareProvider")
        } catch {
            Logger.error("Failed to write PDF data: \(error.localizedDescription)", category: "ShareProvider")
            self.fileWritten = false
        }
    }
    
    // MARK: - UIActivityItemProvider
    
    override var item: Any {
        // Verify file exists and is readable before sharing
        guard fileWritten, FileManager.default.fileExists(atPath: temporaryURL.path) else {
            Logger.error("PDF file not found or not written successfully", category: "ShareProvider")
            // Return the raw data as fallback
            return pdfData
        }
        
        // Verify file is readable
        guard FileManager.default.isReadableFile(atPath: temporaryURL.path) else {
            Logger.error("PDF file is not readable", category: "ShareProvider")
            // Return the raw data as fallback
            return pdfData
        }
        
        Logger.info("Successfully sharing PDF from: \(temporaryURL.path)", category: "ShareProvider")
        return temporaryURL
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        // Specify the file is a PDF
        return "com.adobe.pdf"
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return title
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Clean up temporary file
        if FileManager.default.fileExists(atPath: temporaryURL.path) {
            do {
                try FileManager.default.removeItem(at: temporaryURL)
                Logger.info("Cleaned up temporary PDF file", category: "ShareProvider")
            } catch {
                Logger.error("Failed to clean up temporary PDF file: \(error.localizedDescription)", category: "ShareProvider")
            }
        }
    }
} 