import SwiftUI
import PDFKit

/// Protocol defining the factory responsible for creating views for navigation destinations.
@MainActor
protocol DestinationFactoryProtocol {
    /// Creates a view suitable for pushing onto a NavigationStack.
    /// - Parameter destination: The destination to create a view for.
    /// - Returns: A view conforming to SwiftUI's View protocol.
    @ViewBuilder func makeDestinationView(for destination: AppNavigationDestination) -> AnyView // Use new enum
    
    /// Creates a view suitable for modal presentation (sheet or full screen cover).
    /// - Parameters:
    ///   - destination: The destination to create a view for.
    ///   - isSheet: Indicates if the presentation is a sheet (true) or full screen cover (false).
    ///   - onDismiss: A closure to be called when the modal view is dismissed.
    /// - Returns: A view conforming to SwiftUI's View protocol.
    @ViewBuilder func makeModalView(for destination: AppNavigationDestination, isSheet: Bool, onDismiss: @escaping () -> Void) -> AnyView // Use new enum
} 