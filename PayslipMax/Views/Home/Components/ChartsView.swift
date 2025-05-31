import SwiftUI
import Charts

// Define PayslipChartData here instead of importing it
struct PayslipChartData: Identifiable, Equatable {
    let id = UUID()
    let month: String
    let credits: Double
    let debits: Double
    let net: Double
    
    static func == (lhs: PayslipChartData, rhs: PayslipChartData) -> Bool {
        return lhs.month == rhs.month &&
               lhs.credits == rhs.credits &&
               lhs.debits == rhs.debits &&
               lhs.net == rhs.net
    }
}

/// A view for displaying financial charts
struct ChartsView: View {
    let data: [PayslipChartData]
    let payslips: [AnyPayslip] // Add payslips parameter for the FinancialOverviewCard
    
    // Convert AnyPayslip to PayslipItem for the FinancialOverviewCard
    private var payslipItems: [PayslipItem] {
        return payslips.compactMap { payslip in
            // Try to cast AnyPayslip to PayslipItem
            if let payslipItem = payslip as? PayslipItem {
                // Create a proper timestamp from month/year instead of using existing timestamp
                let calendar = Calendar.current
                let monthNumber = monthStringToNumber(payslip.month)
                var dateComponents = DateComponents()
                dateComponents.year = payslip.year
                dateComponents.month = monthNumber
                dateComponents.day = 1
                
                let correctedTimestamp = calendar.date(from: dateComponents) ?? payslipItem.timestamp
                
                print("🔧 Correcting timestamp for \(payslip.month) \(payslip.year)")
                print("   Original timestamp: \(payslipItem.timestamp)")
                print("   Corrected timestamp: \(correctedTimestamp)")
                
                // Create a new PayslipItem with corrected timestamp
                return PayslipItem(
                    id: payslipItem.id,
                    timestamp: correctedTimestamp,
                    month: payslip.month,
                    year: payslip.year,
                    credits: payslip.credits,
                    debits: payslip.debits,
                    dsop: payslip.dsop,
                    tax: payslip.tax,
                    earnings: payslip.earnings,
                    deductions: payslip.deductions,
                    name: payslipItem.name,
                    accountNumber: payslipItem.accountNumber,
                    panNumber: payslipItem.panNumber,
                    isNameEncrypted: payslipItem.isNameEncrypted,
                    isAccountNumberEncrypted: payslipItem.isAccountNumberEncrypted,
                    isPanNumberEncrypted: payslipItem.isPanNumberEncrypted,
                    sensitiveData: payslipItem.sensitiveData,
                    encryptionVersion: payslipItem.encryptionVersion,
                    pdfData: payslipItem.pdfData,
                    pdfURL: payslipItem.pdfURL,
                    isSample: payslipItem.isSample,
                    source: payslipItem.source,
                    status: payslipItem.status,
                    notes: payslipItem.notes,
                    pages: payslipItem.pages,
                    numberOfPages: payslipItem.numberOfPages,
                    metadata: payslipItem.metadata,
                    documentType: payslipItem.documentType,
                    documentDate: payslipItem.documentDate
                )
            }
            
            // If casting fails, create a new PayslipItem from the protocol data
            let calendar = Calendar.current
            let monthNumber = monthStringToNumber(payslip.month)
            var dateComponents = DateComponents()
            dateComponents.year = payslip.year
            dateComponents.month = monthNumber
            dateComponents.day = 1
            
            let timestamp = calendar.date(from: dateComponents) ?? Date()
            
            print("🆕 Creating new PayslipItem for \(payslip.month) \(payslip.year)")
            print("   Calculated timestamp: \(timestamp)")
            
            return PayslipItem(
                timestamp: timestamp,
                month: payslip.month,
                year: payslip.year,
                credits: payslip.credits,
                debits: payslip.debits,
                dsop: payslip.dsop,
                tax: payslip.tax,
                earnings: payslip.earnings,
                deductions: payslip.deductions
            )
        }
    }
    
    // Helper function to convert month name to number
    private func monthStringToNumber(_ monthString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        
        // Try full month name first
        if let date = formatter.date(from: monthString) {
            return Calendar.current.component(.month, from: date)
        }
        
        // Try short month name
        formatter.dateFormat = "MMM"
        if let date = formatter.date(from: monthString) {
            return Calendar.current.component(.month, from: date)
        }
        
        // Manual mapping for common cases
        switch monthString.lowercased() {
        case "january", "jan": return 1
        case "february", "feb": return 2
        case "march", "mar": return 3
        case "april", "apr": return 4
        case "may": return 5
        case "june", "jun": return 6
        case "july", "jul": return 7
        case "august", "aug": return 8
        case "september", "sep": return 9
        case "october", "oct": return 10
        case "november", "nov": return 11
        case "december", "dec": return 12
        default: return 1 // Default to January if parsing fails
        }
    }
    
    var body: some View {
        // Only show the new Financial Overview Card
        VStack {
            if !payslipItems.isEmpty {
                FinancialOverviewCard(payslips: payslipItems)
            } else {
                // Show empty state when no payslips are available
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Financial Data")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Upload your first payslip to see financial insights")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
    }
}

// Helper struct for equatable comparison
struct ChartsContent: Equatable {
    let data: [PayslipChartData]
    
    static func == (lhs: ChartsContent, rhs: ChartsContent) -> Bool {
        guard lhs.data.count == rhs.data.count else { return false }
        
        for (index, lhsItem) in lhs.data.enumerated() {
            let rhsItem = rhs.data[index]
            if lhsItem != rhsItem {
                return false
            }
        }
        
        return true
    }
}

#Preview {
    ChartsView(
        data: [
            PayslipChartData(month: "Jan", credits: 50000, debits: 30000, net: 20000),
            PayslipChartData(month: "Feb", credits: 60000, debits: 35000, net: 25000),
            PayslipChartData(month: "Mar", credits: 55000, debits: 32000, net: 23000)
        ],
        payslips: []
    )
} 