import Foundation
import SwiftUI
@testable import Payslip_Max

class MockErrorHandler: ErrorHandler {
    var handleErrorCallCount = 0
    var lastErrorHandled: Error?
    
    override func handleError(_ error: Error, retry: (() -> Void)? = nil) {
        handleErrorCallCount += 1
        lastErrorHandled = error
    }
    
    override func showAlert(
        title: String,
        message: String,
        primaryButtonText: String = "OK",
        primaryAction: (() -> Void)? = nil,
        secondaryButtonText: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        // Do nothing in test mock
    }
    
    func reset() {
        handleErrorCallCount = 0
        lastErrorHandled = nil
    }
} 