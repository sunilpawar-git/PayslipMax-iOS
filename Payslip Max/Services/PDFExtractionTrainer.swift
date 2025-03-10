import Foundation
import PDFKit

/// A utility class for training and improving the PDF extraction model.
///
/// This class helps collect extraction results, compare them with expected values,
/// and improve the extraction patterns over time.
class PDFExtractionTrainer {
    // MARK: - Properties
    
    /// Shared instance of the trainer.
    static let shared = PDFExtractionTrainer()
    
    /// The collection of training samples.
    private var trainingSamples: [TrainingSample] = []
    
    /// The file URL for storing training data.
    private let trainingDataURL: URL
    
    // MARK: - Initialization
    
    /// Initializes a new PDFExtractionTrainer.
    private init() {
        // Get the documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        trainingDataURL = documentsDirectory.appendingPathComponent("pdf_extraction_training_data.json")
        
        // Load existing training data if available
        loadTrainingData()
    }
    
    // MARK: - Public Methods
    
    /// Records a new extraction result for training.
    ///
    /// - Parameters:
    ///   - extractedData: The data extracted from the PDF.
    ///   - pdfURL: The URL of the PDF file.
    ///   - extractedText: The raw text extracted from the PDF.
    ///   - isCorrect: Whether the extraction is correct (if known).
    func recordExtraction(
        extractedData: any PayslipItemProtocol,
        pdfURL: URL,
        extractedText: String,
        isCorrect: Bool? = nil
    ) {
        // Create a new training sample
        let sample = TrainingSample(
            id: UUID().uuidString,
            timestamp: Date(),
            pdfFilename: pdfURL.lastPathComponent,
            extractedData: ExtractedDataSnapshot(from: extractedData),
            extractedText: extractedText,
            isCorrect: isCorrect,
            userCorrections: nil
        )
        
        // Add to the collection
        trainingSamples.append(sample)
        
        // Save the updated training data
        saveTrainingData()
        
        print("PDFExtractionTrainer: Recorded new extraction sample for \(pdfURL.lastPathComponent)")
    }
    
    /// Records user corrections for a previous extraction.
    ///
    /// - Parameters:
    ///   - pdfFilename: The filename of the PDF.
    ///   - corrections: The corrected data.
    func recordCorrections(
        pdfFilename: String,
        corrections: any PayslipItemProtocol
    ) {
        // Find the most recent sample for this PDF
        if let index = trainingSamples.lastIndex(where: { $0.pdfFilename == pdfFilename }) {
            // Create a snapshot of the corrections
            let correctionsSnapshot = ExtractedDataSnapshot(from: corrections)
            
            // Update the sample
            trainingSamples[index].userCorrections = correctionsSnapshot
            trainingSamples[index].isCorrect = false
            
            // Save the updated training data
            saveTrainingData()
            
            print("PDFExtractionTrainer: Recorded corrections for \(pdfFilename)")
            
            // Analyze the differences to improve extraction
            analyzeCorrections(original: trainingSamples[index].extractedData, corrected: correctionsSnapshot)
        }
    }
    
    /// Gets statistics about the extraction accuracy.
    ///
    /// - Returns: Statistics about the extraction accuracy.
    func getStatistics() -> ExtractionStatistics {
        let totalSamples = trainingSamples.count
        let samplesWithFeedback = trainingSamples.filter { $0.isCorrect != nil }.count
        let correctSamples = trainingSamples.filter { $0.isCorrect == true }.count
        let incorrectSamples = trainingSamples.filter { $0.isCorrect == false }.count
        
        return ExtractionStatistics(
            totalSamples: totalSamples,
            samplesWithFeedback: samplesWithFeedback,
            correctSamples: correctSamples,
            incorrectSamples: incorrectSamples,
            accuracyRate: samplesWithFeedback > 0 ? Double(correctSamples) / Double(samplesWithFeedback) : 0
        )
    }
    
    /// Gets the most common extraction issues.
    ///
    /// - Returns: A list of the most common extraction issues.
    func getCommonIssues() -> [ExtractionIssue] {
        var issues: [ExtractionIssue] = []
        
        // Find samples with corrections
        let samplesWithCorrections = trainingSamples.filter { $0.userCorrections != nil }
        
        // Count issues by field
        var fieldIssueCount: [String: Int] = [:]
        
        for sample in samplesWithCorrections {
            guard let corrections = sample.userCorrections else { continue }
            
            // Compare each field
            if sample.extractedData.name != corrections.name {
                fieldIssueCount["name"] = (fieldIssueCount["name"] ?? 0) + 1
            }
            if sample.extractedData.month != corrections.month {
                fieldIssueCount["month"] = (fieldIssueCount["month"] ?? 0) + 1
            }
            if sample.extractedData.year != corrections.year {
                fieldIssueCount["year"] = (fieldIssueCount["year"] ?? 0) + 1
            }
            if sample.extractedData.credits != corrections.credits {
                fieldIssueCount["credits"] = (fieldIssueCount["credits"] ?? 0) + 1
            }
            if sample.extractedData.debits != corrections.debits {
                fieldIssueCount["debits"] = (fieldIssueCount["debits"] ?? 0) + 1
            }
            if sample.extractedData.dsop != corrections.dsop {
                fieldIssueCount["dsop"] = (fieldIssueCount["dsop"] ?? 0) + 1
            }
            if sample.extractedData.tax != corrections.tax {
                fieldIssueCount["tax"] = (fieldIssueCount["tax"] ?? 0) + 1
            }
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
    
    /// Exports the training data to a file.
    ///
    /// - Parameter url: The URL to export to.
    /// - Throws: An error if export fails.
    func exportTrainingData(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(trainingSamples)
        try data.write(to: url)
        
        print("PDFExtractionTrainer: Exported training data to \(url.path)")
    }
    
    // MARK: - Private Methods
    
    /// Loads training data from disk.
    private func loadTrainingData() {
        do {
            if FileManager.default.fileExists(atPath: trainingDataURL.path) {
                let data = try Data(contentsOf: trainingDataURL)
                let decoder = JSONDecoder()
                trainingSamples = try decoder.decode([TrainingSample].self, from: data)
                
                print("PDFExtractionTrainer: Loaded \(trainingSamples.count) training samples")
            }
        } catch {
            print("PDFExtractionTrainer: Failed to load training data: \(error)")
        }
    }
    
    /// Saves training data to disk.
    private func saveTrainingData() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(trainingSamples)
            try data.write(to: trainingDataURL)
            
            print("PDFExtractionTrainer: Saved \(trainingSamples.count) training samples")
        } catch {
            print("PDFExtractionTrainer: Failed to save training data: \(error)")
        }
    }
    
