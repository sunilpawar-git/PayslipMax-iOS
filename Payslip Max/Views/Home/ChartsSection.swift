import SwiftUI
import SwiftData

struct ChartsSection: View {
    @Query private var payslips: [Payslip]
    
    init() {
        let sortDescriptor = SortDescriptor<Payslip>(\.timestamp, order: .reverse)
        _payslips = Query(sort: [sortDescriptor])
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Financial Overview")
                .font(.title2)
                .bold()
            
            CreditsDebitsChartView(
                credits: lastSixMonthsCredits,
                debits: lastSixMonthsDebits,
                labels: lastSixMonthsLabels
            )
            .frame(height: 200)
            .cardStyle()
        }
        .padding()
    }
    
    private var lastSixMonthsCredits: [Double] {
        // Calculate credits for last 6 months
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return payslips
            .filter { $0.timestamp >= sixMonthsAgo }
            .map { $0.netPay }
    }
    
    private var lastSixMonthsDebits: [Double] {
        // Calculate debits for last 6 months
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return payslips
            .filter { $0.timestamp >= sixMonthsAgo }
            .flatMap { $0.deductions }
            .map { $0.amount }
    }
    
    private var lastSixMonthsLabels: [String] {
        // Generate labels for last 6 months
        (0..<6).map { monthsAgo in
            let date = Calendar.current.date(byAdding: .month, value: -monthsAgo, to: Date()) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }.reversed()
    }
} 