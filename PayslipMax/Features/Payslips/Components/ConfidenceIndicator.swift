import SwiftUI

/// Visual confidence indicator showing parsing data quality
/// Color-coded: Green (90-100%), Yellow (75-89%), Orange (50-74%), Red (<50%)
struct ConfidenceIndicator: View {
    let score: Double
    
    private var percentage: Double {
        return score * 100
    }
    
    private var level: ConfidenceLevel {
        return ConfidenceCalculator.confidenceLevel(for: score)
    }
    
    private var color: Color {
        switch level {
        case .excellent:
            return .green
        case .good:
            return .yellow
        case .reviewRecommended:
            return .orange
        case .manualVerificationRequired:
            return .red
        }
    }
    
    private var icon: String {
        switch level {
        case .excellent:
            return "checkmark.seal.fill"
        case .good:
            return "checkmark.circle.fill"
        case .reviewRecommended:
            return "exclamationmark.triangle.fill"
        case .manualVerificationRequired:
            return "xmark.octagon.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title3)
                    .foregroundColor(color)
                
                Text("Data Quality")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(percentage))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: geometry.size.width * score, height: 12)
                        .animation(.spring(), value: score)
                }
            }
            .frame(height: 12)
            
            // Status Message
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.description)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                    
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Detailed Breakdown (if not excellent)
            if level != .excellent {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ForEach(recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Helper Properties
    
    private var statusMessage: String {
        switch level {
        case .excellent:
            return "All validations passed. Data looks accurate."
        case .good:
            return "Minor discrepancies detected. Data is reliable."
        case .reviewRecommended:
            return "Some validation warnings. Please review the data."
        case .manualVerificationRequired:
            return "Significant issues detected. Manual verification required."
        }
    }
    
    private var recommendations: [String] {
        switch level {
        case .excellent:
            return []
        case .good:
            return [
                "Review 'Other Earnings' and 'Other Deductions' breakdowns",
                "Verify calculated totals match PDF document"
            ]
        case .reviewRecommended:
            return [
                "Check if Gross Pay = BPAY + DA + MSP + Other Earnings",
                "Verify Total Deductions = DSOP + AGIF + Tax + Other",
                "Confirm Net Remittance = Gross Pay - Total Deductions",
                "Use edit buttons to correct 'Other' amounts if needed"
            ]
        case .manualVerificationRequired:
            return [
                "Core fields may be missing or incorrect",
                "Compare all amounts with original PDF",
                "Use edit buttons to manually enter missing data",
                "Consider re-uploading PDF if data is severely inaccurate"
            ]
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ConfidenceIndicator(score: 0.95)
        ConfidenceIndicator(score: 0.80)
        ConfidenceIndicator(score: 0.65)
        ConfidenceIndicator(score: 0.35)
    }
    .padding()
}

