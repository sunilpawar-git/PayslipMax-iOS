import Foundation
import PDFKit

/// A utility class for training and improving the PDF extraction model.
///
/// This class helps collect extraction results, compare them with expected values,
/// analyze issues, and improve the extraction patterns over time.
/// It coordinates with TrainingDataStore for persistence.
///
/// Phase 2C: Converted to dual-mode pattern supporting both singleton and DI
class PDFExtractionTrainer {
    // MARK: - Properties

    /// The shared singleton instance providing access to the PDFExtractionTrainer.
    /// Phase 2C: Maintained for backward compatibility
    static let shared = PDFExtractionTrainer()

    /// The underlying data store responsible for persisting and retrieving training samples.
    /// Phase 2C: Made injectable for dependency injection support
    private let dataStore: TrainingDataStore

    // MARK: - Initialization

    /// Phase 2C: Private initializer for singleton pattern
    /// Uses singleton DataStore for backward compatibility
    private init() {
        self.dataStore = TrainingDataStore.shared
        print("PDFExtractionTrainer: Initialized with singleton pattern.")
    }

    /// Phase 2C: Public initializer for dependency injection
    /// - Parameter dataStore: Injectable TrainingDataStore instance
    init(dataStore: TrainingDataStore) {
        self.dataStore = dataStore
        print("PDFExtractionTrainer: Initialized with dependency injection.")
    }

    // MARK: - Public Methods (Facade for Data Recording & Export)

    /// Records a new extraction result for training.
    /// This creates a TrainingSample and passes it to the data store.
    ///
    /// - Parameters:
    ///   - extractedData: The data extracted from the PDF.
    ///   - pdfURL: The URL of the PDF file.
    ///   - extractedText: The raw text extracted from the PDF.
    ///   - isCorrect: Whether the extraction is correct (if known).
    func recordExtraction(
        extractedData: AnyPayslip,
        pdfURL: URL,
        extractedText: String,
        isCorrect: Bool? = nil
    ) {
        // Create a new training sample
        let snapshot = createSnapshot(from: extractedData)
        let sample = TrainingSample(
            id: UUID().uuidString,
            timestamp: Date(),
            pdfFilename: pdfURL.lastPathComponent,
            extractedData: snapshot,
            extractedText: extractedText,
            isCorrect: isCorrect,
            userCorrections: nil
        )

        // Delegate saving to the data store
        dataStore.recordSample(sample)
        print("PDFExtractionTrainer: Recorded new extraction sample for \(pdfURL.lastPathComponent)")
    }

    /// Records user corrections for a previous extraction.
    /// Updates the data store and then triggers local analysis.
    ///
    /// - Parameters:
    ///   - pdfFilename: The filename of the PDF.
    ///   - corrections: The corrected data.
    func recordCorrections(
        pdfFilename: String,
        corrections: AnyPayslip
    ) {
        // Create a snapshot of the corrections
        let correctionsSnapshot = createSnapshot(from: corrections)

        // Delegate saving corrections to the data store
        if let updatedSample = dataStore.recordCorrections(pdfFilename: pdfFilename, corrections: correctionsSnapshot) {
            print("PDFExtractionTrainer: Recorded corrections for \(pdfFilename)")
            // Analyze the differences to potentially improve extraction logic
            analyzeCorrections(original: updatedSample.extractedData, corrected: correctionsSnapshot)
        } else {
            print("PDFExtractionTrainer: Failed to record corrections as sample for \(pdfFilename) was not found in data store.")
        }
    }

    /// Exports the training data to a file by delegating to the data store.
    ///
    /// - Parameter url: The URL to export to.
    /// - Throws: An error if export fails.
    func exportTrainingData(to url: URL) throws {
        print("PDFExtractionTrainer: Delegating export request to data store.")
        try dataStore.exportTrainingData(to: url)
    }

    // MARK: - Public Methods (Analysis & Statistics)

    /// Gets statistics about the extraction accuracy based on data from the store.
    ///
    /// - Returns: Statistics about the extraction accuracy.
    func getStatistics() -> ExtractionStatistics {
        let samples = dataStore.trainingSamples // Access samples from the store
        let totalSamples = samples.count
        let samplesWithFeedback = samples.filter { $0.isCorrect != nil }.count
        let correctSamples = samples.filter { $0.isCorrect == true }.count
        let incorrectSamples = samples.filter { $0.isCorrect == false }.count

        let accuracyRate: Double
        if samplesWithFeedback > 0 {
            accuracyRate = Double(correctSamples) / Double(samplesWithFeedback)
        } else {
            accuracyRate = 0.0 // Avoid division by zero
        }

        return ExtractionStatistics(
            totalSamples: totalSamples,
            samplesWithFeedback: samplesWithFeedback,
            correctSamples: correctSamples,
            incorrectSamples: incorrectSamples,
            accuracyRate: accuracyRate
        )
    }

