import Foundation
import SwiftUI
import Combine
import UIKit

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
        print("[ManualEntryCoordinator] showManualEntry() called - Current state: \(showManualEntryForm)")
        print("[ManualEntryCoordinator] Thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        // Force a state transition by ensuring we start from false
        if showManualEntryForm == true {
            print("[ManualEntryCoordinator] State already true, forcing reset cycle")
            showManualEntryForm = false
            // Small delay to ensure SwiftUI processes the state change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                print("[ManualEntryCoordinator] After reset delay, setting to true")
                self.showManualEntryForm = true
                print("[ManualEntryCoordinator] State set to: \(self.showManualEntryForm)")
            }
        } else {
            showManualEntryForm = true
            print("[ManualEntryCoordinator] State set to: \(showManualEntryForm)")
        }
        
        print("[ManualEntryCoordinator] Coordinator instance: \(ObjectIdentifier(self))")
        
        // Force a UI update to ensure the change is applied immediately
        DispatchQueue.main.async {
            print("[ManualEntryCoordinator] Dispatch async - showManualEntryForm: \(self.showManualEntryForm)")
        }
    }
    
    /// Hides the manual entry form
    func hideManualEntry() {
        print("[ManualEntryCoordinator] hideManualEntry() called - Current state: \(showManualEntryForm)")
        print("[ManualEntryCoordinator] Thread: \(Thread.isMainThread ? "Main" : "Background")")
        
        showManualEntryForm = false
        
        print("[ManualEntryCoordinator] showManualEntryForm set to: \(showManualEntryForm)")
        print("[ManualEntryCoordinator] Coordinator instance: \(ObjectIdentifier(self))")
        
        // Force a UI update to ensure the change is applied immediately
        DispatchQueue.main.async {
            print("[ManualEntryCoordinator] Dispatch async - showManualEntryForm: \(self.showManualEntryForm)")
        }
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
            timestamp: Date(),
            month: payslipData.month,
            year: payslipData.year,
            credits: payslipData.credits,
            debits: payslipData.debits,
            dsop: payslipData.dsop,
            tax: payslipData.tax,
            earnings: createEarningsFromManualEntry(payslipData),
            deductions: createDeductionsFromManualEntry(payslipData),
            name: payslipData.name,
            accountNumber: payslipData.accountNumber,
            panNumber: payslipData.panNumber,
            source: "Manual Entry"
        )
        
        print("[ManualEntryCoordinator] Created payslip item with ID: \(payslipItem.id)")
        return payslipItem
    }
    
    /// Creates earnings from manual entry data
    private func createEarningsFromManualEntry(_ payslipData: PayslipManualEntryData) -> [String: Double] {
        var earnings = payslipData.earnings
        
        // Add individual components if not already in the earnings dictionary
        if payslipData.basicPay > 0 && earnings["BPAY"] == nil && earnings["Basic Pay"] == nil {
            earnings["Basic Pay"] = payslipData.basicPay
        }
        if payslipData.dearnessPay > 0 && earnings["DA"] == nil && earnings["Dearness Pay"] == nil {
            earnings["Dearness Pay"] = payslipData.dearnessPay
        }
        if payslipData.militaryServicePay > 0 && earnings["MSP"] == nil && earnings["Military Service Pay"] == nil {
            earnings["Military Service Pay"] = payslipData.militaryServicePay
        }
        
        return earnings
    }
    
    /// Creates deductions from manual entry data
    private func createDeductionsFromManualEntry(_ payslipData: PayslipManualEntryData) -> [String: Double] {
        var deductions = payslipData.deductions
        
        // Add individual components if not already in the deductions dictionary
        if payslipData.tax > 0 && deductions["ITAX"] == nil && deductions["Tax"] == nil {
            deductions["Income Tax"] = payslipData.tax
        }
        if payslipData.dsop > 0 && deductions["DSOP"] == nil {
            deductions["DSOP"] = payslipData.dsop
        }
        if payslipData.incomeTax > 0 && deductions["ITAX"] == nil && deductions["Income Tax"] == nil {
            deductions["Income Tax"] = payslipData.incomeTax
        }
        
        return deductions
    }
} 