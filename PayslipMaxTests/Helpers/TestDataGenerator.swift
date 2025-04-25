import Foundation
import PDFKit
@testable import PayslipMax

/// Helper class for generating test data for unit and integration tests
class TestDataGenerator {
    
    // MARK: - PayslipItem Generators
    
    /// Generate a sample PayslipItem with default values
    static func samplePayslipItem(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        credits: Double = 5000.0,
        debits: Double = 1000.0,
        dsop: Double = 300.0,
        tax: Double = 800.0,
        name: String = "John Doe",
        accountNumber: String = "XXXX1234",
        panNumber: String = "ABCDE1234F",
        pdfData: Data? = nil
    ) -> PayslipItem {
        return PayslipItem(
            id: id,
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: pdfData
        )
    }
    
    /// Generate an array of sample PayslipItems
    static func samplePayslips(count: Int) -> [PayslipItem] {
        var payslips: [PayslipItem] = []
        let months = ["January", "February", "March", "April", "May", "June", 
                     "July", "August", "September", "October", "November", "December"]
        
        for i in 0..<count {
            let month = months[i % 12]
            let year = 2023 - (i / 12)
            
            let payslip = samplePayslipItem(
                month: month,
                year: year,
                credits: Double.random(in: 3000...8000),
                debits: Double.random(in: 500...1500),
                dsop: Double.random(in: 200...600),
                tax: Double.random(in: 500...1200)
            )
            
            payslips.append(payslip)
        }
        
        return payslips
    }
    
    // MARK: - Document Analysis Test Data
    
    /// Generate a sample DocumentAnalysis object for testing
    static func sampleDocumentAnalysis(
        pageCount: Int = 1,
        containsScannedContent: Bool = false,
        hasComplexLayout: Bool = false,
        isTextHeavy: Bool = true,
        isLargeDocument: Bool = false,
        containsTables: Bool = false,
        complexityScore: Double = 0.5
    ) -> DocumentAnalysis {
        return DocumentAnalysis(
            pageCount: pageCount,
            containsScannedContent: containsScannedContent,
            hasComplexLayout: hasComplexLayout,
            isTextHeavy: isTextHeavy,
            isLargeDocument: isLargeDocument,
            containsTables: containsTables,
            complexityScore: complexityScore
        )
    }
    
    // MARK: - Extraction Parameters Test Data
    
    /// Generate sample extraction parameters for testing
    static func sampleExtractionParameters(
        preserveFormatting: Bool = false,
        maintainTextOrder: Bool = true,
        extractTables: Bool = false,
        useGridDetection: Bool = false,
        extractImages: Bool = false,
        useOCR: Bool = false
    ) -> ExtractionParameters {
        return ExtractionParameters(
            preserveFormatting: preserveFormatting,
            maintainTextOrder: maintainTextOrder,
            extractTables: extractTables,
            useGridDetection: useGridDetection,
            extractImages: extractImages,
            useOCR: useOCR
        )
    }
    
    // MARK: - Dictionary Extraction Test Data
    
    /// Generate sample extraction results as a dictionary
    static func sampleExtractionDictionary() -> [String: String] {
        return [
            "name": "John Doe",
            "accountNumber": "XXXX1234",
            "panNumber": "ABCDE1234F",
            "month": "January",
            "year": "2023",
            "credits": "5000.00",
            "debits": "1000.00",
            "dsop": "300.00",
            "tax": "800.00"
        ]
    }
    
    // MARK: - Error Generation
    
    /// Generate sample error of specified type
    static func sampleError(ofType type: AppError) -> Error {
        return type
    }
} 