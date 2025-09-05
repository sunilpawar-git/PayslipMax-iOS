import SwiftUI

/// Header section for the manual entry form
struct ManualEntryHeaderSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Create Payslip")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Enter your payslip details manually")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ManualEntryHeaderSection()
}
