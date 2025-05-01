import Foundation
import SwiftUI

/// Service responsible for handling the sharing of payslip information
@MainActor
class PayslipShareService {
    // MARK: - Singleton Instance
    static let shared = PayslipShareService()
    
    // MARK: - Dependencies
    private let pdfService: PayslipPDFService
    private let formatterService: PayslipFormatterService
    
    init(pdfService: PayslipPDFService? = nil,
         formatterService: PayslipFormatterService? = nil) {
        self.pdfService = pdfService ?? PayslipPDFService.shared
        self.formatterService = formatterService ?? PayslipFormatterService.shared
    }
    
    // MARK: - Public Methods
    
    /// Get items to share for a payslip
    func getShareItems(for payslip: AnyPayslip, payslipData: Models.PayslipData) async -> [Any] {
        guard let payslipItem = payslip as? PayslipItem else {
            // If we can't get a PayslipItem, just share the text
            return [formatterService.getShareText(for: payslipData)]
        }
        
        // Create a shared results array
        var shareItems: [Any] = []
        
        // Add the formatted text first - always include text
        let shareText = formatterService.getShareText(for: payslipData)
        shareItems.append(shareText)
        
        // Try to get the PDF URL with proper security handling
        do {
            if let pdfURL = try await pdfService.getPDFURL(for: payslip) {
                Logger.info("Got PDF URL for sharing: \(pdfURL.path)", category: "ShareService")
                
                // Create a temporary file for sharing instead of using the original
                // This avoids security-scoped resource issues with the share sheet
                let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                    "\(payslip.id)_share_\(UUID().uuidString).pdf")
                
                // Copy the PDF data to the temporary location
                if let pdfData = try? Data(contentsOf: pdfURL) {
                    try? pdfData.write(to: tempFileURL)
                    Logger.info("Created temporary share file at: \(tempFileURL.path)", category: "ShareService")
                    shareItems.append(tempFileURL)
                    return shareItems
                }
            }
        } catch {
            Logger.error("Error getting PDF URL: \(error)", category: "ShareService")
        }
        
        // If no PDF URL is available but we have PDF data, write it to a temporary file
        if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
            Logger.info("Using PDF data from payslip item", category: "ShareService")
            
            // Verify and repair the PDF data if needed
            let validData = PDFManager.shared.verifyAndRepairPDF(data: pdfData)
            
            do {
                let tempDir = FileManager.default.temporaryDirectory
                let tempURL = tempDir.appendingPathComponent("\(payslipItem.id.uuidString)_\(UUID().uuidString).pdf")
                try validData.write(to: tempURL)
                Logger.info("Wrote PDF data to temp file: \(tempURL.path)", category: "ShareService")
                shareItems.append(tempURL)
            } catch {
                Logger.error("Failed to write PDF data to temp file: \(error)", category: "ShareService")
            }
        }
        
        return shareItems
    }
} 