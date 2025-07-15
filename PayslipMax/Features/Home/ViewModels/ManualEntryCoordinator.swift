import Foundation
import SwiftUI
import Combine

/// Coordinates all manual entry and scanned image processing for HomeViewModel
/// Follows single responsibility principle by handling only manual data entry operations
@MainActor
class ManualEntryCoordinator: ObservableObject {
    // MARK: - Published Properties
    
    /// Flag indicating whether to show the manual entry form
    @Published var showManualEntryForm = false
    
    /// Whether manual entry processing is in progress
    @Published var isProcessing = false
    
    // MARK: - Private Properties
    
    /// The handler for PDF processing operations (needed for scanned images)
    private let pdfHandler: PDFProcessingHandler
    
    /// Completion handlers for processing results
    private var onProcessingSuccess: ((PayslipItem) -> Void)?
    private var onProcessingFailure: ((Error) -> Void)?
    
    // MARK: - Initialization
    
    init(pdfHandler: PDFProcessingHandler) {
        self.pdfHandler = pdfHandler
    }
    
    // MARK: - Public Methods
    
    /// Sets completion handlers for processing results
    func setCompletionHandlers(
        onSuccess: @escaping (PayslipItem) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.onProcessingSuccess = onSuccess
        self.onProcessingFailure = onFailure
    }
    
    /// Shows the manual entry form
    func showManualEntry() {
        print("[ManualEntryCoordinator] showManualEntry() called")
        showManualEntryForm = true
        print("[ManualEntryCoordinator] showManualEntryForm set to: \(showManualEntryForm)")
    }
    
    /// Hides the manual entry form
    func hideManualEntry() {
        print("[ManualEntryCoordinator] hideManualEntry() called")
        showManualEntryForm = false
        print("[ManualEntryCoordinator] showManualEntryForm set to: \(showManualEntryForm)")
    }
    
    /// Processes a manual entry
    /// - Parameter payslipData: The payslip data to process
    func processManualEntry(_ payslipData: PayslipManualEntryData) async {
        isProcessing = true
        print("[ManualEntryCoordinator] Processing manual entry")
        
        // Create a payslip item from the manual entry data
        let payslipItem = createPayslipFromManualEntry(payslipData)
        
        // Notify success
        onProcessingSuccess?(payslipItem)
        
        isProcessing = false
    }
    
    /// Processes a scanned payslip image
    /// - Parameter image: The scanned image
    func processScannedPayslip(from image: UIImage) async {
        isProcessing = true
        print("[ManualEntryCoordinator] Processing scanned payslip image")
        
        // Use the PDF handler to process the scanned image
        let result = await pdfHandler.processScannedImage(image)
        
        switch result {
        case .success(let payslipItem):
            print("[ManualEntryCoordinator] Successfully processed scanned payslip")
            onProcessingSuccess?(payslipItem)
            
        case .failure(let error):
            print("[ManualEntryCoordinator] Failed to process scanned payslip: \(error.localizedDescription)")
            onProcessingFailure?(AppError.pdfProcessingFailed(error.localizedDescription))
        }
        
        isProcessing = false
    }
    
    /// Cancels all manual entry processing
    func cancelProcessing() {
        isProcessing = false
        hideManualEntry()
    }
    
    // MARK: - Private Methods
    
    /// Creates a PayslipItem from manual entry data
    /// - Parameter payslipData: The manual entry data
    /// - Returns: A PayslipItem instance
    private func createPayslipFromManualEntry(_ payslipData: PayslipManualEntryData) -> PayslipItem {
        print("[ManualEntryCoordinator] Creating payslip from manual entry data")
        
        // Create a new PayslipItem with the manual entry data
        let payslipItem = PayslipItem(
            id: UUID(),
            fileName: "Manual Entry - \(payslipData.employeeName ?? "Unknown")",
            extractedText: "Manual Entry",
            personalInfo: PersonalInfo(
                name: payslipData.employeeName ?? "",
                employeeId: payslipData.employeeId ?? "",
                designation: payslipData.designation ?? "",
                department: payslipData.department ?? "",
                pfNumber: payslipData.pfNumber ?? "",
                esiNumber: payslipData.esiNumber ?? "",
                uan: payslipData.uan ?? "",
                panNumber: payslipData.panNumber ?? "",
                bankAccountNumber: payslipData.bankAccountNumber ?? "",
                bankName: payslipData.bankName ?? "",
                location: payslipData.location ?? ""
            ),
            payPeriod: PayPeriod(
                startDate: payslipData.payPeriodStart ?? Date(),
                endDate: payslipData.payPeriodEnd ?? Date(),
                payDate: payslipData.payDate ?? Date()
            ),
            earnings: createEarningsFromManualEntry(payslipData),
            deductions: createDeductionsFromManualEntry(payslipData),
            payslipMetadata: PayslipMetadata(
                format: .manual,
                confidence: 1.0,
                processingDate: Date(),
                source: .manual,
                version: "1.0"
            ),
            companyInfo: CompanyInfo(
                name: payslipData.companyName ?? "",
                address: payslipData.companyAddress ?? "",
                logo: nil
            )
        )
        
        print("[ManualEntryCoordinator] Created payslip item with ID: \(payslipItem.id)")
        return payslipItem
    }
    
    /// Creates earnings from manual entry data
    private func createEarningsFromManualEntry(_ payslipData: PayslipManualEntryData) -> Earnings {
        return Earnings(
            basic: payslipData.basicSalary ?? 0,
            hra: payslipData.hra ?? 0,
            allowances: [],
            overtime: payslipData.overtime ?? 0,
            bonus: payslipData.bonus ?? 0,
            total: (payslipData.basicSalary ?? 0) + (payslipData.hra ?? 0) + (payslipData.overtime ?? 0) + (payslipData.bonus ?? 0)
        )
    }
    
    /// Creates deductions from manual entry data
    private func createDeductionsFromManualEntry(_ payslipData: PayslipManualEntryData) -> Deductions {
        return Deductions(
            pf: payslipData.pf ?? 0,
            esi: payslipData.esi ?? 0,
            tax: payslipData.tax ?? 0,
            other: [],
            total: (payslipData.pf ?? 0) + (payslipData.esi ?? 0) + (payslipData.tax ?? 0)
        )
    }
} 