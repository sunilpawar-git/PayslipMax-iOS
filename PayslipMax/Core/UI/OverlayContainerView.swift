import SwiftUI

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
