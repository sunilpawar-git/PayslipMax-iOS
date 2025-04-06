import SwiftUI
import PDFKit

// PDFViewerScreen - Enhanced to reliably display and share PDFs
struct PDFViewerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PayslipDetailViewModel
    @State private var hasError = false
    @State private var isLoading = true
    @State private var pdfData: Data? = nil
    @State private var pdfURL: URL? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading PDF...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if hasError {
                    // Simple error view instead of a custom PDFErrorView
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Could not load PDF")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("The PDF file could not be loaded. It may be corrupted or in an unsupported format.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    if let data = pdfData {
                        EnhancedPDFView(pdfData: data, hasError: $hasError)
                    } else {
                        Text("No PDF data available")
                    }
                }
            }
            .navigationTitle("Original PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !hasError, pdfData != nil || pdfURL != nil {
                        Button(action: {
                            // Use the viewModel's built-in sharing functionality
                            viewModel.showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .task {
                await loadPDF()
            }
        }
    }
    
    private func loadPDF() async {
        isLoading = true
        hasError = false
        
        do {
            // Try to get the PDF URL
            if let url = try await viewModel.getPDFURL() {
                // Load the PDF data from the URL
                do {
                    let data = try Data(contentsOf: url)
                    if isPDFValid(data: data) {
                        pdfData = data
                    } else {
                        hasError = true
                    }
                } catch {
                    print("PDFViewer: Error reading PDF data from URL: \(error)")
                    hasError = true
                }
            } else if let item = viewModel.payslip as? PayslipItem, let data = item.pdfData {
                // Use PDF data directly if available
                if isPDFValid(data: data) {
                    pdfData = data
                } else {
                    hasError = true
                }
            } else {
                hasError = true
            }
        } catch {
            print("PDFViewer: Error loading PDF: \(error)")
            hasError = true
        }
        
        isLoading = false
    }
    
    private func isPDFValid(data: Data) -> Bool {
        return PDFDocument(data: data) != nil
    }
} 