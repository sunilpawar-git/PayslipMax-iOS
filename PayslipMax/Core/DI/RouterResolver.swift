import Foundation
import UIKit

/// Router resolver for handling navigation router resolution
/// Provides centralized router access logic with fallback mechanisms
@MainActor
class RouterResolver {
    /// Resolves the global navigation router with multiple fallback strategies
    /// - Returns: The resolved router instance
    static func resolveRouter() -> any RouterProtocol {
        // Check if we already have a router instance
        if let appDelegate = UIApplication.shared.delegate,
           let router = objc_getAssociatedObject(appDelegate, "router") as? (any RouterProtocol) {
            return router
        }

        // Try to resolve from the app container
        if let sharedRouter = AppContainer.shared.resolve((any RouterProtocol).self) {
            return sharedRouter
        }

        // If we can't find the router, log a warning and create a new one
        // This should rarely happen in production
        print("Warning: Creating a new router instance in RouterResolver. This may cause navigation issues.")
        return NavRouter()
    }
}
