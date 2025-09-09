import SwiftUI
import Combine

/// Global overlay system that manages all application overlays
@MainActor
final class GlobalOverlaySystem: ObservableObject {

    // MARK: - Singleton Instance
    static let shared = GlobalOverlaySystem()

    // MARK: - Published Properties

    /// Currently active overlays
    @Published private(set) var activeOverlays: [OverlayItem] = []

    // MARK: - Private Properties

    /// Global loading manager reference
    private let loadingManager = GlobalLoadingManager.shared

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        setupLoadingManagerSubscription()
    }

    // MARK: - Public Methods

    /// Presents an overlay with specified configuration
    /// - Parameters:
    ///   - id: Unique identifier for the overlay
    ///   - type: Type of overlay to present
    ///   - priority: Display priority
    ///   - dismissible: Whether the overlay can be dismissed by user interaction
    func presentOverlay(
        id: String,
        type: OverlayType,
        priority: OverlayPriority = .normal,
        dismissible: Bool = true
    ) {
        let overlay = OverlayItem(
            id: id,
            type: type,
            priority: priority,
            dismissible: dismissible
        )

        // Remove any existing overlay with the same ID
        activeOverlays.removeAll { $0.id == id }

        // Add new overlay
        activeOverlays.append(overlay)

        // Sort by priority (highest first)
        activeOverlays.sort { $0.priority.rawValue > $1.priority.rawValue }

        print("🎭 GlobalOverlaySystem: Presented overlay '\(id)' of type \(type)")
    }

    /// Dismisses an overlay by ID
    /// - Parameter id: The ID of the overlay to dismiss
    func dismissOverlay(id: String) {
        if let index = activeOverlays.firstIndex(where: { $0.id == id }) {
            let overlay = activeOverlays[index]
            activeOverlays.remove(at: index)
            print("🎭 GlobalOverlaySystem: Dismissed overlay '\(id)' of type \(overlay.type)")
        }
    }

    /// Dismisses all overlays of a specific type
    /// - Parameter type: The type of overlays to dismiss
    func dismissOverlays(ofType type: OverlayType) {
        let removedCount = activeOverlays.count
        activeOverlays.removeAll { $0.type == type }
        let newCount = activeOverlays.count

        if removedCount != newCount {
            print("🎭 GlobalOverlaySystem: Dismissed \(removedCount - newCount) overlays of type \(type)")
        }
    }

    /// Dismisses all dismissible overlays
    func dismissAllDismissibleOverlays() {
        let removedCount = activeOverlays.count
        activeOverlays.removeAll { $0.dismissible }
        let newCount = activeOverlays.count

        if removedCount != newCount {
            print("🎭 GlobalOverlaySystem: Dismissed \(removedCount - newCount) dismissible overlays")
        }
    }

    /// Checks if an overlay with the given ID is currently active
    /// - Parameter id: The overlay ID to check
    /// - Returns: True if the overlay is active
    func isOverlayActive(id: String) -> Bool {
        return activeOverlays.contains { $0.id == id }
    }

    /// Gets the top-most overlay (highest priority)
    var topOverlay: OverlayItem? {
        return activeOverlays.first
    }

    // MARK: - Private Methods

    /// Sets up subscription to loading manager to coordinate loading overlays
    private func setupLoadingManagerSubscription() {
        // Monitor loading state and present/dismiss loading overlay accordingly
        loadingManager.$isLoading
            .removeDuplicates()
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.presentLoadingOverlay()
                } else {
                    self?.dismissLoadingOverlay()
                }
            }
            .store(in: &cancellables)

        // Monitor transition state to adjust overlay behavior
        loadingManager.$isTransitioning
            .removeDuplicates()
            .sink { [weak self] isTransitioning in
                if isTransitioning {
                    // During transitions, dismiss low-priority overlays
                    self?.activeOverlays.removeAll { $0.priority == .low && $0.dismissible }
                }
            }
            .store(in: &cancellables)
    }

    /// Presents the global loading overlay
    private func presentLoadingOverlay() {
        let message = loadingManager.loadingMessage
        presentOverlay(
            id: "global_loading",
            type: .loading(message: message),
            priority: .normal,
            dismissible: false
        )
    }

    /// Dismisses the global loading overlay
    private func dismissLoadingOverlay() {
        dismissOverlay(id: "global_loading")
    }
}
