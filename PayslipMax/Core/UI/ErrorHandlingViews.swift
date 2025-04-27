import SwiftUI

/// A view modifier that shows an error alert based on a binding to an AppError.
struct ErrorAlert: ViewModifier {
    /// The binding to the optional AppError that triggers the alert.
    @Binding var error: AppError?
    /// An optional closure to execute when the alert is dismissed.
    var onDismiss: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: Binding<Bool>(
                    get: { error != nil },
                    set: { if !$0 { error = nil; onDismiss?() } } // Clear error on dismissal
                ),
                actions: {
                    Button("OK", role: .cancel) { // Standard dismiss button
                        error = nil
                        onDismiss?()
                    }
                },
                message: {
                    // Display the user-friendly message from the AppError
                    if let error = error {
                        Text(error.userMessage)
                    }
                }
            )
    }
}

extension View {
    /// Attaches an alert to the view that automatically presents when the bound AppError is non-nil.
    ///
    /// Example:
    /// ```
    /// struct MyView: View {
    ///     @State private var currentError: AppError?
    ///
    ///     var body: some View {
    ///         VStack {
    ///             // ... view content ...
    ///             Button("Trigger Error") {
    ///                 currentError = .networkConnectionLost
    ///             }
    ///         }
    ///         .errorAlert(error: $currentError)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - error: A binding to an optional `AppError`. The alert shows when this is non-nil.
    ///   - onDismiss: An optional closure to perform when the alert is dismissed.
    /// - Returns: A view modified to present an error alert.
    func errorAlert(error: Binding<AppError?>, onDismiss: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlert(error: error, onDismiss: onDismiss))
    }
} 