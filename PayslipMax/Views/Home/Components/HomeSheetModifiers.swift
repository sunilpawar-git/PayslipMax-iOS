import SwiftUI

/// Extracts sheet modifiers from HomeView to improve code organization
struct HomeSheetModifiers: ViewModifier {
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var manualEntryCoordinator: ManualEntryCoordinator
    @Binding var showingDocumentPicker: Bool
    @Binding var showingScanner: Bool
    let onDocumentPicked: (URL) -> Void
    
    init(viewModel: HomeViewModel, showingDocumentPicker: Binding<Bool>, showingScanner: Binding<Bool>, onDocumentPicked: @escaping (URL) -> Void) {
        self.viewModel = viewModel
        self.manualEntryCoordinator = viewModel.manualEntryCoordinator
        self._showingDocumentPicker = showingDocumentPicker
        self._showingScanner = showingScanner
        self.onDocumentPicked = onDocumentPicked
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerView(onDocumentPicked: onDocumentPicked)
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView(onScanCompleted: { image in
                    viewModel.processScannedPayslip(from: image)
                })
            }
            .sheet(isPresented: $manualEntryCoordinator.showManualEntryForm) {
                ManualEntryView(onSave: { payslipData in
                    print("[HomeSheetModifiers] Manual entry saved")
                    viewModel.processManualEntry(payslipData)
                })
                .onAppear {
                    print("[HomeSheetModifiers] ManualEntryView appeared")
                }
                .onDisappear {
                    print("[HomeSheetModifiers] ManualEntryView disappeared")
                }
            }
            .onChange(of: manualEntryCoordinator.showManualEntryForm) { oldValue, newValue in
                print("[HomeSheetModifiers] showManualEntryForm changed from \(oldValue) to \(newValue)")
            }
            .sheet(isPresented: $viewModel.showPasswordEntryView) {
                if let pdfData = viewModel.currentPasswordProtectedPDFData {
                    PasswordProtectedPDFView(
                        pdfData: pdfData,
                        onUnlock: { unlockedData, password in
                            Task {
                                await viewModel.handleUnlockedPDF(data: unlockedData, originalPassword: password)
                            }
                        }
                    )
                }
            }
    }
}

extension View {
    func homeSheetModifiers(
        viewModel: HomeViewModel,
        showingDocumentPicker: Binding<Bool>,
        showingScanner: Binding<Bool>,
        onDocumentPicked: @escaping (URL) -> Void
    ) -> some View {
        self.modifier(HomeSheetModifiers(
            viewModel: viewModel,
            showingDocumentPicker: showingDocumentPicker,
            showingScanner: showingScanner,
            onDocumentPicked: onDocumentPicked
        ))
    }
} 