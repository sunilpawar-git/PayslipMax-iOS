import Foundation
import PDFKit
@testable import PayslipMax

// MARK: - Mock Home Navigation Coordinator

/// Mock implementation of HomeNavigationCoordinator for testing purposes.
/// Provides configurable behavior for navigation operations.
class MockHomeNavigationCoordinator: HomeNavigationCoordinator {
    var navigateToPayslipDetailCalled = false
    var setPDFDocumentCalled = false

    var mockPDFDocument: PDFDocument?
    var mockURL: URL?

    /// Navigates to payslip detail view and tracks the call
    override func navigateToPayslipDetail(for payslip: PayslipItem) {
        navigateToPayslipDetailCalled = true
        super.navigateToPayslipDetail(for: payslip)
    }

    /// Sets PDF document and tracks the call with mock values
    override func setPDFDocument(_ document: PDFDocument?, url: URL?) {
        setPDFDocumentCalled = true
        mockPDFDocument = document
        mockURL = url
        super.setPDFDocument(document, url: url)
    }

    /// Resets all tracking flags and mock data to default values
    func reset() {
        navigateToPayslipDetailCalled = false
        setPDFDocumentCalled = false
        mockPDFDocument = nil
        mockURL = nil
        resetNavigation()
    }
}
