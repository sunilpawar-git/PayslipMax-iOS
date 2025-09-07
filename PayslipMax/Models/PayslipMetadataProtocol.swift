import Foundation
import PDFKit

/// Protocol defining the metadata properties of a payslip item.
///
/// This protocol provides the metadata and secondary information
/// properties that are useful for presentation and storage purposes.
protocol PayslipMetadataProtocol: PayslipBaseProtocol {
    // MARK: - PDF Data Properties
    
    /// The raw PDF data of the payslip.
    var pdfData: Data? { get set }
    
    /// The source URL of the PDF, if available.
    var pdfURL: URL? { get set }
    
    // MARK: - Presentation Properties
    
    /// Flag indicating if the payslip is a sample.
    var isSample: Bool { get set }
    
    /// The source of the payslip data (e.g., "Manual", "Imported", "Scanned").
    var source: String { get set }
    
    /// The processing status of the payslip.
    var status: String { get set }
    
    /// Any additional notes or comments about the payslip.
    var notes: String? { get set }
}

// MARK: - Default Implementations
extension PayslipMetadataProtocol {
    /// Returns a PDFDocument created from the stored PDF data, if available.
    var pdfDocument: PDFDocument? {
        guard let data = pdfData else { return nil }
        return PDFDocument(data: data)
    }

    /// Returns a formatted description of the payslip source and status.
    var sourceDescription: String {
        let baseDescription = source
        if isSample {
            return "\(baseDescription) (Sample)"
        }
        return baseDescription
    }

    /// Provides the associated PDFDocument if `pdfData` is available. Alias for `pdfDocument`.
    var document: PDFDocument? {
        return pdfDocument
    }
}
