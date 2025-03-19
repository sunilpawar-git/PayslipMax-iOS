import SwiftUI
import UIKit
import PDFKit

// Define notification names
extension Notification.Name {
    static let payslipUpdated = Notification.Name("PayslipUpdated")
    static let payslipDeleted = Notification.Name("PayslipDeleted")
}

struct PayslipDetailView<T: PayslipViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @State private var isEditing = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Month and Year header
                HStack {
                    Text("\(viewModel.payslipData.month) \(viewModel.payslipData.year)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    HStack {
                        if isEditing {
                            Button("Done") {
                                isEditing = false
                            }
                            .foregroundColor(.blue)
                        } else {
                            Button("Edit") {
                                isEditing = true
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.bottom, 4)
                
                // Personal Details Section
                detailSection(title: "PERSONAL DETAILS") {
                    DetailRowView(label: "Name", value: viewModel.payslipData.name, isEditing: isEditing)
                    DetailRowView(label: "Account", value: viewModel.payslipData.accountNumber, isEditing: isEditing)
                    DetailRowView(label: "PAN", value: viewModel.payslipData.panNumber, isEditing: isEditing)
                }
                
                // Financial Details Section
                detailSection(title: "FINANCIAL DETAILS") {
                    DetailRowView(label: "Credits", value: viewModel.formatCurrency(viewModel.payslipData.totalCredits), isEditing: isEditing)
                    DetailRowView(label: "Debits", value: viewModel.formatCurrency(viewModel.payslipData.totalDebits), isEditing: isEditing)
                    DetailRowView(label: "DSOP", value: viewModel.formatCurrency(viewModel.payslipData.dsop), isEditing: isEditing)
                    DetailRowView(label: "Income Tax", value: viewModel.formatCurrency(viewModel.payslipData.incomeTax), isEditing: isEditing)
                }
                
                // Net Remittance Section
                NetRemittanceView(amount: viewModel.payslipData.netRemittance)
                    .padding(.vertical, 8)
                
                // Earnings Breakdown Section
                if !viewModel.payslipData.allEarnings.isEmpty {
                    detailSection(title: "EARNINGS BREAKDOWN") {
                        if viewModel.payslipData.basicPay > 0 {
                            DetailRowView(label: "Basic Pay", value: viewModel.formatCurrency(viewModel.payslipData.basicPay), isEditing: isEditing)
                        }
                        
                        if viewModel.payslipData.dearnessPay > 0 {
                            DetailRowView(label: "Dearness Allowance", value: viewModel.formatCurrency(viewModel.payslipData.dearnessPay), isEditing: isEditing)
                        }
                        
                        if viewModel.payslipData.militaryServicePay > 0 {
                            DetailRowView(label: "Military Service Pay", value: viewModel.formatCurrency(viewModel.payslipData.militaryServicePay), isEditing: isEditing)
                        }
                        
                        if viewModel.payslipData.miscCredits > 0 {
                            DetailRowView(label: "Other Allowances", value: viewModel.formatCurrency(viewModel.payslipData.miscCredits), isEditing: isEditing)
                        }
                        
                        DetailRowView(label: "Gross Pay", value: viewModel.formatCurrency(viewModel.payslipData.totalCredits), isEditing: isEditing, isHighlighted: true)
                    }
                }
                
                // Deductions Breakdown Section
                if !viewModel.payslipData.allDeductions.isEmpty {
                    detailSection(title: "DEDUCTIONS BREAKDOWN") {
                        if viewModel.payslipData.dsop > 0 {
                            DetailRowView(label: "DSOP", value: viewModel.formatCurrency(viewModel.payslipData.dsop), isEditing: isEditing)
                        }
                        
                        if viewModel.payslipData.agif > 0 {
                            DetailRowView(label: "AGIF", value: viewModel.formatCurrency(viewModel.payslipData.agif), isEditing: isEditing)
                        }
                        
                        if viewModel.payslipData.incomeTax > 0 {
                            DetailRowView(label: "Income Tax", value: viewModel.formatCurrency(viewModel.payslipData.incomeTax), isEditing: isEditing)
                        }
                        
                        if viewModel.payslipData.miscDebits > 0 {
                            DetailRowView(label: "Other Deductions", value: viewModel.formatCurrency(viewModel.payslipData.miscDebits), isEditing: isEditing)
                        }
                        
                        DetailRowView(label: "Total Deductions", value: viewModel.formatCurrency(viewModel.payslipData.totalDebits), isEditing: isEditing, isHighlighted: true)
                    }
                }
                
                // DSOP Details Section
                if viewModel.payslipData.dsop > 0 {
                    detailSection(title: "DSOP DETAILS") {
                        if let openingBalance = viewModel.payslipData.dsopOpeningBalance {
                            DetailRowView(label: "Opening Balance", value: viewModel.formatCurrency(openingBalance), isEditing: isEditing)
                        }
                        
                        DetailRowView(label: "DSOP", value: viewModel.formatCurrency(viewModel.payslipData.dsop), isEditing: isEditing)
                        
                        if let closingBalance = viewModel.payslipData.dsopClosingBalance {
                            DetailRowView(label: "Closing Balance", value: viewModel.formatCurrency(closingBalance), isEditing: isEditing)
                        }
                    }
                }
                
                // Income Tax Details Section
                if viewModel.payslipData.incomeTax > 0 {
                    detailSection(title: "INCOME TAX DETAILS") {
                        DetailRowView(label: "Income Tax", value: viewModel.formatCurrency(viewModel.payslipData.incomeTax), isEditing: isEditing)
                    }
                }
                
                // Contact Details Section
                if !viewModel.payslipData.contactDetails.isEmpty {
                    detailSection(title: "CONTACT DETAILS") {
                        ForEach(Array(viewModel.payslipData.contactDetails.keys.sorted()), id: \.self) { key in
                            if let value = viewModel.payslipData.contactDetails[key] {
                                DetailRowView(
                                    label: key.capitalized,
                                    value: value,
                                    isEditing: isEditing,
                                    isContactDetail: true
                                )
                            }
                        }
                    }
                }
                
                // Debug Section
                if viewModel.showDiagnostics {
                    detailSection(title: "DIAGNOSTICS") {
                        Button("View Extraction Patterns") {
                            // Show extraction patterns
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                
                // Original PDF Section
                detailSection(title: "ORIGINAL DOCUMENT") {
                    Button(action: {
                        viewModel.showOriginalPDF = true
                    }) {
                        HStack {
                            Image(systemName: "doc.viewfinder")
                                .foregroundColor(.blue)
                            Text("View Original PDF")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationBarTitle("Payslip Details", displayMode: .inline)
        .navigationBarItems(
            trailing: HStack {
                Button(action: {
                    // Share both text and PDF
                    sharePayslipWithPDF()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        )
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let items = viewModel.getShareItems() {
                ShareSheet(items: items)
            } else {
                ShareSheet(items: [viewModel.getShareText()])
            }
        }
        .sheet(isPresented: $viewModel.showOriginalPDF) {
            if let payslipItem = viewModel.payslip as? PayslipItem {
                if let pdfUrl = PDFManager.shared.getPDFURL(for: payslipItem.id.uuidString),
                   FileManager.default.fileExists(atPath: pdfUrl.path),
                   let pdfData = try? Data(contentsOf: pdfUrl),
                   !pdfData.isEmpty {
                    PDFViewerScreen(pdfURL: pdfUrl, pdfData: pdfData, onDismiss: {
                        viewModel.showOriginalPDF = false
                    }, onShare: {
                        // Trigger share sheet for the PDF
                        viewModel.showShareSheet = true
                    })
                } else {
                    // Fallback in case no PDF is available
                    Text("PDF not available")
                        .padding()
                        .onAppear {
                            // Close the sheet after a brief delay since no PDF is available
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                viewModel.showOriginalPDF = false
                            }
                        }
                }
            } else {
                PDFNotAvailableView {
                    viewModel.showOriginalPDF = false
                }
                .onAppear {
                    print("PayslipDetailView: PayslipItem is not the correct type")
                }
            }
        }
        .padding(.horizontal)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle(Text("Payslip Details"))
        .onAppear {
            // Pre-fetch PDF data when the view appears
            preFetchPDF()
        }
    }
    
    // Share both text and PDF if available
    private func sharePayslipWithPDF() {
        // Just trigger the share sheet - getShareItems will handle the rest
        viewModel.showShareSheet = true
    }
    
    // Export PDF only
    private func exportPDF() {
        print("PayslipDetailView: Starting PDF export process")
        
        Task {
            do {
                if let url = try await viewModel.getPDFURL() {
                    print("PayslipDetailView: Got PDF URL for export: \(url.path)")
                    
                    // Share the PDF file
                    DispatchQueue.main.async {
                        let fileName = "\(viewModel.payslipData.month)_\(viewModel.payslipData.year)_Payslip.pdf"
                        
                        // Create activity view controller for sharing
                        let activityVC = UIActivityViewController(
                            activityItems: [url],
                            applicationActivities: nil
                        )
                        
                        // Set the filename that will be shown in the share sheet
                        activityVC.setValue(fileName, forKey: "subject")
                        
                        // Present the share sheet
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let controller = windowScene.windows.first?.rootViewController {
                            controller.present(activityVC, animated: true)
                        } else {
                            // Fallback to standard ShareSheet
                            ShareSheet.share(items: [url])
                        }
                    }
                } else {
                    print("PayslipDetailView: Failed to get PDF URL for export")
                }
            } catch {
                print("PayslipDetailView: Error exporting PDF: \(error)")
                ErrorLogger.log(error)
            }
        }
    }
    
    @ViewBuilder
    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
}

struct DetailRowView: View {
    let label: String
    let value: String
    let isEditing: Bool
    var isHighlighted: Bool = false
    var isContactDetail: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(isHighlighted ? .semibold : .regular)
            
            Spacer()
            
            if isContactDetail, let url = contactURL(for: label, value: value) {
                Link(value, destination: url)
                    .foregroundColor(.blue)
            } else {
                Text(value)
                    .fontWeight(isHighlighted ? .semibold : .regular)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHighlighted ? Color(.systemGray5) : Color.clear)
        .contentShape(Rectangle())
    }
    
    private func contactURL(for label: String, value: String) -> URL? {
        let lowerLabel = label.lowercased()
        
        // Email
        if lowerLabel.contains("email") || lowerLabel.contains("mail") {
            return URL(string: "mailto:\(value)")
        }
        
        // Phone
        if lowerLabel.contains("phone") || lowerLabel.contains("tel") {
            let cleaned = value.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            return URL(string: "tel:\(cleaned)")
        }
        
        // Website
        if lowerLabel.contains("website") || lowerLabel.contains("web") || lowerLabel.contains("site") {
            var urlString = value
            if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                urlString = "https://" + urlString
            }
            return URL(string: urlString)
        }
        
        return nil
    }
}

// Additional view to display the net remittance amount
struct NetRemittanceView: View {
    let amount: Double
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("NET REMITTANCE")
                .font(.subheadline)
                .fontWeight(.semibold)
                .opacity(0.7)
            
            Text(formatCurrency(amount))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if let formattedValue = formatter.string(from: NSNumber(value: value)) {
            return "₹" + formattedValue
        }
        
        return "₹" + String(format: "%.0f", value)
    }
}

// Original PDF Viewer Screen - replacing with a more robust version
struct PDFViewerScreen: View {
    let pdfURL: URL?
    let pdfData: Data?
    let onDismiss: () -> Void
    var onShare: (() -> Void)? = nil
    @State private var hasError = false
    
    var body: some View {
        NavigationView {
            VStack {
                if hasError {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Could not load PDF")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Text("The PDF may be corrupted or in an unsupported format.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    SafePDFView(pdfURL: pdfURL, pdfData: pdfData, hasError: $hasError)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("PDF Viewer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                }
                
                if let onShare = onShare {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
}

// New SafePDFView to handle PDF document creation safely
struct SafePDFView: UIViewRepresentable {
    let pdfURL: URL?
    let pdfData: Data?
    @Binding var hasError: Bool
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Load the PDF document
        if let document = createSafePDFDocument() {
            pdfView.document = document
            hasError = false
        } else {
            hasError = true
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Only update if the document changed
        if let document = createSafePDFDocument(), uiView.document == nil {
            uiView.document = document
            hasError = false
        }
    }
    
    private func createSafePDFDocument() -> PDFDocument? {
        // Try to create a PDF document from the provided data or URL
        if let pdfData = pdfData, !pdfData.isEmpty {
            print("SafePDFView: Creating PDF document from data (\(pdfData.count) bytes)")
            return PDFDocument(data: pdfData)
        } else if let pdfURL = pdfURL {
            print("SafePDFView: Creating PDF document from URL: \(pdfURL.path)")
            return PDFDocument(url: pdfURL)
        }
        
        print("SafePDFView: No valid PDF data or URL provided")
        return nil
    }
}

// Error view when PDF is not available
struct PDFNotAvailableView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .padding()
            
            Text("PDF Not Available")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("The original PDF file could not be found or may not have been saved with this payslip.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Dismiss", action: onDismiss)
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
                .padding(.top, 20)
        }
        .padding()
    }
}

// Call this method in the PayslipDetailView to preload PDFs when the view appears
extension PayslipDetailView {
    /// Pre-fetch and verify PDF data for better viewing experience
    func preFetchPDF() {
        if let payslipItem = viewModel.payslip as? PayslipItem {
            Task {
                print("PreFetch: Starting PDF prefetch for payslip \(payslipItem.id)")
                
                // Check if PDF data is already available in the PayslipItem
                if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
                    print("PreFetch: PayslipItem has PDF data of size \(pdfData.count) bytes")
                    
                    // Verify the PDF data is valid and repair if needed
                    if !PDFManager.shared.verifyPDF(data: pdfData) {
                        print("PreFetch: PDF data is invalid, repairing")
                        let repairedData = PDFManager.shared.verifyAndRepairPDF(data: pdfData)
                        
                        // Update PayslipItem with repaired data
                        payslipItem.pdfData = repairedData
                        
                        // Also save to PDFManager
                        do {
                            let url = try PDFManager.shared.savePDF(data: repairedData, identifier: payslipItem.id.uuidString)
                            print("PreFetch: Saved repaired PDF to \(url.path)")
                        } catch {
                            print("PreFetch: Failed to save repaired PDF: \(error)")
                        }
                        
                        // Save the updated PayslipItem
                        let dataService = DIContainer.shared.dataService
                        try? await dataService.save(payslipItem)
                        print("PreFetch: Updated PayslipItem with repaired PDF data")
                    } else {
                        print("PreFetch: PDF data is valid")
                        
                        // Ensure the PDF is saved to the PDFManager as well
                        if !PDFManager.shared.pdfExists(for: payslipItem.id.uuidString) {
                            do {
                                let url = try PDFManager.shared.savePDF(data: pdfData, identifier: payslipItem.id.uuidString)
                                print("PreFetch: Saved valid PDF to \(url.path)")
                            } catch {
                                print("PreFetch: Failed to save valid PDF: \(error)")
                            }
                        }
                    }
                    return
                }
                
                // If no PDF data in PayslipItem, check PDFManager
                print("PreFetch: No PDF data in PayslipItem, checking PDFManager")
                if let storedPDFData = PDFManager.shared.getPDFData(for: payslipItem.id.uuidString),
                   !storedPDFData.isEmpty {
                    print("PreFetch: Found PDF in PDFManager, size: \(storedPDFData.count) bytes")
                    
                    // Verify and repair the stored PDF data if needed
                    let validData = PDFManager.shared.verifyAndRepairPDF(data: storedPDFData)
                    
                    // Update PayslipItem with the valid data
                    payslipItem.pdfData = validData
                    
                    // Save the updated PayslipItem
                    let dataService = DIContainer.shared.dataService
                    try? await dataService.save(payslipItem)
                    print("PreFetch: Updated PayslipItem with PDF data from PDFManager")
                    return
                }
                
                // If no PDF data is available anywhere, create a placeholder
                print("PreFetch: No PDF data found, requesting PDF URL creation")
                
                // This will create a placeholder PDF if necessary
                if let _ = try? await viewModel.getPDFURL() {
                    print("PreFetch: Successfully created PDF URL")
                    
                    // Refresh the PDF data in the PayslipItem
                    if let newData = PDFManager.shared.getPDFData(for: payslipItem.id.uuidString) {
                        payslipItem.pdfData = newData
                        
                        // Save the updated PayslipItem
                        let dataService = DIContainer.shared.dataService
                        try? await dataService.save(payslipItem)
                        print("PreFetch: Updated PayslipItem with newly created PDF data")
                    }
                }
            }
        }
    }
} 