    /// Analyzes corrections to improve extraction.
    ///
    /// - Parameters:
    ///   - original: The original extracted data.
    ///   - corrected: The corrected data.
    private func analyzeCorrections(original: ExtractedDataSnapshot, corrected: ExtractedDataSnapshot) {
        print("PDFExtractionTrainer: Analyzing corrections")
        
        // Compare each field and log differences
        if original.name != corrected.name {
            print("  Name: '\(original.name)' -> '\(corrected.name)'")
        }
        
        if original.month != corrected.month {
            print("  Month: '\(original.month)' -> '\(corrected.month)'")
        }
        
        if original.year != corrected.year {
            print("  Year: \(original.year) -> \(corrected.year)")
        }
        
        if original.credits != corrected.credits {
            print("  Credits: \(original.credits) -> \(corrected.credits)")
        }
        
        if original.debits != corrected.debits {
            print("  Debits: \(original.debits) -> \(corrected.debits)")
        }
        
        if original.dsop != corrected.dsop {
            print("  DSOP: \(original.dsop) -> \(corrected.dsop)")
        }
        
        if original.tax != corrected.tax {
            print("  Tax: \(original.tax) -> \(corrected.tax)")
        }
        
        // TODO: Use these insights to automatically update extraction patterns
    }
    
    /// Creates a snapshot of the extracted data.
    ///
    /// - Parameter payslipItem: The payslip item to create a snapshot from.
    /// - Returns: A snapshot of the extracted data.
    private func createSnapshot(from payslipItem: any PayslipItemProtocol) -> ExtractedDataSnapshot {
        return ExtractedDataSnapshot(from: payslipItem)
    }
}

// MARK: - Supporting Types

/// A training sample for PDF extraction.
struct TrainingSample: Codable {
    /// The unique identifier for the sample.
    let id: String
    
    /// The timestamp when the sample was created.
    let timestamp: Date
    
    /// The filename of the PDF.
    let pdfFilename: String
    
    /// The data extracted from the PDF.
    let extractedData: ExtractedDataSnapshot
    
    /// The raw text extracted from the PDF.
    let extractedText: String
    
    /// Whether the extraction is correct.
    var isCorrect: Bool?
    
    /// User corrections for the extraction.
    var userCorrections: ExtractedDataSnapshot?
}

/// A snapshot of extracted data.
struct ExtractedDataSnapshot: Codable {
    /// The name of the employee.
    let name: String
    
    /// The month of the payslip.
    let month: String
    
    /// The year of the payslip.
    let year: Int
    
    /// The credits (net pay) amount.
    let credits: Double
    
    /// The debits (deductions) amount.
    let debits: Double
    
    /// The DSOP amount.
    let dsop: Double
    
    /// The tax amount.
    let tax: Double
    
    /// The location.
    let location: String
    
    /// The account number.
    let accountNumber: String
    
    /// The PAN number.
    let panNumber: String
    
    /// Initializes a new ExtractedDataSnapshot from a PayslipItemProtocol.
    ///
    /// - Parameter payslip: The payslip to create a snapshot from.
    init(from payslip: any PayslipItemProtocol) {
        self.name = payslip.name
        self.month = payslip.month
        self.year = payslip.year
        self.credits = payslip.credits
        self.debits = payslip.debits
        self.dsop = payslip.dsop
        self.tax = payslip.tax
        self.location = payslip.location
        self.accountNumber = payslip.accountNumber
        self.panNumber = payslip.panNumber
    }
}

/// Statistics about extraction accuracy.
struct ExtractionStatistics {
    /// The total number of samples.
    let totalSamples: Int
    
    /// The number of samples with feedback.
    let samplesWithFeedback: Int
    
    /// The number of correct samples.
    let correctSamples: Int
    
    /// The number of incorrect samples.
    let incorrectSamples: Int
    
    /// The accuracy rate (correct / total with feedback).
    let accuracyRate: Double
}

/// An extraction issue.
struct ExtractionIssue {
    /// The field with the issue.
    let field: String
    
    /// The number of occurrences of the issue.
    let occurrences: Int
    
    /// A description of the issue.
    let description: String
}