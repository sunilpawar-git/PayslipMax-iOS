import SwiftUI

/// Extracts action sheet from HomeView to improve code organization
struct HomeActionSheet: ViewModifier {
    @Binding var showingActionSheet: Bool
    let onManualEntryTapped: () -> Void
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    func body(content: Content) -> some View {
        content
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Add Payslip"),
                    message: Text("Choose how you want to add a payslip"),
                    buttons: [
                        .default(Text("Upload PDF")) {
                            navigationCoordinator.showDocumentPicker()
                        },
                        .default(Text("Scan Document")) {
                            navigationCoordinator.showCameraScanner()
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
        onManualEntryTapped: @escaping () -> Void
    ) -> some View {
        self.modifier(HomeActionSheet(
            showingActionSheet: showingActionSheet,
            onManualEntryTapped: onManualEntryTapped
        ))
    }
} 