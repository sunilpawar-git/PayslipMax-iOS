import Foundation
import SwiftUI

/// Utility structs for equatable comparisons in SwiftUI
public struct GlobalEmptyStateEquatable: Equatable {
    public init() {}
    
    public static func == (lhs: GlobalEmptyStateEquatable, rhs: GlobalEmptyStateEquatable) -> Bool {
        return true
    }
} 