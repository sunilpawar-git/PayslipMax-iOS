import SwiftUI
import Foundation

/// Global loading state manager that coordinates loading indicators across the entire application
@MainActor
final class GlobalLoadingManager: GlobalLoadingManagerProtocol {

    // MARK: - Singleton
    static let shared = GlobalLoadingManager(singleton: true)

    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var loadingMessage: String = "Loading..."
    @Published private(set) var isTransitioning = false

    // MARK: - Private Properties
    private var activeOperations: Set<String> = []
    private var operationMessages: [String: String] = [:]

    // MARK: - Initialization
    /// Public initializer for dependency injection
    public init() {}

    /// Private initializer for singleton pattern (deprecated - use public init for DI)
    private convenience init(singleton: Bool) {
        self.init()
    }

    // MARK: - Public Methods

    /// Starts a loading operation
    func startLoading(operationId: String, message: String = "Loading...") {
        activeOperations.insert(operationId)
        operationMessages[operationId] = message
        updateLoadingState()
    }

    /// Stops a loading operation
    func stopLoading(operationId: String) {
        activeOperations.remove(operationId)
        operationMessages.removeValue(forKey: operationId)
        updateLoadingState()
    }

    /// Begins a tab transition
    func beginTransition(duration: TimeInterval = 0.35) {
        isTransitioning = true
        // End transition after the specified duration using a simple approach
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            endTransition()
        }
    }

    /// Ends the transition
    func endTransition() {
        isTransitioning = false
        updateLoadingState()
    }

    /// Checks if a specific operation is loading
    func isOperationLoading(_ operationId: String) -> Bool {
        return activeOperations.contains(operationId)
    }

    /// Stops all loading operations
    func stopAllLoading() {
        activeOperations.removeAll()
        operationMessages.removeAll()
        updateLoadingState()
    }

    // MARK: - Private Methods

    /// Updates the loading state
    private func updateLoadingState() {
        // Don't show loading during transitions
        if isTransitioning {
            isLoading = false
            return
        }

        // Update loading state based on active operations
        isLoading = !activeOperations.isEmpty

        // Set the loading message from first available operation
        if let firstOperation = activeOperations.first,
           let message = operationMessages[firstOperation] {
            loadingMessage = message
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Convenience method to start loading with automatic cleanup
    func withGlobalLoading(operationId: String, message: String = "Loading...") -> some View {
        self.onAppear {
            GlobalLoadingManager.shared.startLoading(operationId: operationId, message: message)
        }
        .onDisappear {
            GlobalLoadingManager.shared.stopLoading(operationId: operationId)
        }
    }
}
