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
    func getShareItems(for payslip: any PayslipItemProtocol, payslipData: Models.PayslipData) async -> [Any] {
        guard let payslipItem = payslip as? PayslipItem else {
            // If we can't get a PayslipItem, just share the text
            return [formatterService.getShareText(for: payslipData)]
        }
        
        // Create a shared results array
        var shareItems: [Any] = []
        
        // Add the formatted text first
        shareItems.append(formatterService.getShareText(for: payslipData))
        
        // Try to get the PDF URL
        if let pdfURL = try? await pdfService.getPDFURL(for: payslip) {
            // Add the PDF URL to share items
            shareItems.append(pdfURL)
            return shareItems
        }
        
        // If no PDF URL is available but we have PDF data, write it to a temporary file
        if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
            print("GetShareItems: Using PDF data from payslip item")
            
            // Verify and repair the PDF data if needed
            let validData = PDFManager.shared.verifyAndRepairPDF(data: pdfData)
            
            do {
                let tempDir = FileManager.default.temporaryDirectory
                let tempURL = tempDir.appendingPathComponent("\(payslipItem.id.uuidString)_temp.pdf")
                try validData.write(to: tempURL)
                print("GetShareItems: Wrote PDF data to temp file: \(tempURL.path)")
                shareItems.append(tempURL)
            } catch {
                print("GetShareItems: Failed to write PDF data to temp file: \(error)")
            }
        }
        
        return shareItems
    }
} 