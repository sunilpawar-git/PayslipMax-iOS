import Foundation
import PDFKit
@testable import Payslip_Max

// Define the protocol based on PDFParsingCoordinator functionality
// protocol PDFParsingCoordinatorProtocol {
//    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem?
//    func selectBestParser(for text: String) -> PayslipParser?
// }

class MockParsingCoordinator: PDFParsingCoordinatorProtocol {
    nonisolated(unsafe) var shouldFail = false
    nonisolated(unsafe) var parsePayslipCallCount = 0
    nonisolated(unsafe) var selectBestParserCallCount = 0
    nonisolated(unsafe) var parsePayslipResult: PayslipItem?
    nonisolated(unsafe) var selectBestParserResult: PayslipParser?
    
    init() {}
    
    nonisolated func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        parsePayslipCallCount += 1
        return shouldFail ? nil : parsePayslipResult
    }
    
    nonisolated func selectBestParser(for text: String) -> PayslipParser? {
        selectBestParserCallCount += 1
        return shouldFail ? nil : selectBestParserResult
    }
    
    nonisolated func reset() {
        shouldFail = false
        parsePayslipCallCount = 0
        selectBestParserCallCount = 0
        parsePayslipResult = nil
        selectBestParserResult = nil
    }
} 