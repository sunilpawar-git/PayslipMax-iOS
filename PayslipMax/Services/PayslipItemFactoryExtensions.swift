import Foundation
import PDFKit

// MARK: - PayslipItemFactory Extensions
// Additional factory methods extracted to maintain 300-line rule compliance

extension PayslipItemFactory {
    /// Creates a PayslipItem from extraction results (enhanced factory method)
    /// - Parameters:
    ///   - extractionResult: The result from PDF text extraction
    ///   - pdfData: The original PDF data
    ///   - pdfURL: The source URL of the PDF
    /// - Returns: A configured PayslipItem or nil if creation fails
    static func createFromExtraction(extractionResult: [String: Any],
                                   pdfData: Data,
                                   pdfURL: URL? = nil) -> PayslipItem? {
        guard let month = extractionResult["month"] as? String,
              let year = extractionResult["year"] as? Int,
              let credits = extractionResult["credits"] as? Double,
              let debits = extractionResult["debits"] as? Double else {
            return nil
        }

        let earnings = extractionResult["earnings"] as? [String: Double] ?? [:]
        let deductions = extractionResult["deductions"] as? [String: Double] ?? [:]
        let dsop = extractionResult["dsop"] as? Double ?? 0.0
        let tax = extractionResult["tax"] as? Double ?? 0.0
        let name = extractionResult["name"] as? String ?? ""
        let accountNumber = extractionResult["accountNumber"] as? String ?? ""
        let panNumber = extractionResult["panNumber"] as? String ?? ""

        var numberOfPages = 0
        if let pdfDocument = PDFDocument(data: pdfData) {
            numberOfPages = pdfDocument.pageCount
        }

        let payslip = PayslipItem(
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            earnings: earnings,
            deductions: deductions,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: pdfData,
            pdfURL: pdfURL,
            source: "Imported",
            numberOfPages: numberOfPages,
            metadata: ["ExtractionDate": ISO8601DateFormatter().string(from: Date())]
        )

        return payslip
    }

    /// Creates a copy of a PayslipItem with modified properties
    /// - Parameters:
    ///   - original: The original PayslipItem to copy
    ///   - modifications: A closure that modifies the copied payslip
    /// - Returns: A new PayslipItem instance with the modifications applied
    static func copy(_ original: PayslipItem, modifications: (inout PayslipItem) -> Void) -> PayslipItem {
        // Create a basic copy first
        var copy = PayslipItem(id: UUID(), timestamp: original.timestamp, month: original.month, year: original.year, credits: original.credits, debits: original.debits)

        // Copy all additional properties
        copy.dsop = original.dsop
        copy.tax = original.tax
        copy.earnings = original.earnings
        copy.deductions = original.deductions
        copy.name = original.name
        copy.accountNumber = original.accountNumber
        copy.panNumber = original.panNumber
        copy.isNameEncrypted = original.isNameEncrypted
        copy.isAccountNumberEncrypted = original.isAccountNumberEncrypted
        copy.isPanNumberEncrypted = original.isPanNumberEncrypted
        copy.sensitiveData = original.sensitiveData
        copy.encryptionVersion = original.encryptionVersion
        copy.pdfData = original.pdfData
        copy.pdfURL = original.pdfURL
        copy.isSample = original.isSample
        copy.source = original.source
        copy.status = original.status
        copy.notes = original.notes
        copy.pages = original.pages
        copy.numberOfPages = original.numberOfPages
        copy.metadata = original.metadata
        copy.documentType = original.documentType
        copy.documentDate = original.documentDate

        modifications(&copy)
        return copy
    }
}
