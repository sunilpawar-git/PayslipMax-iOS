import SwiftUI
import PDFKit

struct PayslipExtractionDiagnosticsView: View {
    let payslip: PayslipItem
    @State private var rawText: String = ""
    @State private var extractionResults: [ExtractionResult] = []
    @State private var isLoading: Bool = false
    @State private var selectedTab: DiagnosticTab = .patterns
    
    enum DiagnosticTab {
        case patterns, rawText
    }
    
    var body: some View {
        VStack {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Extraction Patterns").tag(DiagnosticTab.patterns)
                Text("Raw Text").tag(DiagnosticTab.rawText)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .accessibilityIdentifier("diagnostics_tabs")
            
            if isLoading {
                ProgressView("Analyzing payslip...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier("loading_indicator")
            } else {
                switch selectedTab {
                case .patterns:
                    patternMatchesView
                case .rawText:
                    rawTextView
                }
            }
        }
        .navigationTitle("Extraction Diagnostics")
        .onAppear {
            loadData()
        }
    }
    
    // View showing pattern matches
    private var patternMatchesView: some View {
        List {
            ForEach(extractionResults) { result in
                Section(header: Text(result.patternName)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pattern: \(result.pattern)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("pattern_\(result.patternName.lowercased().replacingOccurrences(of: " ", with: "_"))")
                        
                        if !result.matches.isEmpty {
                            Text("Matches Found: \(result.matches.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            ForEach(result.matches, id: \.self) { match in
                                Text(match)
                                    .padding(.leading)
                                    .font(.body)
                                    .background(Color.yellow.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        } else {
                            Text("No matches found")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                }
            }
        }
        .accessibilityIdentifier("pattern_matches_view")
    }
    
    // View showing raw extracted text
    private var rawTextView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Raw Extracted Text")
                    .font(.headline)
                    .padding(.bottom)
                
                Text(rawText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .accessibilityIdentifier("raw_text_content")
            }
            .padding()
        }
        .accessibilityIdentifier("raw_text_view")
    }
    
    // Load data from the payslip
    private func loadData() {
        isLoading = true
        
        // Extract raw text from PDF
        if let pdfData = payslip.pdfData, let pdfDocument = PDFDocument(data: pdfData) {
            var extractedText = ""
            for i in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: i), let pageText = page.string {
                    extractedText += pageText + "\n\n--- PAGE BREAK ---\n\n"
                }
            }
            self.rawText = extractedText
            
            // Analyze pattern matches
            analyzePatternMatches(text: extractedText)
            
            // Enhanced parser removed - using unified ModularPayslipProcessingPipeline instead
        }
        
        isLoading = false
    }
    
    // Analyze which patterns match in the text
    private func analyzePatternMatches(text: String) {
        var results: [ExtractionResult] = []
        
        // Get common extraction patterns
        let patterns = PayslipParsingUtility.getCommonExtractionPatterns()
        let patternResults = PayslipParsingUtility.analyzeExtractionPatterns(in: text, patterns: patterns)
        
        // Convert the results to ExtractionResult objects
        for (name, pattern) in patterns {
            let matches = patternResults[name] ?? []
            let result = ExtractionResult(
                id: UUID(),
                patternName: name,
                pattern: pattern,
                matches: matches
            )
            results.append(result)
        }
        
        self.extractionResults = results
    }
}

// Data structure for extraction results
struct ExtractionResult: Identifiable {
    let id: UUID
    let patternName: String
    let pattern: String
    let matches: [String]
}

// MARK: - Preview
struct PayslipExtractionDiagnosticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PayslipExtractionDiagnosticsView(payslip: PayslipItemFactory.createSample())
        }
    }
}