    /// Gets the most common extraction issues based on data from the store.
    ///
    /// - Returns: A list of the most common extraction issues.
    func getCommonIssues() -> [ExtractionIssue] {
        var issues: [ExtractionIssue] = []
        let samples = dataStore.trainingSamples // Access samples from the store

        // Find samples with corrections
        let samplesWithCorrections = samples.filter { $0.userCorrections != nil }

        // Count issues by field
        var fieldIssueCount: [String: Int] = [:]

        for sample in samplesWithCorrections {
            guard let corrections = sample.userCorrections else { continue }

            // Compare each field using the helper function
            checkAndRecordIssue(original: sample.extractedData.name, corrected: corrections.name, fieldName: "name", issueCounts: &fieldIssueCount)
            checkAndRecordIssue(original: sample.extractedData.month, corrected: corrections.month, fieldName: "month", issueCounts: &fieldIssueCount)
            checkAndRecordIssue(original: sample.extractedData.year, corrected: corrections.year, fieldName: "year", issueCounts: &fieldIssueCount)
            checkAndRecordIssue(original: sample.extractedData.credits, corrected: corrections.credits, fieldName: "credits", issueCounts: &fieldIssueCount)
            checkAndRecordIssue(original: sample.extractedData.debits, corrected: corrections.debits, fieldName: "debits", issueCounts: &fieldIssueCount)
            checkAndRecordIssue(original: sample.extractedData.dsop, corrected: corrections.dsop, fieldName: "dsop", issueCounts: &fieldIssueCount)
            checkAndRecordIssue(original: sample.extractedData.tax, corrected: corrections.tax, fieldName: "tax", issueCounts: &fieldIssueCount)
            checkAndRecordIssue(original: sample.extractedData.accountNumber, corrected: corrections.accountNumber, fieldName: "accountNumber", issueCounts: &fieldIssueCount)
            checkAndRecordIssue(original: sample.extractedData.panNumber, corrected: corrections.panNumber, fieldName: "panNumber", issueCounts: &fieldIssueCount)
        }

        // Convert to issues
        for (field, count) in fieldIssueCount {
            issues.append(ExtractionIssue(
                field: field,
                occurrences: count,
                description: "Incorrect extraction of \(field)"
            ))
        }

        // Sort by occurrences (most frequent first)
        return issues.sorted { $0.occurrences > $1.occurrences }
    }

    // MARK: - Private Methods (Analysis & Helpers)

    /// Helper function to compare a field and record an issue if different.
    /// Kept within the Trainer as it's part of the analysis logic.
    /// - Parameters:
    ///   - original: The original value of the field.
    ///   - corrected: The corrected value of the field.
    ///   - fieldName: The name of the field being checked.
    ///   - issueCounts: The dictionary holding the counts of issues per field.
    private func checkAndRecordIssue<T: Equatable>(original: T, corrected: T, fieldName: String, issueCounts: inout [String: Int]) {
        if original != corrected {
            issueCounts[fieldName, default: 0] += 1
        }
    }

    /// Analyzes corrections to potentially improve extraction patterns.
    /// This method remains in the Trainer as it represents analysis logic.
    ///
    /// - Parameters:
    ///   - original: The original extracted data snapshot.
    ///   - corrected: The corrected data snapshot.
    private func analyzeCorrections(original: ExtractedDataSnapshot, corrected: ExtractedDataSnapshot) {
        // This function now purely analyzes and logs differences.
        // Persistence is handled by the TrainingDataStore.
        print("PDFExtractionTrainer: Analyzing corrections...")

        var differences: [String] = []
        if original.name != corrected.name { differences.append("Name: '\(original.name)' -> '\(corrected.name)'") }
        if original.month != corrected.month { differences.append("Month: '\(original.month)' -> '\(corrected.month)'") }
        if original.year != corrected.year { differences.append("Year: \(original.year) -> \(corrected.year)") }
        if original.credits != corrected.credits { differences.append("Credits: \(original.credits) -> \(corrected.credits)") }
        if original.debits != corrected.debits { differences.append("Debits: \(original.debits) -> \(corrected.debits)") }
        if original.dsop != corrected.dsop { differences.append("DSOP: \(original.dsop) -> \(corrected.dsop)") }
        if original.tax != corrected.tax { differences.append("Tax: \(original.tax) -> \(corrected.tax)") }
        if original.accountNumber != corrected.accountNumber {
            differences.append("Account Number: '\(original.accountNumber)' -> '\(corrected.accountNumber)'")
        }
        if original.panNumber != corrected.panNumber {
            differences.append("PAN Number: '\(original.panNumber)' -> '\(corrected.panNumber)'")
        }

        if differences.isEmpty {
            print("PDFExtractionTrainer: No differences found in correction analysis.")
        } else {
            print("PDFExtractionTrainer: Differences found:")
            differences.forEach { print("  - \($0)") }
            // TODO: Use these insights to automatically update extraction patterns or suggest improvements.
        }
    }

    /// Creates a snapshot of the extracted data.
    /// Kept as a helper within the Trainer.
    ///
    /// - Parameter payslipItem: The payslip item to create a snapshot from.
    /// - Returns: A snapshot of the extracted data.
    private func createSnapshot(from payslipItem: AnyPayslip) -> ExtractedDataSnapshot {
        // Ensure this uses the ExtractedDataSnapshot defined in its own file.
        return ExtractedDataSnapshot(from: payslipItem)
    }
}

// The struct definitions previously here have been moved to separate files.
