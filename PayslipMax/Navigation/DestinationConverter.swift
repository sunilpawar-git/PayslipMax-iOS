import Foundation
import PDFKit
import SwiftData

/// Helper class to convert between the old AppDestination and new AppNavigationDestination during the transition
@MainActor
class DestinationConverter {
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }
    
    /// Convert old AppDestination to new AppNavigationDestination
    func convertToAppNavigationDestination(_ oldDestination: AppDestination) -> AppNavigationDestination {
        switch oldDestination {
        case .home:
            return .homeTab
        case .payslips:
            return .payslipsTab
        case .payslipDetail(let payslip):
            return .payslipDetail(id: payslip.id)
        case .insights:
            return .insightsTab
        case .settings:
            return .settingsTab
        case .addPayslip:
            return .addPayslip
        case .pinSetup:
            return .pinSetup
        case .scanner:
            return .scanner
        case .pdfPreview(let document):
            return .pdfPreview(document: document)
        case .privacyPolicy:
            return .privacyPolicy
        case .termsOfService:
            return .termsOfService
        case .changePin:
            return .changePin
        }
    }
    
    /// Convert new AppNavigationDestination to old AppDestination (where possible)
    /// Note: This will require payslip lookup for payslipDetail case
    func convertToAppDestination(_ newDestination: AppNavigationDestination) async -> AppDestination? {
        switch newDestination {
        case .homeTab:
            return .home
        case .payslipsTab:
            return .payslips
        case .payslipDetail(let id):
            // Need to lookup the PayslipItem by ID
            let payslip = try? await lookupPayslip(byId: id)
            return payslip.map { .payslipDetail(payslip: $0) }
        case .insightsTab:
            return .insights
        case .settingsTab:
            return .settings
        case .addPayslip:
            return .addPayslip
        case .pinSetup:
            return .pinSetup
        case .scanner:
            return .scanner
        case .pdfPreview(let document):
            return .pdfPreview(document: document)
        case .privacyPolicy:
            return .privacyPolicy
        case .termsOfService:
            return .termsOfService
        case .changePin:
            return .changePin
        case .performanceMonitor:
            // No direct equivalent in the old system
            return nil
        }
    }
    
    /// Helper method to lookup a PayslipItem by ID
    private func lookupPayslip(byId id: UUID) async throws -> PayslipItem? {
        let payslips = try await dataService.fetch(PayslipItem.self)
        return payslips.first(where: { $0.id == id })
    }
} 