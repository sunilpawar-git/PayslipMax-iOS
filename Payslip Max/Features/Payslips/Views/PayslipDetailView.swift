import SwiftUI
import UIKit
import PDFKit
import Foundation // For AppNotification

// Define notification names
// extension Notification.Name {
//     static let payslipUpdated = Notification.Name("PayslipUpdated")
//     static let payslipDeleted = Notification.Name("PayslipDeleted")
// }

struct PayslipDetailView<T: PayslipViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @State private var isEditing = false
    @State private var hasError = false
    @State private var isPDFLoaded = false
    
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("ORIGINAL DOCUMENT")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                    
                    Button(action: {
                        // Pre-fetch the PDF URL to improve loading experience
                        Task {
                            do {
                                _ = try await viewModel.getPDFURL()
                            } catch {
                                print("Failed to pre-fetch PDF: \(error)")
                            }
                        }
                        viewModel.showOriginalPDF = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            
                            Text("View Original PDF")
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
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
        .fullScreenCover(isPresented: $viewModel.showOriginalPDF) {
            PDFViewerScreen(viewModel: viewModel as! PayslipDetailViewModel)
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
            if let payslipItem = viewModel.payslip as? PayslipItem {
                // First check if we have PDF data directly in the PayslipItem
                if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
                    await shareRawPDFData(pdfData)
                    return
                }
                
                // Next, try to get the PDF from the PDFManager
                if let pdfUrl = PDFManager.shared.getPDFURL(for: payslipItem.id.uuidString),
                   let pdfData = try? Data(contentsOf: pdfUrl),
                   !pdfData.isEmpty {
                    await shareRawPDFData(pdfData)
                    return
                }
                
                // If we still don't have PDF data, try to generate it
                do {
                    if let url = try await viewModel.getPDFURL() {
                        print("PayslipDetailView: Got PDF URL for export: \(url.path)")
                        
                        // Share the PDF file
                        DispatchQueue.main.async {
                            let items = viewModel.getShareItems() ?? [viewModel.getShareText()]
                            ShareSheet.share(items: items)
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
    }
    
    // Helper to share raw PDF data
    private func shareRawPDFData(_ data: Data) async {
        print("PayslipDetailView: Sharing raw PDF data of size \(data.count)")
        
        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(viewModel.payslipData.month)_\(viewModel.payslipData.year)_Payslip.pdf"
        let tempURL = tempDir.appendingPathComponent(fileName)
        
        do {
            // Write the data to the temp file
            try data.write(to: tempURL)
            
            // Share on the main thread
            await MainActor.run {
                // Create activity view controller for sharing
                let activityVC = UIActivityViewController(
                    activityItems: [tempURL],
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
                    ShareSheet.share(items: [tempURL])
                }
            }
        } catch {
            print("PayslipDetailView: Error writing PDF to temp file: \(error)")
            
            // Fallback to using the share items if direct sharing fails
            await MainActor.run {
                let items = viewModel.getShareItems() ?? [viewModel.getShareText()]
                ShareSheet.share(items: items)
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
    
    // Helper to fetch PDF before showing
    private func preFetchPDF() {
        Task {
            do {
                _ = try await viewModel.getPDFURL()
            } catch {
                print("Failed to pre-fetch PDF: \(error)")
            }
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
                    PDFErrorView()
                } else {
                    PDFViewContainer(pdfData: pdfData, pdfURL: pdfURL, hasError: $hasError)
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
                pdfURL = url
                
                // Verify this is actually a valid PDF file
                do {
                    let data = try Data(contentsOf: url)
                    if !isPDFValid(data: data) {
                        print("PDFViewer: URL points to invalid PDF, trying to get data directly")
                        // Try to get PDF data directly from PayslipItem
                        if let item = viewModel.payslip as? PayslipItem, 
                           let data = item.pdfData, 
                           !data.isEmpty,
                           isPDFValid(data: data) {
                            pdfData = data
                            pdfURL = nil
                        } else {
                            // If neither URL nor data are valid, create a placeholder
                            pdfData = createFormattedPlaceholderPDF()
                            pdfURL = nil
                        }
                    }
                } catch {
                    print("PDFViewer: Error reading PDF from URL: \(error)")
                    // Try to get PDF data directly from PayslipItem
                    if let item = viewModel.payslip as? PayslipItem, 
                       let data = item.pdfData, 
                       !data.isEmpty {
                        pdfData = data
                        pdfURL = nil
                    } else {
                        pdfData = createFormattedPlaceholderPDF()
                        pdfURL = nil
                    }
                }
            } else {
                print("PDFViewer: Could not get PDF URL")
                // Try to get PDF data directly from PayslipItem
                if let item = viewModel.payslip as? PayslipItem, 
                   let data = item.pdfData, 
                   !data.isEmpty {
                    pdfData = data
                } else {
                    pdfData = createFormattedPlaceholderPDF()
                }
            }
        } catch {
            print("PDFViewer: Error getting PDF URL: \(error)")
            // Create a basic formatted placeholder PDF
            pdfData = createFormattedPlaceholderPDF()
        }
        
        isLoading = false
    }
    
    private func isPDFValid(data: Data) -> Bool {
        // Quick check for PDF header
        let pdfHeaderCheck = data.prefix(5).map { UInt8($0) }
        let validHeader: [UInt8] = [37, 80, 68, 70, 45] // %PDF-
        
        if pdfHeaderCheck != validHeader {
            return false
        }
        
        // Try creating a PDFDocument
        if let document = PDFDocument(data: data), document.pageCount > 0 {
            return true
        }
        
        return false
    }
    
    private func createFormattedPlaceholderPDF() -> Data {
        let payslipItem = viewModel.payslip
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let headerFont = UIFont.boldSystemFont(ofSize: 18)
            let textFont = UIFont.systemFont(ofSize: 16)
            let smallFont = UIFont.systemFont(ofSize: 12)
            
            // Header with styling
            let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 80)
            context.cgContext.setFillColor(UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0).cgColor)
            context.cgContext.fill(headerRect)
            
            // Title
            let titleRect = CGRect(x: 50, y: 25, width: pageRect.width - 100, height: 40)
            "Payslip Details".draw(in: titleRect, withAttributes: [
                NSAttributedString.Key.font: titleFont,
                NSAttributedString.Key.foregroundColor: UIColor.white
            ])
            
            // Month and Year
            let dateRect = CGRect(x: 50, y: 100, width: pageRect.width - 100, height: 30)
            "\(payslipItem.month) \(payslipItem.year)".draw(in: dateRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Payslip data
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "₹"
            formatter.minimumFractionDigits = 2
            
            var yPos: CGFloat = 150
            
            // Name if available
            let name = viewModel.payslipData.name.isEmpty ? payslipItem.name : viewModel.payslipData.name
            if !name.isEmpty {
                let nameRect = CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: 30)
                "Employee: \(name)".draw(in: nameRect, withAttributes: [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: UIColor.darkText
                ])
                yPos += 40
            }
            
            // Credits/Debits section
            let creditsStr = formatter.string(from: NSNumber(value: payslipItem.credits)) ?? "\(payslipItem.credits)"
            let debitsStr = formatter.string(from: NSNumber(value: payslipItem.debits)) ?? "\(payslipItem.debits)"
            let netStr = formatter.string(from: NSNumber(value: payslipItem.credits - payslipItem.debits)) ?? "\(payslipItem.credits - payslipItem.debits)"
            
            // Financial section header
            let financialRect = CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: 30)
            "Financial Summary".draw(in: financialRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            yPos += 40
            
            // Two-column layout for financial data
            let col1X: CGFloat = 50
            let col2X: CGFloat = pageRect.width / 2 + 20
            
            // Credits
            let creditsLabelRect = CGRect(x: col1X, y: yPos, width: 200, height: 25)
            "Gross Pay:".draw(in: creditsLabelRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            let creditsValueRect = CGRect(x: col1X + 120, y: yPos, width: 150, height: 25)
            creditsStr.draw(in: creditsValueRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            // Debits
            let debitsLabelRect = CGRect(x: col2X, y: yPos, width: 200, height: 25)
            "Deductions:".draw(in: debitsLabelRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            let debitsValueRect = CGRect(x: col2X + 120, y: yPos, width: 150, height: 25)
            debitsStr.draw(in: debitsValueRect, withAttributes: [
                NSAttributedString.Key.font: textFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            yPos += 40
            
            // DSOP if available
            if payslipItem.dsop > 0 {
                let dsopStr = formatter.string(from: NSNumber(value: payslipItem.dsop)) ?? "\(payslipItem.dsop)"
                
                let dsopLabelRect = CGRect(x: col1X, y: yPos, width: 200, height: 25)
                "DSOP:".draw(in: dsopLabelRect, withAttributes: [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: UIColor.darkText
                ])
                
                let dsopValueRect = CGRect(x: col1X + 120, y: yPos, width: 150, height: 25)
                dsopStr.draw(in: dsopValueRect, withAttributes: [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: UIColor.darkText
                ])
                
                // Tax if available
                if payslipItem.tax > 0 {
                    let taxStr = formatter.string(from: NSNumber(value: payslipItem.tax)) ?? "\(payslipItem.tax)"
                    
                    let taxLabelRect = CGRect(x: col2X, y: yPos, width: 200, height: 25)
                    "Income Tax:".draw(in: taxLabelRect, withAttributes: [
                        NSAttributedString.Key.font: textFont,
                        NSAttributedString.Key.foregroundColor: UIColor.darkText
                    ])
                    
                    let taxValueRect = CGRect(x: col2X + 120, y: yPos, width: 150, height: 25)
                    taxStr.draw(in: taxValueRect, withAttributes: [
                        NSAttributedString.Key.font: textFont,
                        NSAttributedString.Key.foregroundColor: UIColor.darkText
                    ])
                }
                
                yPos += 40
            }
            
            // Net Pay with highlight
            context.cgContext.setFillColor(UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0).cgColor)
            context.cgContext.fill(CGRect(x: 50, y: yPos - 10, width: pageRect.width - 100, height: 40))
            
            let netLabelRect = CGRect(x: 70, y: yPos, width: 200, height: 25)
            "Net Pay:".draw(in: netLabelRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            let netValueRect = CGRect(x: pageRect.width - 220, y: yPos, width: 150, height: 25)
            netStr.draw(in: netValueRect, withAttributes: [
                NSAttributedString.Key.font: headerFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkText
            ])
            
            yPos += 60
            
            // Add message about original document
            let messageRect = CGRect(x: 50, y: yPos, width: pageRect.width - 100, height: 80)
            let message = """
            The original PDF document cannot be displayed directly. This is a formatted representation of the data extracted from your payslip.
            
            Military and government PDFs often use security features that prevent standard viewing. The payslip data is still accessible in the app interface.
            """
            message.draw(in: messageRect, withAttributes: [
                NSAttributedString.Key.font: smallFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ])
            
            // Footer
            let footerRect = CGRect(x: 50, y: pageRect.height - 50, width: pageRect.width - 100, height: 30)
            "Generated by Payslip Max App".draw(in: footerRect, withAttributes: [
                NSAttributedString.Key.font: smallFont,
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ])
        }
    }
}

struct PDFViewContainer: View {
    var pdfData: Data?
    var pdfURL: URL?
    @Binding var hasError: Bool
    
    var body: some View {
        if let pdfData = pdfData {
            // If we have direct PDF data, use it
            EnhancedPDFViewer(pdfData: pdfData, hasError: $hasError)
        } else if let pdfURL = pdfURL {
            // If we have a URL, use that instead
            EnhancedPDFViewer(pdfURL: pdfURL, hasError: $hasError)
        } else {
            // If we have neither, show an error
            PDFErrorView()
        }
    }
}

struct EnhancedPDFViewer: View {
    var pdfData: Data?
    var pdfURL: URL?
    @Binding var hasError: Bool
    
    var body: some View {
        SafePDFView(pdfURL: pdfURL, pdfData: pdfData, hasError: $hasError)
            .edgesIgnoringSafeArea([.horizontal, .bottom])
    }
}

struct PDFErrorView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Cannot display PDF")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("The original PDF document could not be displayed. Military and government PDFs often use security features that prevent standard viewing. Your payslip data is still accessible in the app interface.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

// SafePDFView - Enhanced for better error handling and rendering
struct SafePDFView: UIViewRepresentable {
    let pdfURL: URL?
    let pdfData: Data?
    @Binding var hasError: Bool
    
    // Add support for retry
    @State private var retryCount = 0
    private let maxRetryCount = 2
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .secondarySystemBackground
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // Create the PDF document
        loadDocument(into: pdfView)
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Only update if the document is not set or has changed
        if pdfView.document == nil {
            loadDocument(into: pdfView)
        }
    }
    
    private func loadDocument(into pdfView: PDFView) {
        // First try direct loading methods with better debug output
        print("SafePDFView: Attempting to load PDF document (attempt \(retryCount + 1))")
        
        // Try to load from direct data first
        if let pdfData = pdfData, !pdfData.isEmpty {
            print("SafePDFView: Loading from data (\(pdfData.count) bytes)")
            
            // Military PDFs often have specific signatures - check for common indicators
            let isPotentiallyMilitaryPDF = checkForMilitaryPDFSignature(data: pdfData)
            if isPotentiallyMilitaryPDF {
                print("SafePDFView: Detected potential military PDF format signature")
            }
            
            // Try PDFKit first
            if let document = createSafePDFDocument(from: pdfData) {
                if document.pageCount > 0 {
                    print("SafePDFView: Successfully created document from data with \(document.pageCount) pages")
                    pdfView.document = document
                    configureViewSettings(pdfView)
                    hasError = false
                    return
                } else {
                    print("SafePDFView: Document created but has 0 pages, will try repair")
                }
            } else {
                print("SafePDFView: Failed to create PDFDocument from data, will try lower-level methods")
            }
            
            // If PDFKit fails, try CoreGraphics as fallback
            if let cgPDF = createCGPDFDocument(from: pdfData) {
                print("SafePDFView: Created CGPDFDocument with \(cgPDF.numberOfPages) pages, rendering to new PDF")
                
                // We have a valid CoreGraphics PDF, render it to a new PDF via UIGraphicsPDFRenderer
                let renderedData = renderPDFFromCGPDF(cgPDF)
                if let renderedDocument = PDFDocument(data: renderedData) {
                    print("SafePDFView: Successfully rendered document with \(renderedDocument.pageCount) pages")
                    pdfView.document = renderedDocument
                    configureViewSettings(pdfView)
                    hasError = false
                    return
                }
            }
            
            // Military PDF-specific approach - try to extract text and create new PDF
            if isPotentiallyMilitaryPDF {
                print("SafePDFView: Attempting military PDF specialized processing")
                if let militaryPDFData = processMilitaryPDF(pdfData) {
                    if let militaryDocument = PDFDocument(data: militaryPDFData) {
                        print("SafePDFView: Successfully processed military PDF format")
                        pdfView.document = militaryDocument
                        configureViewSettings(pdfView)
                        hasError = false
                        return
                    }
                }
            }
            
            // Last resort: try to repair or re-encode the data
            print("SafePDFView: Attempting to repair PDF data")
            let repairedData = PDFManager.shared.verifyAndRepairPDF(data: pdfData)
            if let repairedDocument = PDFDocument(data: repairedData), repairedDocument.pageCount > 0 {
                print("SafePDFView: Successfully repaired PDF with \(repairedDocument.pageCount) pages")
                pdfView.document = repairedDocument
                configureViewSettings(pdfView)
                hasError = false
                return
            }
        }
        
        // If data approach failed, try URL
        if let pdfURL = pdfURL {
            print("SafePDFView: Trying to load from URL: \(pdfURL.path)")
            
            // Try to create from URL directly first
            if let document = createSafePDFDocument(from: pdfURL) {
                if document.pageCount > 0 {
                    print("SafePDFView: Successfully loaded document from URL with \(document.pageCount) pages")
                    pdfView.document = document
                    configureViewSettings(pdfView)
                    hasError = false
                    return
                }
            }
            
            // If direct URL loading fails, try loading the data from URL
            do {
                let urlData = try Data(contentsOf: pdfURL)
                print("SafePDFView: Loaded \(urlData.count) bytes from URL")
                
                if !urlData.isEmpty {
                    // Check for military PDF format
                    let isPotentiallyMilitaryPDF = checkForMilitaryPDFSignature(data: urlData)
                    
                    if let document = createSafePDFDocument(from: urlData), document.pageCount > 0 {
                        print("SafePDFView: Created document from URL data with \(document.pageCount) pages")
                        pdfView.document = document
                        configureViewSettings(pdfView)
                        hasError = false
                        return
                    }
                    
                    // Military PDF-specific approach for URL data
                    if isPotentiallyMilitaryPDF {
                        print("SafePDFView: Attempting military PDF specialized processing for URL data")
                        if let militaryPDFData = processMilitaryPDF(urlData) {
                            if let militaryDocument = PDFDocument(data: militaryPDFData) {
                                print("SafePDFView: Successfully processed military PDF from URL")
                                pdfView.document = militaryDocument
                                configureViewSettings(pdfView)
                                hasError = false
                                return
                            }
                        }
                    }
                    
                    // Try repair as last resort
                    print("SafePDFView: Attempting to repair data from URL")
                    let repairedData = PDFManager.shared.verifyAndRepairPDF(data: urlData)
                    if let repairedDocument = PDFDocument(data: repairedData), repairedDocument.pageCount > 0 {
                        print("SafePDFView: Successfully repaired URL data, \(repairedDocument.pageCount) pages")
                        pdfView.document = repairedDocument
                        configureViewSettings(pdfView)
                        hasError = false
                        return
                    }
                }
            } catch {
                print("SafePDFView: Error loading data from URL: \(error)")
            }
        }
        
        // If all approaches failed but we haven't tried too many times, try one more time
        if retryCount < maxRetryCount {
            retryCount += 1
            // Add a small delay before retrying
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("SafePDFView: Retrying PDF load, attempt \(retryCount + 1)")
                loadDocument(into: pdfView)
            }
            return
        }
        
        // If all approaches failed, show error
        print("SafePDFView: All PDF loading methods failed")
        hasError = true
    }
    
    // Configure standard view settings
    private func configureViewSettings(_ pdfView: PDFView) {
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 4.0
        pdfView.autoScales = true
    }
    
    // Helper method to create PDFDocument safely with password attempts if needed
    private func createSafePDFDocument(from data: Data) -> PDFDocument? {
        // First try without password
        if let document = PDFDocument(data: data) {
            return document
        }
        
        // Unfortunately PDFDocument in iOS doesn't support password directly
        // We'll have to use other recovery methods
        
        return nil
    }
    
    // Helper method to create PDFDocument from URL safely
    private func createSafePDFDocument(from url: URL) -> PDFDocument? {
        // First try without password
        if let document = PDFDocument(url: url) {
            return document
        }
        
        // For URL-based PDFs, try loading the data and then using standard methods
        do {
            let data = try Data(contentsOf: url)
            return createSafePDFDocument(from: data)
        } catch {
            print("SafePDFView: Error loading URL data for recovery attempts: \(error)")
            return nil
        }
    }
    
    // Helper to create CGPDFDocument safely
    private func createCGPDFDocument(from data: Data) -> CGPDFDocument? {
        guard let provider = CGDataProvider(data: data as CFData),
              let cgPDF = CGPDFDocument(provider),
              cgPDF.numberOfPages > 0 else {
            return nil
        }
        
        // If the document is encrypted but has no password
        if cgPDF.isEncrypted && !cgPDF.isUnlocked {
            // Try with empty password
            if cgPDF.unlockWithPassword("") {
                return cgPDF
            }
            
            // Try common passwords
            for password in ["0000", "1234", "military", "payslip"] {
                if cgPDF.unlockWithPassword(password) {
                    print("SafePDFView: Unlocked CGPDFDocument with password")
                    return cgPDF
                }
            }
            
            return nil
        }
        
        return cgPDF
    }
    
    // Check for military PDF signatures
    private func checkForMilitaryPDFSignature(data: Data) -> Bool {
        // Look for specific byte patterns or strings common in military PDFs
        let dataString: String
        if let string = String(data: data.prefix(4000), encoding: .ascii) {
            dataString = string
        } else if let string = String(data: data.prefix(4000), encoding: .utf8) {
            dataString = string
        } else {
            return false
        }
        
        // Check for common military document identifiers
        let militaryKeywords = [
            "MILITARY PAY", "DFAS", "Defense Finance", "TSP",
            "LES", "Leave and Earnings", "MyPay", "Armed Forces"
        ]
        
        for keyword in militaryKeywords {
            if dataString.contains(keyword) {
                return true
            }
        }
        
        // Check for specific PDF security settings in header
        if dataString.contains("/Encrypt") && dataString.contains("/Filter") {
            return true
        }
        
        return false
    }
    
    // Special processing for military PDFs
    private func processMilitaryPDF(_ data: Data) -> Data? {
        // Try to extract text content from the PDF
        guard let provider = CGDataProvider(data: data as CFData),
              let cgPDF = CGPDFDocument(provider),
              cgPDF.numberOfPages > 0 else {
            return nil
        }
        
        // Extract text content using lower-level APIs
        var extractedText = ""
        
        for i in 1...cgPDF.numberOfPages {
            guard let page = cgPDF.page(at: i) else { continue }
            
            if let pageText = extractTextFromPDFPage(page) {
                extractedText += "Page \(i):\n\(pageText)\n\n"
            }
        }
        
        if !extractedText.isEmpty {
            // Create a new PDF with the extracted text
            return createPDFFromText(extractedText)
        }
        
        return nil
    }
    
    // Extract text from PDF page
    private func extractTextFromPDFPage(_ page: CGPDFPage) -> String? {
        // We can't directly create a PDFDocument from a single page
        // Instead, we'll render this page to a temporary context and create a data
        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let pageData = renderer.pdfData { context in
            context.beginPage()
            let ctx = context.cgContext
            
            // Setup for correct rendering
            ctx.translateBy(x: 0, y: pageRect.height)
            ctx.scaleBy(x: 1, y: -1)
            
            // Draw the page
            ctx.drawPDFPage(page)
        }
        
        // Now try to extract text from this rendered page
        if let pdfDoc = PDFDocument(data: pageData),
           let firstPage = pdfDoc.page(at: 0) {
            return firstPage.string
        }
        
        // CoreGraphics doesn't provide direct text extraction, return nil
        return nil
    }
    
    // Create PDF from text
    private func createPDFFromText(_ text: String) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            let textFont = UIFont.systemFont(ofSize: 10)
            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            
            // Split the text into manageable chunks
            let textChunks = text.split(separator: "\n\n")
            let chunkSize = 40 // Approximately lines per page
            var currentChunks: [String] = []
            var currentSize = 0
            
            for chunk in textChunks {
                currentChunks.append(String(chunk))
                currentSize += 1
                
                if currentSize >= chunkSize {
                    // Render a page with current chunks
                    context.beginPage()
                    
                    // Title
                    "Military Payslip Content".draw(
                        in: CGRect(x: 50, y: 20, width: pageRect.width - 100, height: 30),
                        withAttributes: [.font: titleFont]
                    )
                    
                    // Content
                    let joinedText = currentChunks.joined(separator: "\n\n")
                    joinedText.draw(
                        in: CGRect(x: 50, y: 60, width: pageRect.width - 100, height: pageRect.height - 100),
                        withAttributes: [.font: textFont]
                    )
                    
                    // Reset for next page
                    currentChunks = []
                    currentSize = 0
                }
            }
            
            // Any remaining chunks
            if !currentChunks.isEmpty {
                context.beginPage()
                
                // Title
                "Military Payslip Content".draw(
                    in: CGRect(x: 50, y: 20, width: pageRect.width - 100, height: 30),
                    withAttributes: [.font: titleFont]
                )
                
                // Content
                let joinedText = currentChunks.joined(separator: "\n\n")
                joinedText.draw(
                    in: CGRect(x: 50, y: 60, width: pageRect.width - 100, height: pageRect.height - 100),
                    withAttributes: [.font: textFont]
                )
            }
        }
    }
    
    private func renderPDFFromCGPDF(_ cgPDF: CGPDFDocument) -> Data {
        let pageCount = cgPDF.numberOfPages
        
        // Create a PDF with A4 size (or use first page bounds if available)
        var pageBounds = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // Default A4
        
        if let firstPage = cgPDF.page(at: 1) {
            pageBounds = firstPage.getBoxRect(.mediaBox)
            if pageBounds.width < 10 || pageBounds.height < 10 {
                // Invalid bounds, use default A4
                pageBounds = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
            }
        }
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        
        return renderer.pdfData { context in
            for i in 1...pageCount {
                guard let page = cgPDF.page(at: i) else { continue }
                
                context.beginPage()
                let ctx = context.cgContext
                
                // Get the page bounds
                let pageBounds = page.getBoxRect(.mediaBox)
                
                // Flip coordinates and apply scaling if needed
                ctx.translateBy(x: 0, y: context.pdfContextBounds.height)
                ctx.scaleBy(x: 1, y: -1)
                
                // Scale to fit if needed
                let scaleX = context.pdfContextBounds.width / pageBounds.width
                let scaleY = context.pdfContextBounds.height / pageBounds.height
                let scale = min(scaleX, scaleY)
                
                ctx.scaleBy(x: scale, y: scale)
                
                // Draw the page
                ctx.drawPDFPage(page)
            }
        }
    }
} 