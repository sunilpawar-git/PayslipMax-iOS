//
//  ExampleViewModel.swift
//  Payslip Max
//
//  Created by Sunil on 26/02/25.
//

import Foundation
import SwiftUI
import Combine

/// Example ViewModel that demonstrates the use of the @Inject property wrapper
@MainActor
class ExampleViewModel: ObservableObject {
    // Using the @Inject property wrapper to inject dependencies
    // This will use our non-actor-isolated DIResolver
    @Inject private var securityService: SecurityServiceProtocol
    @Inject private var dataService: DataServiceProtocol
    
    // For ViewModels, we should create them on the MainActor
    // So we'll inject them in the initializer instead of using property wrappers
    private var payslipsViewModel: PayslipsViewModel
    
    // Published properties
    @Published private(set) var isLoading = false
    @Published private(set) var payslips: [PayslipItem] = []
    @Published var error: Error?
    
    // MARK: - Initialization
    
    init() {
        // Create the PayslipsViewModel on the MainActor
        self.payslipsViewModel = DIContainer.shared.makePayslipsViewModel()
    }
    
    // MARK: - Public Methods
    
    /// Load payslips using the injected services
    func loadPayslips() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Use the injected data service
            let items = try await dataService.fetch(PayslipItem.self)
            self.payslips = items
            
            // Example of using the injected security service
            let authenticated = try await securityService.authenticate()
            // Use the authentication result
            if !authenticated {
                throw NSError(domain: "Authentication", code: 401, userInfo: nil)
            }
        } catch {
            self.error = error
        }
    }
    
    /// Example of using another injected ViewModel
    func refreshPayslipsList() async {
        // This demonstrates how we can use another ViewModel that was injected
        // In a real app, you might want to use a different pattern for ViewModel-to-ViewModel communication
        // For now, just call our own loadPayslips method
        await loadPayslips()
    }
}

// MARK: - Preview Helper
extension ExampleViewModel {
    static func preview() -> ExampleViewModel {
        // Set up the container for previews
        let testContainer = DIContainer.forTesting()
        DIContainer.setShared(testContainer)
        
        return ExampleViewModel()
    }
} 