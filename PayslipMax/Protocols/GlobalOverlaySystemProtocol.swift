import SwiftUI
import Combine

/// Protocol for managing global overlay system functionality
/// Supports both singleton and dependency injection patterns
@MainActor
protocol GlobalOverlaySystemProtocol: ObservableObject {

    // MARK: - Published Properties

    /// Currently active overlays
    var activeOverlays: [OverlayItem] { get }

    // MARK: - Overlay Management Methods

    /// Presents an overlay with specified configuration
    /// - Parameters:
    ///   - id: Unique identifier for the overlay
    ///   - type: Type of overlay to present
    ///   - priority: Display priority
    ///   - dismissible: Whether the overlay can be dismissed by user interaction
    func presentOverlay(
        id: String,
        type: OverlayType,
        priority: OverlayPriority,
        dismissible: Bool
    )

    /// Dismisses an overlay by ID
    /// - Parameter id: The ID of the overlay to dismiss
    func dismissOverlay(id: String)

    /// Dismisses all overlays of a specific type
    /// - Parameter type: The type of overlays to dismiss
    func dismissOverlays(ofType type: OverlayType)

    /// Dismisses all dismissible overlays
    func dismissAllDismissibleOverlays()

    /// Checks if an overlay with the given ID is currently active
    /// - Parameter id: The overlay ID to check
    /// - Returns: True if the overlay is active
    func isOverlayActive(id: String) -> Bool

    /// Gets the top-most overlay (highest priority)
    var topOverlay: OverlayItem? { get }
}
