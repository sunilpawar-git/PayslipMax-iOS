import SwiftUI

/// View component for pattern testing controls
struct PatternTestingControlsView: View {
    // MARK: - Properties

    let documentURL: URL?
    let isLoading: Bool
    let onTestPattern: () -> Void

    // MARK: - Body

    var body: some View {
        VStack {
            Button {
                onTestPattern()
            } label: {
                Text("Run Test")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isEnabled ? Color.accentColor : Color.gray)
                    )
                    .foregroundColor(.white)
            }
            .disabled(!isEnabled)
        }
    }

    // MARK: - Computed Properties

    private var isEnabled: Bool {
        documentURL != nil && !isLoading
    }
}

/// Preview provider for PatternTestingControlsView
struct PatternTestingControlsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Enabled state
            PatternTestingControlsView(
                documentURL: URL(string: "file://sample.pdf"),
                isLoading: false,
                onTestPattern: {}
            )

            // Disabled - no document
            PatternTestingControlsView(
                documentURL: nil,
                isLoading: false,
                onTestPattern: {}
            )

            // Disabled - loading
            PatternTestingControlsView(
                documentURL: URL(string: "file://sample.pdf"),
                isLoading: true,
                onTestPattern: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
