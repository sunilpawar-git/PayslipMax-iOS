import SwiftUI

struct AddPayslipSheet: View {
    @Binding var isPresented: Bool
    let pdfManager: PDFUploadManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                SelectPDFButton(pdfManager: pdfManager)
                ScanDocumentButton()
                Spacer()
            }
            .padding()
            .navigationTitle("Add Payslip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Subviews
private struct SelectPDFButton: View {
    let pdfManager: PDFUploadManager
    
    var body: some View {
        Button {
            pdfManager.showPicker()
        } label: {
            HStack {
                Image(systemName: "doc.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Select PDF")
                        .font(.headline)
                    Text("Choose from Files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
}

private struct ScanDocumentButton: View {
    var body: some View {
        Button(action: {
            // Implement camera scanning
        }) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("Scan Document")
                        .font(.headline)
                    Text("Use Camera")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
} 