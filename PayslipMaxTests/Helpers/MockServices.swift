import Foundation
@testable import Payslip_Max

final class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var shouldFail: Bool = false
    
    func initialize() async throws {
        isInitialized = true
    }
    
    func authenticate() async throws -> Bool {
        if shouldFail {
            throw NSError(domain: "MockError", code: -1, userInfo: nil)
        }
        return true
    }
    
    func encrypt(_ data: Data) async throws -> Data {
        return data
    }
    
    func decrypt(_ data: Data) async throws -> Data {
        return data
    }
} 