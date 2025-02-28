import Foundation
import SwiftUI
import SwiftData

// This file contains all the imports needed for the network infrastructure
// It helps resolve circular dependencies and import issues

// Re-export the ServiceProtocol
typealias ServiceProtocol = Payslip_Max.ServiceProtocol

// Define the FeatureError enum
enum FeatureError: Error {
    case premiumRequired
    case notImplemented
    case notAvailable
}

// Import the PayslipItem model
typealias PayslipItem = Payslip_Max.PayslipItem

// Mock classes for testing
class MockNetworkService: NetworkServiceProtocol {
    var isInitialized: Bool = true
    
    func initialize() async throws {
        // Do nothing
    }
    
    func get<T: Decodable>(from endpoint: String, headers: [String: String]? = nil) async throws -> T {
        throw FeatureError.notImplemented
    }
    
    func post<T: Decodable, U: Encodable>(to endpoint: String, body: U, headers: [String: String]? = nil) async throws -> T {
        throw FeatureError.notImplemented
    }
    
    func upload(to endpoint: String, data: Data, mimeType: String) async throws -> URL {
        throw FeatureError.notImplemented
    }
    
    func download(from endpoint: String) async throws -> Data {
        throw FeatureError.notImplemented
    }
}

class MockCloudRepository: CloudRepositoryProtocol {
    func syncPayslips(_ payslips: [PayslipItem]) async throws {
        throw FeatureError.notImplemented
    }
    
    func backupPayslips(_ payslips: [PayslipItem]) async throws -> URL {
        throw FeatureError.notImplemented
    }
    
    func fetchBackups() async throws -> [PayslipBackup] {
        throw FeatureError.notImplemented
    }
    
    func restoreFromBackup(_ backupId: String) async throws -> [PayslipItem] {
        throw FeatureError.notImplemented
    }
} 