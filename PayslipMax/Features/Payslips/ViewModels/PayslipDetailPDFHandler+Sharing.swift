import SwiftUI
import SwiftData
import Foundation
import PDFKit

// MARK: - PDF Sharing

extension PayslipDetailPDFHandler {

    /// Get PDF data for sharing operations
    func getPDFDataForSharing() async -> Data? {
        if let payslipItem = payslip as? PayslipItem {
            if needsPDFRegeneration && (payslipItem.pdfData == nil || payslipItem.pdfData!.isEmpty) {
                Logger.info("Manual entry detected without PDF data - generating new PDF", category: "PayslipSharing")

                let payslipData = PayslipData(from: payslip)
                let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

                if !newPDFData.isEmpty {
                    Logger.info("Generated fresh PDF data for sharing (\(newPDFData.count) bytes)", category: "PayslipSharing")

                    await MainActor.run {
                        payslipItem.pdfData = newPDFData
                        self.pdfData = newPDFData
                    }

                    return newPDFData
                }
            } else if let pdfData = payslipItem.pdfData {
                Logger.info("Found existing PDF data with size: \(pdfData.count) bytes", category: "PayslipSharing")

                if !pdfData.isEmpty && pdfData.count > 100 {
                    let pdfHeader = Data([0x25, 0x50, 0x44, 0x46])
                    if pdfData.starts(with: pdfHeader) {
                        Logger.info("PDF data is valid", category: "PayslipSharing")
                        return pdfData
                    } else {
                        Logger.warning("PDF data found but doesn't have valid PDF header - regenerating", category: "PayslipSharing")

                        let payslipData = PayslipData(from: payslip)
                        let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

                        if !newPDFData.isEmpty {
                            await MainActor.run {
                                payslipItem.pdfData = newPDFData
                                self.pdfData = newPDFData
                            }
                            return newPDFData
                        }
                    }
                } else {
                    Logger.warning("PDF data found but is too small (\(pdfData.count) bytes) - regenerating", category: "PayslipSharing")

                    let payslipData = PayslipData(from: payslip)
                    let newPDFData = pdfService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)

                    if !newPDFData.isEmpty {
                        await MainActor.run {
                            payslipItem.pdfData = newPDFData
                            self.pdfData = newPDFData
                        }
                        return newPDFData
                    }
                }
            }
        }

        return nil
    }
}
