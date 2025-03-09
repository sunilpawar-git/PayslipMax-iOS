import SwiftUI
import UniformTypeIdentifiers

/// A view for displaying PDF extraction statistics and managing training data.
struct PDFExtractionTrainingView: View {
    // MARK: - Properties
    
    /// The statistics about extraction accuracy.
    @State private var statistics = PDFExtractionTrainer.shared.getStatistics()
    
    /// The most common extraction issues.
    @State private var commonIssues = PDFExtractionTrainer.shared.getCommonIssues()
    
    /// Whether to show the export sheet.
    @State private var showingExportSheet = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            // Statistics section
            Section(header: Text("Extraction Statistics")) {
                StatisticRow(title: "Total Samples", value: "\(statistics.totalSamples)")
                StatisticRow(title: "Samples with Feedback", value: "\(statistics.samplesWithFeedback)")
                StatisticRow(title: "Correct Extractions", value: "\(statistics.correctSamples)")
                StatisticRow(title: "Incorrect Extractions", value: "\(statistics.incorrectSamples)")
                StatisticRow(
                    title: "Accuracy Rate",
                    value: String(format: "%.1f%%", statistics.accuracyRate * 100)
                )
            }
            
            // Common issues section
            if !commonIssues.isEmpty {
                Section(header: Text("Common Issues")) {
                    ForEach(commonIssues, id: \.field) { issue in
                        HStack {
                            Text(issue.field.capitalized)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(issue.occurrences) occurrences")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Actions section
            Section(header: Text("Actions")) {
                Button(action: {
                    showingExportSheet = true
                }) {
                    Label("Export Training Data", systemImage: "square.and.arrow.up")
                }
                
                Button(action: refreshData) {
                    Label("Refresh Data", systemImage: "arrow.clockwise")
                }
            }
        }
        .navigationTitle("PDF Extraction Training")
        .fileExporter(
            isPresented: $showingExportSheet,
            document: TrainingDataDocument(),
            contentType: .json,
            defaultFilename: "pdf_extraction_training_data"
        ) { result in
            switch result {
            case .success(let url):
                print("Training data exported to \(url.path)")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
        .onAppear {
            refreshData()
        }
    }
    
    // MARK: - Methods
    
    /// Refreshes the statistics and common issues.
    private func refreshData() {
        statistics = PDFExtractionTrainer.shared.getStatistics()
        commonIssues = PDFExtractionTrainer.shared.getCommonIssues()
    }
}

// MARK: - Supporting Views

/// A row for displaying a statistic.
struct StatisticRow: View {
    /// The title of the statistic.
    let title: String
    
    /// The value of the statistic.
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Supporting Types

/// A document for exporting training data.
struct TrainingDataDocument: FileDocument {
    /// The types of content that can be exported.
    static var readableContentTypes: [UTType] { [.json] }
    
    /// Initializes a new TrainingDataDocument.
    init() {}
    
    /// Initializes a new TrainingDataDocument from file data.
    init(configuration: ReadConfiguration) throws {
        // Not used for export-only
    }
    
    /// Writes the document to a file.
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let tempURL = documentsDirectory.appendingPathComponent("temp_training_data.json")
        
        try PDFExtractionTrainer.shared.exportTrainingData(to: tempURL)
        let data = try Data(contentsOf: tempURL)
        
        try? FileManager.default.removeItem(at: tempURL)
        
        return FileWrapper(regularFileWithContents: data)
    }
} 