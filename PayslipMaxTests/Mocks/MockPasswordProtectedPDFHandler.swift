import Foundation
import PDFKit
@testable import PayslipMax

class MockPasswordProtectedPDFHandler: PasswordProtectedPDFHandler {
    var handlePasswordProtectedPDFCallCount = 0
    var mockData: Data = Data()
    var shouldFail = false
    var passwordInput: String?
    
    override func handlePasswordProtectedPDF(data: Data, completion: @escaping (Result<Data, PDFProcessingError>) -> Void) {
        handlePasswordProtectedPDFCallCount += 1
        
        if shouldFail {
            completion(.failure(.passwordLocked))
            return
        }
        
        completion(.success(mockData))
    }
    
    override func unlockPDF(data: Data, password: String) async -> Result<Data, PDFProcessingError> {
        passwordInput = password
        
        if shouldFail {
            return .failure(.passwordLocked)
        }
        
        return .success(mockData)
    }
    
    func reset() {
        handlePasswordProtectedPDFCallCount = 0
        mockData = Data()
        shouldFail = false
        passwordInput = nil
    }
} 