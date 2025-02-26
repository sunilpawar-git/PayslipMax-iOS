//
//  Inject.swift
//  Payslip Max
//
//  Created by Sunil on 26/02/25.
//

import Foundation
import SwiftUI

// MARK: - Non-Actor-Isolated Container
// This container is specifically designed to be used outside of the actor system
// It provides a safe way to access dependencies without actor isolation issues
final class DIResolver {
    // Singleton instance
    static let shared = DIResolver()
    
    // Services - these are not actor-isolated
    private var securityService: any SecurityServiceProtocol
    private var dataService: any DataServiceProtocol
    private var pdfService: any PDFServiceProtocol
    
    // Private initializer for singleton
    private init() {
        // Initialize with default implementations
        // These will be replaced when setupWithContainer is called
        self.securityService = DefaultSecurityService()
        self.dataService = DefaultDataService()
        self.pdfService = DefaultPDFService()
    }
    
    // Setup method to be called from the MainActor
    @MainActor
    func setupWithContainer(_ container: DIContainer) {
        // Copy references to the services from the container
        self.securityService = container.securityService
        self.dataService = container.dataService
        self.pdfService = container.pdfService
    }
    
    // Resolve method for property wrappers
    func resolve<T>(_ type: T.Type) -> T {
        switch type {
        case is SecurityServiceProtocol.Type:
            return securityService as! T
        case is DataServiceProtocol.Type:
            return dataService as! T
        case is PDFServiceProtocol.Type:
            return pdfService as! T
        default:
            fatalError("No provider found for type \(T.self)")
        }
    }
}

// MARK: - Default Service Implementations
// These are simple placeholders that will be replaced with real implementations
private class DefaultSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        fatalError("This is a placeholder implementation")
    }
    
    func encrypt(_ data: Data) async throws -> Data {
        fatalError("This is a placeholder implementation")
    }
    
    func decrypt(_ data: Data) async throws -> Data {
        fatalError("This is a placeholder implementation")
    }
    
    func authenticate() async throws -> Bool {
        fatalError("This is a placeholder implementation")
    }
}

private class DefaultDataService: DataServiceProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        fatalError("This is a placeholder implementation")
    }
    
    func save<T: Codable>(_ item: T) async throws {
        fatalError("This is a placeholder implementation")
    }
    
    func fetch<T: Codable>(_ type: T.Type) async throws -> [T] {
        fatalError("This is a placeholder implementation")
    }
    
    func delete<T: Codable>(_ item: T) async throws {
        fatalError("This is a placeholder implementation")
    }
}

private class DefaultPDFService: PDFServiceProtocol {
    var isInitialized: Bool = false
    
    func initialize() async throws {
        fatalError("This is a placeholder implementation")
    }
    
    func process(_ url: URL) async throws -> Data {
        fatalError("This is a placeholder implementation")
    }
    
    func extract(_ data: Data) async throws -> PayslipItem {
        fatalError("This is a placeholder implementation")
    }
}

// MARK: - Property Wrappers
@propertyWrapper
struct Inject<T> {
    let wrappedValue: T
    
    init() {
        self.wrappedValue = DIResolver.shared.resolve(T.self)
    }
}

// MARK: - Setup Extension for DIContainer
@MainActor
extension DIContainer {
    // Call this method when the container is created
    func setupResolver() {
        DIResolver.shared.setupWithContainer(self)
    }
} 