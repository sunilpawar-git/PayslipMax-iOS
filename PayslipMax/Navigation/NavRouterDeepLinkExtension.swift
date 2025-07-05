import Foundation
import SwiftUI
import PDFKit

extension NavRouter {
    /// Handle deep link URLs
    func handleDeepLink(_ url: URL) {
        guard url.scheme == "payslipmax" else { return }
        
        let path = url.path.lowercased()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems ?? []
        
        switch path {
        case "/home":
            switchTab(to: 0)
            
        case "/payslips":
            switchTab(to: 1)
            
        case "/payslip":
            if let idString = queryItems.first(where: { $0.name == "id" })?.value,
               let id = UUID(uuidString: idString) {
                switchTab(to: 1)
                navigate(to: .payslipDetail(id: id))
            }
            
        case "/insights":
            switchTab(to: 2)
            
        case "/settings":
            switchTab(to: 3)
            
        case "/privacy":
            presentSheet(.privacyPolicy)
            
        case "/terms":
            presentSheet(.termsOfService)
            
        default:
            // Default to home tab
            switchTab(to: 0)
        }
    }
} 