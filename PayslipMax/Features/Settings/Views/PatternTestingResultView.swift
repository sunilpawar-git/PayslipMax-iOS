import SwiftUI

/// View component for displaying pattern testing results
struct PatternTestingResultView: View {
    // MARK: - Properties

    @Binding var extractedValue: String?
    let documentURL: URL?
    let isLoading: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test Results")
                .font(.headline)

            if isLoading {
                loadingView
            } else if let extractedValue = extractedValue {
                resultContentView(extractedValue)
            } else {
                placeholderView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    // MARK: - Subviews

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }

    private func resultContentView(_ value: String) -> some View {
        Group {
            if value.isEmpty {
                Text("No value could be extracted with this pattern.")
                    .foregroundColor(.red)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Extracted Value:")
                        .font(.subheadline)

                    Text(value)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green, lineWidth: 1)
                        )
                }
            }
        }
    }

    private var placeholderView: some View {
        let message: String
        let color: Color

        if documentURL != nil {
            message = "Press 'Run Test' to extract data from the document."
            color = .secondary
        } else {
            message = "Select a document first to test pattern extraction."
            color = .secondary
        }

        return Text(message)
            .foregroundColor(color)
            .padding()
    }
}

/// Preview provider for PatternTestingResultView
struct PatternTestingResultView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Loading state
            PatternTestingResultView(
                extractedValue: .constant(nil),
                documentURL: URL(string: "file://sample.pdf"),
                isLoading: true
            )

            // Success state
            PatternTestingResultView(
                extractedValue: .constant("$5,000.00"),
                documentURL: URL(string: "file://sample.pdf"),
                isLoading: false
            )

            // Empty result state
            PatternTestingResultView(
                extractedValue: .constant(""),
                documentURL: URL(string: "file://sample.pdf"),
                isLoading: false
            )

            // No document selected
            PatternTestingResultView(
                extractedValue: .constant(nil),
                documentURL: nil,
                isLoading: false
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
