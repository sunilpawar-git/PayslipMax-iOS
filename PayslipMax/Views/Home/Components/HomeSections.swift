import SwiftUI

struct UploadSection: View {
    var body: some View {
        VStack {
            Image(systemName: "doc.badge.plus")
                .font(.largeTitle)
            Text("Upload Payslip")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentPayslipsSection: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Payslips")
                .font(.headline)
            // Add recent payslips list
        }
    }
}

struct QuickStatsSection: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Quick Stats")
                .font(.headline)
            // Add stats
        }
    }
} 