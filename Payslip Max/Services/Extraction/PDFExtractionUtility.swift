import Foundation
import PDFKit

/// Utility class for PDF extraction operations
class PDFExtractionUtility {
    
    // MARK: - Logging Methods
    
    /// Logs the extracted payslip details
    /// - Parameter payslip: The payslip item to log
    static func logExtractedPayslip(_ payslip: PayslipItem) {
        print("PDFExtractionUtility: Extraction Results:")
        print("  Name: \(payslip.name)")
        print("  Month/Year: \(payslip.month) \(payslip.year)")
        print("  Credits: \(payslip.credits)")
        print("  Debits: \(payslip.debits)")
        print("  DSOP: \(payslip.dsop)")
        print("  Tax: \(payslip.tax)")
        print("  PAN: \(payslip.panNumber)")
        print("  Account: \(payslip.accountNumber)")
    }
    
    // MARK: - File Operations
    
    /// Saves the extracted text to a file for debugging
    /// - Parameter text: The text to save to file
    static func saveExtractedTextToFile(_ text: String) {
        do {
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent("extracted_pdf_text.txt")
            
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            print("PDFExtractionUtility: Saved extracted text to \(fileURL.path)")
        } catch {
            print("PDFExtractionUtility: Failed to save extracted text: \(error)")
        }
    }
    
    /// Records extraction data for training purposes
    /// - Parameters:
    ///   - documentURL: The URL of the document
    ///   - extractedData: The extracted data as a string
    static func recordExtraction(documentURL: String, extractedData: String) {
        // Create a file URL from the document URL string
        guard let url = URL(string: documentURL) else {
            print("Invalid document URL: \(documentURL)")
            return
        }
        
        // Save the extracted data to a file
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let extractionDirectory = documentsDirectory.appendingPathComponent("Extractions", isDirectory: true)
        
        // Create the directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: extractionDirectory, withIntermediateDirectories: true)
        } catch {
            print("Error creating extraction directory: \(error)")
            return
        }
        
        // Create a filename based on the document URL
        let filename = url.lastPathComponent.replacingOccurrences(of: ".pdf", with: "_extraction.txt")
        let fileURL = extractionDirectory.appendingPathComponent(filename)
        
        // Write the extracted data to the file
        do {
            try extractedData.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Extraction data saved to: \(fileURL.path)")
        } catch {
            print("Error saving extraction data: \(error)")
        }
    }
} 