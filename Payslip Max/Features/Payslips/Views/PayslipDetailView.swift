import SwiftUI
import UIKit

// Define notification names
extension Notification.Name {
    static let payslipUpdated = Notification.Name("PayslipUpdated")
    static let payslipDeleted = Notification.Name("PayslipDeleted")
}

struct PayslipDetailView<T: PayslipViewModelProtocol>: View {
    @ObservedObject var viewModel: T
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
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
                    viewModel.showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        )
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: [viewModel.getShareText()])
        }
        .sheet(isPresented: $viewModel.showOriginalPDF) {
            if let payslipItem = viewModel.payslip as? PayslipItem, let pdfData = payslipItem.pdfData {
                NavigationView {
                    EnhancedPDFView(pdfData: pdfData)
                        .navigationTitle("Original PDF")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    viewModel.showOriginalPDF = false
                                }
                            }
                        }
                }
            } else {
                Text("PDF not available")
                    .font(.title)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding(.horizontal)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle(Text("Payslip Details"))
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