import SwiftUI
import Charts

struct ChartsSection: View {
    let items: [PayslipItem]
    
    var body: some View {
        VStack(spacing: 16) {
            // Monthly Overview
            ChartCard(title: "Monthly Overview") {
                CreditsDebitsChartView(items: items)
            }
            
            // DSOP Growth
            ChartCard(title: "DSOP Growth") {
                DSOPChartView(items: items)
            }
            
            // Income Tax
            ChartCard(title: "Income Tax") {
                IncomeTaxChartView(items: items)
            }
        }
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
} 