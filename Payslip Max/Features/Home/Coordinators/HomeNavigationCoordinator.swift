import Foundation
import SwiftUI
import Combine
import PDFKit

/// Coordinator that manages navigation for the Home feature
@MainActor
class HomeNavigationCoordinator: ObservableObject {
    // MARK: - Published Properties
    
    /// Flag indicating whether to navigate to the detail view for a newly added payslip.
    @Published var navigateToNewPayslip = false
    
    /// Flag indicating whether to show the parsing feedback view.
    @Published var showParsingFeedbackView = false
    
    /// Flag indicating whether to show the manual entry form.
    @Published var showManualEntryForm = false
    
    /// The newly added payslip for direct navigation.
    @Published var newlyAddedPayslip: PayslipItem?
    
    /// The parsed payslip item to display in the feedback view.
    @Published var parsedPayslipItem: PayslipItem?
    
    /// The PDF document being processed.
    @Published var currentPDFDocument: PDFDocument?
    
    /// The current PDF URL that is being processed.
    @Published var currentPDFURL: URL?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Navigation Methods
    
    /// Shows the parsing feedback view with the specified payslip item.
    /// - Parameter payslipItem: The payslip item to display.
    func showParsingFeedback(for payslipItem: PayslipItem) {
        parsedPayslipItem = payslipItem
        showParsingFeedbackView = true
    }
    
    /// Navigates to the detail view for the newly added payslip.
    /// - Parameter payslipItem: The newly added payslip.
    func navigateToPayslipDetail(for payslipItem: PayslipItem) {
        newlyAddedPayslip = payslipItem
        navigateToNewPayslip = true
    }
    
    /// Shows the manual entry form.
    func showManualEntry() {
        showManualEntryForm = true
    }
    
    /// Sets the current PDF document and URL.
    /// - Parameters:
    ///   - document: The PDF document to set.
    ///   - url: The URL of the PDF document.
    func setPDFDocument(_ document: PDFDocument?, url: URL?) {
        currentPDFDocument = document
        currentPDFURL = url
    }
    
    /// Resets all navigation state.
    func resetNavigation() {
        navigateToNewPayslip = false
        showParsingFeedbackView = false
        showManualEntryForm = false
        newlyAddedPayslip = nil
        parsedPayslipItem = nil
        currentPDFDocument = nil
        currentPDFURL = nil
    }
} 