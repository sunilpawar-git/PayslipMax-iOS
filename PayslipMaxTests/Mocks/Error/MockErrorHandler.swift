import Foundation
@testable import Payslip_Max

class MockErrorHandler: ErrorHandlerProtocol {
    var handleCallCount = 0
    var lastHandledError: Error?
    
    func handle(_ error: Error, source: String, action: String) {
        handleCallCount += 1
        lastHandledError = error
    }
    
    func reset() {
        handleCallCount = 0
        lastHandledError = nil
    }
} 