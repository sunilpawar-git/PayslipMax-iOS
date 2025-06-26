import Foundation
import PDFKit

/// Mock implementation of PDFParsingCoordinatorProtocol for testing purposes.
final class MockPDFParsingCoordinator: PDFParsingCoordinatorProtocol {
    
    // MARK: - Properties
    var textToReturn = "Mock PDF text for testing purposes"
    var payslipToReturn: PayslipItem?
    var parserToReturn: PayslipParser?
    var shouldThrowError = false
    
    // MARK: - Initialization
    init(payslipToReturn: PayslipItem? = nil, parserToReturn: PayslipParser? = nil) {
        self.payslipToReturn = payslipToReturn
        self.parserToReturn = parserToReturn
        
        // Create default payslip if none provided
        if self.payslipToReturn == nil {
            self.payslipToReturn = PayslipItem(
                id: UUID(),
                timestamp: Date(),
                month: "January",
                year: 2023,
                credits: 10000.0,
                debits: 2000.0,
                dsop: 500.0,
                tax: 1000.0,
                name: "Mock User",
                accountNumber: "123456789",
                panNumber: "ABCDE1234F",
                pdfData: Data()
            )
        }
    }
    
    // MARK: - Public Methods
    func reset() {
        shouldThrowError = false
    }
    
    // MARK: - PDFParsingCoordinatorProtocol Implementation
    func extractFullText(from document: PDFDocument) -> String? {
        return textToReturn
    }
    
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem? {
        if shouldThrowError {
            throw MockError.processingFailed
        }
        return payslipToReturn
    }
    
    func parsePayslip(pdfDocument: PDFDocument, using parserName: String) async throws -> PayslipItem? {
        if shouldThrowError {
            throw MockError.processingFailed
        }
        
        if parserName == parserToReturn?.name || parserName == "MockParser1" {
            return payslipToReturn
        } else {
            return nil
        }
    }
    
    func selectBestParser(for text: String) -> PayslipParser? {
        return parserToReturn
    }
} 