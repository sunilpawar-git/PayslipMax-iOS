//
//  ExampleViewModel.swift
//  Payslip Max
//
//  Created by Sunil on 26/02/25.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

/// Example ViewModel that demonstrates the use of the @Inject property wrapper
@MainActor
class ExampleViewModel: ObservableObject {
    @Published var payslips: [PayslipItem] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let dataService: DataServiceProtocol
    private let securityService: SecurityServiceProtocol
    private let payslipsViewModel: PayslipsViewModel
    
    init() {
        self.dataService = DIContainer.shared.dataService
        self.securityService = DIContainer.shared.securityService
        self.payslipsViewModel = DIContainer.shared.makePayslipsViewModel()
    }
    
    // MARK: - Public Methods
    
    /// Load payslips using the injected services
    func loadPayslips() async {
        isLoading = true
        error = nil
        
        do {
            payslips = try await dataService.fetch(PayslipItem.self)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Example of using another injected ViewModel
    func refreshPayslipsList() async {
        // This demonstrates how we can use another ViewModel that was injected
        // In a real app, you might want to use a different pattern for ViewModel-to-ViewModel communication
        // For now, just call our own loadPayslips method
        await loadPayslips()
    }
    
    func addPayslip(_ payslip: PayslipItem) async {
        do {
            try await dataService.save(payslip)
            await loadPayslips()
        } catch {
            self.error = error
        }
    }
    
    func deletePayslip(_ payslip: PayslipItem) async {
        do {
            try await dataService.delete(payslip)
            await loadPayslips()
        } catch {
            self.error = error
        }
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