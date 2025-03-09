//
//  Payslip_MaxApp.swift
//  Payslip Max
//
//  Created by Sunil on 21/01/25.
//

import SwiftUI
import SwiftData

@main
struct Payslip_MaxApp: App {
    @StateObject private var router = NavRouter()
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Payslip.self,
                Allowance.self,
                Deduction.self,
                PostingDetails.self,
                PayslipItem.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Initialize encryption services
            setupEncryptionServices()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    /// Sets up encryption services for the app
    private func setupEncryptionServices() {
        // Initialize the security service
        Task {
            do {
                try await DIContainer.shared.securityService.initialize()
                print("Security service initialized successfully")
                
                // Initialize the PayslipSensitiveDataHandler factory
                PayslipSensitiveDataHandler.Factory.initialize()
                
                // Create an adapter that makes SecurityServiceImpl conform to SensitiveDataEncryptionService
                let securityService = DIContainer.shared.securityService
                let encryptionServiceAdapter = SecurityServiceAdapter(securityService: securityService)
                
                // Configure with the adapter and store the result
                let result = PayslipSensitiveDataHandler.Factory.setEncryptionServiceFactory {
                    return encryptionServiceAdapter
                }
                
                print("Encryption service factory configured successfully: \(result)")
            } catch {
                print("Failed to initialize security service: \(error)")
            }
        }
    }
    
    /// Adapter to make SecurityServiceImpl conform to SensitiveDataEncryptionService
    private class SecurityServiceAdapter: SensitiveDataEncryptionService {
        private let securityService: SecurityServiceProtocol
        
        init(securityService: SecurityServiceProtocol) {
            self.securityService = securityService
        }
        
        func encrypt(_ data: Data) throws -> Data {
            // Create a synchronous wrapper around the async method
            let semaphore = DispatchSemaphore(value: 0)
            var resultData: Data?
            var resultError: Error?
            
            Task {
                do {
                    resultData = try await securityService.encrypt(data)
                } catch {
                    resultError = error
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            if let error = resultError {
                throw error
            }
            
            guard let encryptedData = resultData else {
                throw SensitiveDataError.encryptionServiceCreationFailed
            }
            
            return encryptedData
        }
        
        func decrypt(_ data: Data) throws -> Data {
            // Create a synchronous wrapper around the async method
            let semaphore = DispatchSemaphore(value: 0)
            var resultData: Data?
            var resultError: Error?
            
            Task {
                do {
                    resultData = try await securityService.decrypt(data)
                } catch {
                    resultError = error
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            if let error = resultError {
                throw error
            }
            
            guard let decryptedData = resultData else {
                throw SensitiveDataError.encryptionServiceCreationFailed
            }
            
            return decryptedData
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
                .environmentObject(router)
                .onOpenURL { url in
                    // Handle deep links using our NavRouter
                    router.handleDeepLink(url)
                }
        }
    }
}
