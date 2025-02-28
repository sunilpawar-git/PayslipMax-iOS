import Foundation
import SwiftUI

// Forward declaration for PayslipBackup
struct PayslipBackup: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let payslipCount: Int
    let data: Data
}

// MARK: - Base Service Protocol

protocol ServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
}

// MARK: - Security Service Protocol

protocol SecurityServiceProtocol: ServiceProtocol {
    func encrypt(_ data: Data) async throws -> Data
    func decrypt(_ data: Data) async throws -> Data
    func authenticate() async throws -> Bool
}

// MARK: - Data Service Protocol

protocol DataServiceProtocol: ServiceProtocol {
    func save<T: Codable>(_ item: T) async throws
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T]
    func delete<T: Codable>(_ item: T) async throws
}

// MARK: - PDF Service Protocol

protocol PDFServiceProtocol: ServiceProtocol {
    func process(_ url: URL) async throws -> Data
    func extract(_ data: Data) async throws -> Any
}

// MARK: - Network Service Protocol

protocol NetworkServiceProtocol: ServiceProtocol {
    func get<T: Decodable>(from endpoint: String, headers: [String: String]?) async throws -> T
    func post<T: Decodable, U: Encodable>(to endpoint: String, body: U, headers: [String: String]?) async throws -> T
    func upload(to endpoint: String, data: Data, mimeType: String) async throws -> URL
    func download(from endpoint: String) async throws -> Data
}

// MARK: - Cloud Repository Protocol

protocol CloudRepositoryProtocol: ServiceProtocol {
    func syncPayslips() async throws
    func backupPayslips() async throws
    func fetchBackups() async throws -> [PayslipBackup]
    func restorePayslips() async throws
} 