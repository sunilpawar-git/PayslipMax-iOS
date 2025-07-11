import SwiftUI

/// Extracts sheet modifiers from HomeView to improve code organization
struct HomeSheetModifiers: ViewModifier {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var showingDocumentPicker: Bool
    @Binding var showingScanner: Bool
    let onDocumentPicked: (URL) -> Void
    
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
            .sheet(isPresented: Binding(
                get: { 
                    let isPresented = viewModel.showManualEntryForm
                    print("[HomeSheetModifiers] Manual entry sheet isPresented: \(isPresented)")
                    return isPresented
                },
                set: { newValue in 
                    print("[HomeSheetModifiers] Manual entry sheet set to: \(newValue)")
                    if !newValue {
                        viewModel.showManualEntryForm = false
                    }
                }
            )) {
                ManualEntryView(onSave: { payslipData in
                    print("[HomeSheetModifiers] Manual entry saved")
                    viewModel.processManualEntry(payslipData)
                })
                .onAppear {
                    print("[HomeSheetModifiers] ManualEntryView appeared")
                }
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