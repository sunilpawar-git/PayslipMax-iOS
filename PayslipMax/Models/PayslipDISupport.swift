import Foundation

// MARK: - DIContainer Resolver Helper

/// Helper struct for resolving the application's dependency injection container.
/// Provides safe methods to access the shared `DIContainerProtocol` instance.
struct DIContainerResolver {
    /// Synchronously resolves the shared `DIContainerProtocol` instance.
    /// Throws an error if the container has not been initialized.
    /// - Returns: The shared `DIContainerProtocol` instance.
    static func resolve() throws -> DIContainerProtocol {
        guard let container = Dependencies.container else {
            throw NSError(domain: "DIContainerResolver", code: 1, userInfo: [NSLocalizedDescriptionKey: "DIContainer not initialized"])
        }
        return container
    }
    
    /// Asynchronously resolves the shared `DIContainerProtocol` instance on the MainActor.
    /// Ensures safe access from actor-isolated contexts.
    /// Throws an error if the container has not been initialized.
    /// - Returns: The shared `DIContainerProtocol` instance.
    @MainActor
    static func resolveAsync() async throws -> DIContainerProtocol {
        guard let container = Dependencies.container else {
            throw NSError(domain: "DIContainerResolver", code: 1, userInfo: [NSLocalizedDescriptionKey: "DIContainer not initialized"])
        }
        return container
    }
}

/// Internal struct holding the shared dependency container instance.
private struct Dependencies {
    /// The static optional instance of the dependency container.
    static var container: DIContainerProtocol?
    
    /// Sets up the shared dependency container instance. Typically called once at app launch.
    /// - Parameter container: The `DIContainerProtocol` instance to use.
    static func setup(container: DIContainerProtocol) {
        self.container = container
    }
}
