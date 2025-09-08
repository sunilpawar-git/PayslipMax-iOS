import SwiftUI

/// View for testing patterns against PDF documents
/// Refactored to use modular components for better maintainability and adherence to 300-line rule
struct PatternTestingView: View {

    // MARK: - Properties

    // Environment
    @Environment(\.dismiss) private var dismiss

    // Input parameters
    let pattern: PatternDefinition

    // Dependencies (MVVM compliant - injected through constructor)
    @ObservedObject private var viewModel: PatternTestingViewModel

    // State
    @State private var showingDocumentPicker = false
    @State private var documentURL: URL?
    @State private var extractedValue: String?
    @State private var pdfPreviewHeight: CGFloat = 300

    // MARK: - Initialization

    /// Initialize PatternTestingView with dependency injection
    /// - Parameters:
    ///   - pattern: The pattern definition to test
    ///   - viewModel: The view model for pattern testing operations (injected)
    init(pattern: PatternDefinition, viewModel: PatternTestingViewModel? = nil) {
        self.pattern = pattern
        self._viewModel = ObservedObject(wrappedValue: viewModel ?? DIContainer.shared.makePatternTestingViewModel())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Pattern info section
                    PatternTestingInfoView(pattern: pattern)

                    // PDF preview section
                    PatternTestingPDFPreviewView(
                        documentURL: $documentURL,
                        showingDocumentPicker: $showingDocumentPicker,
                        pdfPreviewHeight: $pdfPreviewHeight,
                        pdfDocument: viewModel.pdfDocument
                    )

                    // Test results section
                    PatternTestingResultView(
                        extractedValue: $extractedValue,
                        documentURL: documentURL,
                        isLoading: viewModel.isLoading
                    )

                    // Testing controls section
                    PatternTestingControlsView(
                        documentURL: documentURL,
                        isLoading: viewModel.isLoading,
                        onTestPattern: testPattern
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .navigationTitle("Pattern Testing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isTestSuccessful {
                        Button {
                            dismiss()
                        } label: {
                            Text("Save Results")
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleDocumentSelection(result)
            }
        }
    }

    // MARK: - Actions

    private func handleDocumentSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }

            let didStartAccessing = selectedURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            }

            documentURL = selectedURL
            viewModel.loadPDF(from: selectedURL)
            extractedValue = nil

        case .failure(let error):
            viewModel.showError(message: "Error selecting document: \(error.localizedDescription)")
        }
    }

    private func testPattern() {
        guard let document = viewModel.pdfDocument else { return }

        Task {
            extractedValue = await viewModel.testPattern(pattern: pattern, document: document)
        }
    }
}

/// Preview provider
struct PatternTestingView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample pattern for preview
        let samplePattern = PatternDefinition.createUserPattern(
            name: "Basic Pay",
            key: "basicPay",
            category: .earnings,
            patterns: [
                ExtractorPattern.regex(
                    pattern: "BASIC PAY:\\s*([0-9,.]+)",
                    priority: 10
                ),
                ExtractorPattern.keyword(
                    keyword: "BASIC PAY",
                    contextAfter: "Rs.",
                    priority: 5
                )
            ]
        )

        // Create a mock view model for preview (or use DI container for testing)
        let mockViewModel = PatternTestingViewModel()

        PatternTestingView(pattern: samplePattern, viewModel: mockViewModel)
    }
}

