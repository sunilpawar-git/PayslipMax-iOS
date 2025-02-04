import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \PayslipItem.id) private var items: [PayslipItem]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel(pdfManager: nil)
    @State private var showingAddPayslipSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if let latestItem = items.first {
                            WelcomeHeader(item: latestItem)
                        }
                        
                        ChartsSection()
                    }
                }
                .background(Color(.systemGroupedBackground))
                
                AddPayslipButton(showingSheet: $showingAddPayslipSheet)
            }
            .sheet(isPresented: $showingAddPayslipSheet) {
                AddPayslipSheet(isPresented: $showingAddPayslipSheet, 
                              pdfManager: viewModel.pdfManager)
            }
            .sheet(isPresented: .init(
                get: { viewModel.pdfManager.isShowingPreview },
                set: { if !$0 { viewModel.pdfManager.hidePreview() } }
            )) {
                if let pdf = viewModel.pdfManager.selectedPDF {
                    PDFPreviewView(document: pdf) {
                        Task {
                            viewModel.startProcessing()
                            // Process PDF
                            viewModel.stopProcessing()
                            viewModel.pdfManager.hidePreview()
                        }
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.pdfManager.isShowingError },
                set: { if !$0 { viewModel.pdfManager.clearError() } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.pdfManager.clearError()
                }
            } message: {
                Text(viewModel.pdfManager.errorMessage ?? "Unknown error occurred")
            }
            .withProcessingOverlay(isProcessing: viewModel.isProcessing, progress: viewModel.processingProgress)
        }
    }
}

// MARK: - Subviews
private struct WelcomeHeader: View {
    let item: PayslipItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, \(item.name)")
                .font(.title)
                .bold()
            
            Text("PCDA (O) Account No: \(item.accountNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("PAN: \(item.panNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top)
    }
}

private struct AddPayslipButton: View {
    @Binding var showingSheet: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showingSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.blue)
                                .shadow(radius: 4)
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
} 