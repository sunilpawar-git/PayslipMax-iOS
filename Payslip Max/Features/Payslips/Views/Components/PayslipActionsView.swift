import SwiftUI
import UniformTypeIdentifiers
import UIKit

// UIViewControllerRepresentable for UIActivityViewController
struct SystemShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

struct PayslipActionsView: View {
    let payslipID: String
    let payslipTitle: String
    let pdfData: Data?
    
    @State private var isShowingShareSheet = false
    @State private var isShowingPDFViewer = false
    @State private var shareItems: [Any] = []
    @State private var exportedFileURL: URL?
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                sharePayslipWithPDF()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Payslip")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(pdfData == nil)
            
            Button(action: {
                exportPDF()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Export PDF")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(pdfData == nil)
            
            Button(action: {
                isShowingPDFViewer = true
            }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("View Full PDF")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
            .disabled(pdfData == nil)
        }
        .padding(.horizontal)
        .sheet(isPresented: $isShowingShareSheet) {
            Group {
                if !shareItems.isEmpty {
                    SystemShareSheet(items: shareItems)
                } else {
                    Text("No items to share")
                }
            }
        }
        .sheet(isPresented: $isShowingPDFViewer) {
            Group {
                if let pdfData = pdfData {
                    createPDFViewer(with: pdfData)
                } else {
                    Text("No PDF to display")
                }
            }
        }
    }
    
    private func createPDFViewer(with pdfData: Data) -> some View {
        // Create a temporary PayslipItem to use with PayslipDetailViewModel
        let tempPayslip = PayslipItem(
            id: UUID(uuidString: payslipID) ?? UUID(),
            month: "",
            year: 0,
            credits: 0,
            debits: 0,
            dsop: 0,
            tax: 0,
            name: payslipTitle,
            accountNumber: "",
            panNumber: "",
            pdfData: pdfData
        )
        tempPayslip.earnings = [:]
        tempPayslip.deductions = [:]
        
        let viewModel = PayslipDetailViewModel(payslip: tempPayslip)
        return PDFViewerScreen(viewModel: viewModel)
    }
    
    private func sharePayslipWithPDF() {
        guard let pdfData = pdfData else { return }
        
        // Create a temporary file URL for the PDF
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(payslipTitle.replacingOccurrences(of: " ", with: "_")).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            shareItems = [fileURL]
            isShowingShareSheet = true
        } catch {
            print("Error writing PDF to temporary file: \(error)")
        }
    }
    
    private func exportPDF() {
        guard let pdfData = pdfData else { return }
        
        // Create a temporary file URL for the PDF
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(payslipTitle.replacingOccurrences(of: " ", with: "_")).pdf"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            exportedFileURL = fileURL
            shareItems = [fileURL]
            isShowingShareSheet = true
        } catch {
            print("Error writing PDF to temporary file: \(error)")
        }
    }
}