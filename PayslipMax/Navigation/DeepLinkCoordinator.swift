import Foundation
import SwiftUI
import Combine

/// Protocol defining the capabilities for handling deep links
@MainActor
protocol DeepLinkHandling {
    /// Parses the incoming URL and triggers the appropriate navigation.
    /// - Parameter url: The URL received by the app.
    /// - Returns: `true` if the deep link was successfully handled, `false` otherwise.
    func handleDeepLink(_ url: URL) -> Bool
}

/// Coordinates the handling of deep links by parsing URLs and using a router to navigate.
class DeepLinkCoordinator: ObservableObject, DeepLinkHandling {
    private let router: any RouterProtocol
    private let webUploadHandler: WebUploadDeepLinkHandler

    init(router: any RouterProtocol, webUploadHandler: WebUploadDeepLinkHandler? = nil) {
        self.router = router
        // Get the handler from DIContainer if not provided
        self.webUploadHandler = webUploadHandler ?? DIContainer.shared.makeWebUploadDeepLinkHandler()
        print("DeepLinkCoordinator initialized")
    }

    /// Parses the incoming URL and triggers the appropriate navigation based on the URL components.
    func handleDeepLink(_ url: URL) -> Bool {
        print("Handling deep link: \(url.absoluteString)")
        
        // First, try to handle it with the WebUploadDeepLinkHandler
        if webUploadHandler.processURL(url) {
            // Successfully handled by web upload handler
            print("Handled by WebUploadDeepLinkHandler")
            // Navigate to the Web Uploads screen
            navigateToWebUploads()
            return true
        }
        
        // Handle universal links if applicable
        if url.scheme == "https" && (url.host == "payslipmax.com" || url.host == "www.payslipmax.com") {
            if webUploadHandler.processUniversalLink(url) {
                // Successfully handled by web upload handler
                print("Handled universal link by WebUploadDeepLinkHandler")
                // Navigate to the Web Uploads screen
                navigateToWebUploads()
                return true
            }
        }

        // Otherwise, handle with the existing deep link logic
        guard url.scheme == "payslipmax" else {
            print("Deep link failed: Invalid scheme")
            return false
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host else {
            print("Deep link failed: Invalid URL components")
            return false
        }

        let path = components.path.isEmpty ? host : "\(host)\(components.path)" // Handle cases like payslipmax://home vs payslipmax://settings/profile
        print("Parsed deep link path: \(path)")

        switch path {
        case "home":
            router.switchTab(to: 0, destination: nil)
            return true
        case "payslips":
            router.switchTab(to: 1, destination: nil)
            return true
        case "insights":
            router.switchTab(to: 2, destination: nil)
            return true
        case "settings":
            router.switchTab(to: 3, destination: nil)
            return true
        case "webuploads":
            navigateToWebUploads()
            return true
        case "payslip":
            if let queryItems = components.queryItems,
               let idItem = queryItems.first(where: { $0.name == "id" }),
               let idValue = idItem.value,
               let payslipUUID = UUID(uuidString: idValue) {
                // Navigate to payslips tab first, then to detail
                router.switchTab(to: 1, destination: nil)
                router.showPayslipDetail(id: payslipUUID)
                return true
            } else {
                print("Deep link failed: Invalid or missing 'id' for payslip")
                return false
            }
        case "privacy":
            // Assuming privacy policy is shown as a sheet
            router.presentSheet(.privacyPolicy)
            return true
        case "terms":
            // Assuming terms of service is shown as a sheet
            router.presentSheet(.termsOfService)
            return true
        default:
            print("Deep link failed: Unrecognized path '\(path)'")
            return false
        }
    }
    
    /// Navigate to the Web Uploads screen
    private func navigateToWebUploads() {
        // First navigate to settings tab
        router.switchTab(to: 3, destination: nil)
        // Then navigate to web uploads destination
        router.navigate(to: .webUploads)
    }
} 