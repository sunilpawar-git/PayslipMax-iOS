import SwiftUI
import Foundation

/// Global loading state manager that coordinates loading indicators across the entire application
@MainActor
final class GlobalLoadingManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = GlobalLoadingManager()
    
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var loadingMessage: String = "Loading..."
    @Published private(set) var isTransitioning = false
    
    // MARK: - Private Properties
    private var activeOperations: Set<String> = []
    private var operationMessages: [String: String] = [:]
    private var operationStartTimes: [String: Date] = [:]
    private let minimumDisplayDuration: TimeInterval = 0.5 // Don't show overlay for operations shorter than 500ms
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Starts a loading operation
    func startLoading(operationId: String, message: String = "Loading...", showImmediately: Bool = false) {
        activeOperations.insert(operationId)
        operationMessages[operationId] = message
        operationStartTimes[operationId] = Date()
        
        if showImmediately {
            updateLoadingState()
        } else {
            // Delay showing the loading indicator to prevent flashing for quick operations
            Task {
                try? await Task.sleep(nanoseconds: UInt64(minimumDisplayDuration * 1_000_000_000))
                // Only show if operation is still active
                if activeOperations.contains(operationId) {
                    updateLoadingState()
                }
            }
        }
    }
    
    /// Starts a quick loading operation that won't show overlay (for navigation/tab switches)
    func startQuickLoading(operationId: String, message: String = "Loading...") {
        activeOperations.insert(operationId)
        operationMessages[operationId] = message
        operationStartTimes[operationId] = Date()
        // Don't update loading state - this prevents the overlay from showing
    }
    
    /// Stops a loading operation
    func stopLoading(operationId: String) {
        let wasActive = activeOperations.contains(operationId)
        activeOperations.remove(operationId)
        operationMessages.removeValue(forKey: operationId)
        operationStartTimes.removeValue(forKey: operationId)
        
        if wasActive {
            updateLoadingState()
        }
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
        operationStartTimes.removeAll()
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
        
        // Filter out operations that are too quick to warrant showing a loading indicator
        let significantOperations = activeOperations.filter { operationId in
            guard let startTime = operationStartTimes[operationId] else { return false }
            let elapsed = Date().timeIntervalSince(startTime)
            return elapsed >= minimumDisplayDuration
        }
        
        // Update loading state based on significant operations only
        isLoading = !significantOperations.isEmpty
        
        // Set the loading message from first available significant operation
        if let firstOperation = significantOperations.first,
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
    
    /// Convenience method for quick operations that shouldn't show overlay
    func withQuickLoading(operationId: String, message: String = "Loading...") -> some View {
        self.onAppear {
            GlobalLoadingManager.shared.startQuickLoading(operationId: operationId, message: message)
        }
        .onDisappear {
            GlobalLoadingManager.shared.stopLoading(operationId: operationId)
        }
    }
} 
