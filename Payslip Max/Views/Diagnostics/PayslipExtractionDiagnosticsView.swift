import SwiftUI
import PDFKit

struct PayslipExtractionDiagnosticsView: View {
    let payslip: PayslipItem
    @State private var rawText: String = ""
    @State private var extractionResults: [ExtractionResult] = []
    @State private var isLoading: Bool = false
    @State private var selectedTab: DiagnosticTab = .patterns
    @State private var parsedData: ParsedPayslipData?
    @State private var parserError: Error?
    
    enum DiagnosticTab {
        case patterns, rawText, enhancedParser
    }
    
    var body: some View {
        VStack {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Extraction Patterns").tag(DiagnosticTab.patterns)
                Text("Raw Text").tag(DiagnosticTab.rawText)
                Text("Enhanced Parser").tag(DiagnosticTab.enhancedParser)
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
                case .enhancedParser:
                    enhancedParserView
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
                        
                        if result.matches.isEmpty {
                            Text("No matches found")
                                .foregroundColor(.red)
                                .italic()
                                .accessibilityIdentifier("no_matches_\(result.patternName.lowercased().replacingOccurrences(of: " ", with: "_"))")
                        } else {
                            ForEach(result.matches, id: \.self) { match in
                                HStack {
                                    Text(match)
                                        .accessibilityIdentifier("match_\(result.patternName.lowercased().replacingOccurrences(of: " ", with: "_"))")
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .accessibilityIdentifier("section_\(result.patternName.lowercased().replacingOccurrences(of: " ", with: "_"))")
            }
        }
        .accessibilityIdentifier("pattern_matches_list")
    }
    
    // View showing raw text
    private var rawTextView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Raw Text Extracted from PDF:")
                    .font(.headline)
                    .padding(.bottom, 8)
                    .accessibilityIdentifier("raw_text_header")
                
                Text(rawText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .accessibilityIdentifier("raw_text_content")
            }
            .padding()
        }
        .accessibilityIdentifier("raw_text_view")
    }
    
    // View showing enhanced parser results
    private var enhancedParserView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let pdfData = payslip.pdfData, let _ = PDFDocument(data: pdfData) {
                    Text("Enhanced Parser Analysis")
                        .font(.headline)
                        .accessibilityIdentifier("enhanced_parser_header")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Document Structure Detection:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .accessibilityIdentifier("document_structure_header")
                        
                        if let parsedData = parsedData {
                            Text("Detected Structure: \(String(describing: parsedData.documentStructure))")
                                .padding(.leading)
                                .accessibilityIdentifier("detected_structure")
                            
                            Text("Confidence Score: \(String(format: "%.2f", parsedData.confidenceScore))")
                                .padding(.leading)
                                .accessibilityIdentifier("confidence_score")
                            
                            Divider()
                            
                            Text("Personal Information:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(parsedData.personalInfo.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(value)
                                        .fontWeight(.medium)
                                }
                                .padding(.leading)
                            }
                            
                            Divider()
                            
                            Text("Earnings:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(parsedData.earnings.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("₹\(String(format: "%.0f", value))")
                                        .fontWeight(.medium)
                                }
                                .padding(.leading)
                            }
                            
                            Divider()
                            
                            Text("Deductions:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(parsedData.deductions.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("₹\(String(format: "%.0f", value))")
                                        .fontWeight(.medium)
                                }
                                .padding(.leading)
                            }
                            
                            Divider()
                            
                            Text("Tax Details:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(parsedData.taxDetails.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("₹\(String(format: "%.0f", value))")
                                        .fontWeight(.medium)
                                }
                                .padding(.leading)
                            }
                            
                            Divider()
                            
                            Text("DSOP Details:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(parsedData.dsopDetails.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("₹\(String(format: "%.0f", value))")
                                        .fontWeight(.medium)
                                }
                                .padding(.leading)
                            }
                            
                            Divider()
                            
                            Text("Metadata:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(parsedData.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(value)
                                        .fontWeight(.medium)
                                }
                                .padding(.leading)
                            }
                        } else if let error = parserError {
                            Text("Error analyzing with enhanced parser: \(error.localizedDescription)")
                                .foregroundColor(.red)
                                .padding()
                        } else {
                            Text("No parsed data available")
                                .foregroundColor(.red)
                                .italic()
                                .padding()
                        }
                    }
                } else {
                    Text("No PDF data available for enhanced analysis")
                        .foregroundColor(.red)
                        .italic()
                        .padding()
                }
            }
            .padding()
        }
        .accessibilityIdentifier("enhanced_parser_view")
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
            
            // Parse data with enhanced parser
            do {
                let enhancedParser = EnhancedPDFParser()
                self.parsedData = try enhancedParser.parseDocument(pdfDocument)
            } catch {
                self.parserError = error
                print("Error analyzing with enhanced parser: \(error.localizedDescription)")
            }
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
            results.append(ExtractionResult(patternName: name, pattern: pattern, matches: matches))
        }
        
        self.extractionResults = results
    }
    
    // Analyze a specific pattern (keeping this for reference)
    private func analyzePattern(name: String, pattern: String, text: String) -> ExtractionResult {
        var matches: [String] = []
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for match in results {
                if match.numberOfRanges > 0 {
                    // Get the entire match
                    let matchRange = match.range(at: 0)
                    let matchText = nsString.substring(with: matchRange)
                    
                    // If there's a capture group, get that too
                    if match.numberOfRanges > 1 {
                        let captureRange = match.range(at: 1)
                        let captureText = nsString.substring(with: captureRange)
                        matches.append("\(matchText) → Captured: \(captureText)")
                    } else {
                        matches.append(matchText)
                    }
                }
            }
        }
        
        return ExtractionResult(patternName: name, pattern: pattern, matches: matches)
    }
}

// Model for extraction results
struct ExtractionResult: Identifiable {
    let id = UUID()
    let patternName: String
    let pattern: String
    let matches: [String]
}

struct PayslipExtractionDiagnosticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PayslipExtractionDiagnosticsView(
                payslip: PayslipItemFactory.createSample() as! PayslipItem
            )
        }
    }
} 