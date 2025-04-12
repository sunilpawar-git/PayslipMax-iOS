import Foundation
import PDFKit
import SwiftUI

/// Service class responsible for PDF-related operations for payslips
@MainActor
class PayslipPDFService {
    // MARK: - Singleton Instance
    static let shared = PayslipPDFService()
    
    // MARK: - Dependencies
    private let dataService: DataServiceProtocol
    private let validationService: PDFValidationServiceProtocol
    private let formattingService: PayslipPDFFormattingServiceProtocol
    private let urlService: PayslipPDFURLServiceProtocol
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil, 
         validationService: PDFValidationServiceProtocol? = nil,
         formattingService: PayslipPDFFormattingServiceProtocol? = nil,
         urlService: PayslipPDFURLServiceProtocol? = nil) {
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.validationService = validationService ?? PDFValidationService.shared
        self.formattingService = formattingService ?? PayslipPDFFormattingService.shared
        self.urlService = urlService ?? PayslipPDFURLService.shared
    }
    
    // MARK: - Public Methods
    
    /// Creates a professionally formatted PDF with payslip details
    func createFormattedPlaceholderPDF(from payslipData: Models.PayslipData, payslip: AnyPayslip) -> Data {
        return formattingService.createFormattedPlaceholderPDF(from: payslipData, payslip: payslip)
    }
    
    /// Get the URL for the original PDF, creating or repairing it if needed
    func getPDFURL(for payslip: AnyPayslip) async throws -> URL? {
        return try await urlService.getPDFURL(for: payslip)
    }
} 