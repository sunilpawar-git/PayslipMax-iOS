import SwiftUI

/// Detailed breakdown of parsing confidence scores
/// Shows overall confidence, field-level breakdown, and action buttons
struct ConfidenceDetailView: View {
    let overallConfidence: Double
    let fieldConfidences: [String: Double]
    let source: String
    let onReparse: (() -> Void)?
    let onEdit: (() -> Void)?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Overall confidence
                    overallSection

                    Divider()

                    // Field breakdown
                    if !fieldConfidences.isEmpty {
                        fieldBreakdownSection

                        Divider()
                    }

                    // Actions
                    if onReparse != nil || onEdit != nil {
                        actionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Parsing Confidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var overallSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overall Confidence")
                .font(.headline)

            HStack {
                ProgressView(value: overallConfidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor))

                Text("\(Int(overallConfidence * 100))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(confidenceColor)
                    .frame(width: 50, alignment: .trailing)
            }

            Text("Source: \(source)")
                .font(.caption)
                .foregroundColor(.secondary)

            // Explanation based on confidence level
            Text(confidenceExplanation)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }

    private var fieldBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Field-Level Confidence")
                .font(.headline)

            ForEach(sortedFields, id: \.key) { field in
                HStack {
                    Image(systemName: iconName(for: field.value))
                        .foregroundColor(color(for: field.value))
                        .frame(width: 20)

                    Text(displayName(for: field.key))
                        .font(.system(size: 14))

                    Spacer()

                    Text("\(Int(field.value * 100))%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color(for: field.value))
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if let onReparse = onReparse {
                Button(action: {
                    onReparse()
                    dismiss()
                }) {
                    Label("Re-parse Document", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if let onEdit = onEdit {
                Button(action: {
                    onEdit()
                    dismiss()
                }) {
                    Label("Edit Manually", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Helpers

    private var sortedFields: [(key: String, value: Double)] {
        fieldConfidences.sorted { $0.key < $1.key }
    }

    private var confidenceColor: Color {
        if overallConfidence >= 0.85 { return .green }
        if overallConfidence >= 0.60 { return .orange }
        return .red
    }

    private var confidenceExplanation: String {
        if overallConfidence >= 0.85 {
            return "Great! Your payslip was parsed accurately. All values look good."
        } else if overallConfidence >= 0.60 {
            return "We've parsed your payslip, but some values might need a quick review. Tap fields below to see details."
        } else {
            return "We had trouble reading some parts of your payslip. Please review the values carefully."
        }
    }

    private func color(for confidence: Double) -> Color {
        if confidence >= 0.85 { return .green }
        if confidence >= 0.60 { return .orange }
        return .red
    }

    private func iconName(for confidence: Double) -> String {
        if confidence >= 0.85 { return "checkmark.circle.fill" }
        if confidence >= 0.60 { return "exclamationmark.triangle.fill" }
        return "xmark.circle.fill"
    }

    private func displayName(for key: String) -> String {
        // Convert field keys to readable names
        switch key {
        case "month": return "Month"
        case "year": return "Year"
        case "grossPay": return "Gross Pay"
        case "netRemittance": return "Net Pay"
        case "earnings": return "Earnings"
        case "deductions": return "Deductions"
        case "basicPay": return "Basic Pay"
        case "credits": return "Total Credits"
        default: return key.capitalized
        }
    }
}

// MARK: - Preview Provider

#Preview("High Confidence") {
    ConfidenceDetailView(
        overallConfidence: 0.95,
        fieldConfidences: [
            "month": 1.0,
            "year": 1.0,
            "netRemittance": 1.0,
            "grossPay": 1.0,
            "earnings": 0.95,
            "deductions": 0.90
        ],
        source: "LLM (Gemini)",
        onReparse: { print("Re-parse tapped") },
        onEdit: { print("Edit tapped") }
    )
}

#Preview("Medium Confidence") {
    ConfidenceDetailView(
        overallConfidence: 0.72,
        fieldConfidences: [
            "month": 1.0,
            "year": 1.0,
            "netRemittance": 0.80,
            "grossPay": 0.70,
            "earnings": 0.65,
            "deductions": 0.60
        ],
        source: "Universal Parser",
        onReparse: { print("Re-parse tapped") },
        onEdit: { print("Edit tapped") }
    )
}

#Preview("Low Confidence") {
    ConfidenceDetailView(
        overallConfidence: 0.45,
        fieldConfidences: [
            "month": 0.70,
            "year": 1.0,
            "netRemittance": 0.20,
            "grossPay": 0.30,
            "earnings": 0.40,
            "deductions": 0.50
        ],
        source: "Universal Parser",
        onReparse: nil,
        onEdit: { print("Edit tapped") }
    )
}

#Preview("No Actions") {
    ConfidenceDetailView(
        overallConfidence: 0.88,
        fieldConfidences: [
            "month": 1.0,
            "year": 1.0,
            "netRemittance": 0.95,
            "earnings": 0.85
        ],
        source: "LLM (Gemini)",
        onReparse: nil,
        onEdit: nil
    )
}
