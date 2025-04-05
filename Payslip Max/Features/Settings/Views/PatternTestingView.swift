import SwiftUI
import PDFKit

/// View for testing patterns against PDF documents
struct PatternTestingView: View {
    
    // MARK: - Properties
    
    // Environment
    @Environment(\.dismiss) private var dismiss
    
    // Input parameters
    let pattern: PatternDefinition
    
    // State
    @StateObject private var viewModel = PatternTestingViewModel()
    @State private var showingDocumentPicker = false
    @State private var documentURL: URL?
    @State private var extractedValue: String?
    @State private var pdfPreviewHeight: CGFloat = 300
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Pattern info
                patternInfoSection
                
                // PDF preview
                pdfPreviewSection
                
                // Test results
                resultSection
                
                // Testing controls
                controlsSection
            }
            .padding()
            .navigationTitle("Test Pattern")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isTestSuccessful {
                        Button {
                            viewModel.saveTestResults(pattern: pattern, testValue: extractedValue)
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
    
    // MARK: - Sections
    
    private var patternInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pattern: \(pattern.name)")
                .font(.headline)
            
            Text("Key: \(pattern.key)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Category: \(pattern.category.displayName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Pattern items: \(pattern.patterns.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(pattern.patterns) { item in
                HStack(alignment: .top) {
                    Image(systemName: patternTypeIcon(for: item.type))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading) {
                        Text(patternTypeTitle(for: item.type))
                            .font(.caption)
                            .bold()
                        
                        Text(item.pattern)
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var pdfPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Test Document")
                    .font(.headline)
                
                Spacer()
                
                if documentURL != nil {
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Text("Change")
                            .font(.caption)
                    }
                }
            }
            
            if let documentURL = documentURL, viewModel.pdfDocument != nil {
                VStack {
                    TestingPDFKitView(document: viewModel.pdfDocument!)
                        .frame(height: pdfPreviewHeight)
                    
                    HStack {
                        Text(documentURL.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Slider(value: $pdfPreviewHeight, in: 200...600, step: 50)
                            .frame(width: 100)
                    }
                }
            } else {
                Button {
                    showingDocumentPicker = true
                } label: {
                    VStack {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.largeTitle)
                            .padding()
                        
                        Text("Select PDF Document")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test Results")
                .font(.headline)
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let extractedValue = extractedValue {
                if extractedValue.isEmpty {
                    Text("No value could be extracted with this pattern.")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Extracted Value:")
                            .font(.subheadline)
                        
                        Text(extractedValue)
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
            } else if documentURL != nil {
                Text("Press 'Run Test' to extract data from the document.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Text("Select a document first to test pattern extraction.")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var controlsSection: some View {
        VStack {
            Button {
                testPattern()
            } label: {
                Text("Run Test")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(documentURL != nil ? Color.accentColor : Color.gray)
                    )
                    .foregroundColor(.white)
            }
            .disabled(documentURL == nil || viewModel.isLoading)
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
    
    // MARK: - Helpers
    
    private func patternTypeIcon(for type: ExtractorPatternType) -> String {
        switch type {
        case .regex:
            return "r.square"
        case .keyword:
            return "k.square"
        case .positionBased:
            return "arrow.left.and.right.square"
        }
    }
    
    private func patternTypeTitle(for type: ExtractorPatternType) -> String {
        switch type {
        case .regex:
            return "Regex Pattern"
        case .keyword:
            return "Keyword Pattern"
        case .positionBased:
            return "Position-Based Pattern"
        }
    }
}

/// PDF view wrapper for SwiftUI
struct TestingPDFKitView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
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
        
        PatternTestingView(pattern: samplePattern)
    }
} 