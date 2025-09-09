import Foundation
import SwiftUI

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
