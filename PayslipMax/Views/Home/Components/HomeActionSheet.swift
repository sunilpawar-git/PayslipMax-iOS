import SwiftUI

/// Extracts action sheet from HomeView to improve code organization
struct HomeActionSheet: ViewModifier {
    @Binding var showingActionSheet: Bool
    @Binding var showingDocumentPicker: Bool
    @Binding var showingScanner: Bool
    let onManualEntryTapped: () -> Void
    
    func body(content: Content) -> some View {
        content
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Add Payslip"),
                    message: Text("Choose how you want to add a payslip"),
                    buttons: [
                        .default(Text("Upload PDF")) {
                            showingDocumentPicker = true
                        },
                        .default(Text("Scan Document")) {
                            showingScanner = true
                        },
                        .default(Text("Manual Entry")) {
                            onManualEntryTapped()
                        },
                        .cancel()
                    ]
                )
            }
    }
}

extension View {
    func homeActionSheet(
        showingActionSheet: Binding<Bool>,
        showingDocumentPicker: Binding<Bool>,
        showingScanner: Binding<Bool>,
        onManualEntryTapped: @escaping () -> Void
    ) -> some View {
        self.modifier(HomeActionSheet(
            showingActionSheet: showingActionSheet,
            showingDocumentPicker: showingDocumentPicker,
            showingScanner: showingScanner,
            onManualEntryTapped: onManualEntryTapped
        ))
    }
} 