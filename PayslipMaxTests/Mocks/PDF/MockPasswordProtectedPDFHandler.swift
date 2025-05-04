import Foundation
@testable import PayslipMax

class MockPasswordProtectedPDFHandler: PasswordProtectedPDFHandlerProtocol {
    var unlockCallCount = 0
    var isPasswordProtectedCallCount = 0
    
    var shouldFailUnlock = false
    var shouldReportAsPasswordProtected = false
    
    var unlockedData: Data?
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        unlockCallCount += 1
        
        if shouldFailUnlock {
            throw MockError.unlockFailed
        }
        
        return unlockedData ?? data
    }
    
    func isPasswordProtected(data: Data) -> Bool {
        isPasswordProtectedCallCount += 1
        return shouldReportAsPasswordProtected
    }
    
    func reset() {
        unlockCallCount = 0
        isPasswordProtectedCallCount = 0
        shouldFailUnlock = false
        shouldReportAsPasswordProtected = false
        unlockedData = nil
    }
} 