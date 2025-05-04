import Foundation
@testable import PayslipMax

extension PDFProcessingService {
    func processPDFDataForTesting(_ data: Data) async -> Result<PayslipItem, PDFProcessingError> {
        // For tests, we only require the header and footer
        let pdfString = String(data: data, encoding: .utf8) ?? ""
        let hasPDFHeader = pdfString.contains("%PDF-")
        let hasPDFFooter = pdfString.contains("%%EOF")
        
        guard hasPDFHeader && hasPDFFooter else {
            print("[PDFProcessingService] Invalid PDF structure")
            return .failure(.invalidPDFData)
        }
        
        // For test data, we'll try to parse it even if it's not a perfect PDF
        if let mockParsingCoordinator = parsingCoordinator as? MockParsingCoordinator,
           let mockResult = mockParsingCoordinator.parsingResult {
            return .success(mockResult)
        }
        
        // If no mock result is available, proceed with normal processing
        return await processPDFData(data)
    }
} 