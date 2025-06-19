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

// MARK: - Supporting Types

/// Represents an overlay item in the system
struct OverlayItem: Identifiable, Equatable {
    let id: String
    let type: OverlayType
    let priority: OverlayPriority
    let dismissible: Bool
    let presentedAt: Date = Date()
    
    static func == (lhs: OverlayItem, rhs: OverlayItem) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Types of overlays that can be presented
enum OverlayType: Equatable {
    case loading(message: String)
    case error(title: String, message: String)
    case success(message: String)
    case custom(view: AnyView)
    
    var description: String {
        switch self {
        case .loading: return "Loading"
        case .error: return "Error"
        case .success: return "Success"
        case .custom: return "Custom"
        }
    }
    
    static func == (lhs: OverlayType, rhs: OverlayType) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.error, .error), (.success, .success), (.custom, .custom):
            return true
        default:
            return false
        }
    }
}

/// Priority levels for overlays
enum OverlayPriority: Int, CaseIterable {
    case low = 1
    case normal = 2
    case high = 3
    case critical = 4
    
    var description: String {
        switch self {
        case .low: return "Low Priority"
        case .normal: return "Normal Priority"
        case .high: return "High Priority"
        case .critical: return "Critical Priority"
        }
    }
}

// MARK: - SwiftUI Integration

/// View that renders the global overlay system
struct GlobalOverlayContainer: View {
    @StateObject private var overlaySystem = GlobalOverlaySystem.shared
    
    var body: some View {
        ZStack {
            // Content goes here (will be inserted by parent)
            Color.clear
            
            // Render active overlays
            ForEach(overlaySystem.activeOverlays) { overlay in
                overlayView(for: overlay)
                    .zIndex(Double(overlay.priority.rawValue * 1000))
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.25), value: overlaySystem.activeOverlays.count)
            }
        }
    }
    
    @ViewBuilder
    private func overlayView(for overlay: OverlayItem) -> some View {
        switch overlay.type {
        case .loading(let message):
            LoadingOverlayView(message: message)
                .onTapGesture {
                    if overlay.dismissible {
                        overlaySystem.dismissOverlay(id: overlay.id)
                    }
                }
        
        case .error(let title, let message):
            ErrorOverlayView(title: title, message: message) {
                overlaySystem.dismissOverlay(id: overlay.id)
            }
        
        case .success(let message):
            SuccessOverlayView(message: message) {
                overlaySystem.dismissOverlay(id: overlay.id)
            }
        
        case .custom(let view):
            view
                .onTapGesture {
                    if overlay.dismissible {
                        overlaySystem.dismissOverlay(id: overlay.id)
                    }
                }
        }
    }
}

// MARK: - Overlay View Components

/// Optimized loading overlay view
private struct LoadingOverlayView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
        }
        .accessibilityIdentifier("global_loading_overlay")
    }
}

/// Error overlay view
private struct ErrorOverlayView: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("OK", action: onDismiss)
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 40)
        }
    }
}

/// Success overlay view
private struct SuccessOverlayView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.green)
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            // Auto-dismiss success messages after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onDismiss()
            }
        }
    }
} 