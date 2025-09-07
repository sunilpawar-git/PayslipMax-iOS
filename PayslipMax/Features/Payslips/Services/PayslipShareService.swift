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
    func getShareItems(for payslip: AnyPayslip, payslipData: PayslipData) async -> [Any] {
        guard let payslipItem = payslip as? PayslipItem else {
            // If we can't get a PayslipItem, just share the text
            return [formatterService.getShareText(for: payslipData)]
        }
        
        // Create a shared results array
        var shareItems: [Any] = []
        
        // Add the formatted text first - always include text
        let shareText = formatterService.getShareText(for: payslipData)
        shareItems.append(shareText)
        
        // Use our specialized item provider if PDF data is available
        if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
            // Add PDF using our specialized item provider
            let pdfProvider = PayslipShareItemProvider(
                pdfData: pdfData,
                title: "\(payslip.month)_\(payslip.year)_Payslip"
            )
            shareItems.append(pdfProvider)
            Logger.info("Added PDF provider to share items", category: "ShareService")
            return shareItems
        }
        
        // If no direct PDF data, try to get the PDF URL
        do {
            if let pdfURL = try await pdfService.getPDFURL(for: payslip) {
                Logger.info("Got PDF URL for sharing: \(pdfURL.path)", category: "ShareService")
                
                // Get PDF data from URL
                if let pdfData = try? Data(contentsOf: pdfURL) {
                    // Add PDF using our specialized item provider
                    let pdfProvider = PayslipShareItemProvider(
                        pdfData: pdfData,
                        title: "\(payslip.month)_\(payslip.year)_Payslip"
                    )
                    shareItems.append(pdfProvider)
                    Logger.info("Added PDF provider from URL to share items", category: "ShareService")
                }
            }
        } catch {
            Logger.error("Error getting PDF URL: \(error)", category: "ShareService")
        }
        
        // Return what we have (at minimum, the text)
        return shareItems
    }
} 