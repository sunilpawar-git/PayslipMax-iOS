import Foundation

/// Manages the storage and retrieval of PDF extraction training samples.
/// This class handles loading from and saving to a JSON file.
///
/// Phase 2C: Converted to dual-mode pattern supporting both singleton and DI
class TrainingDataStore {
    // MARK: - Properties

    /// Phase 2C: Shared singleton instance maintained for backward compatibility
    static let shared = TrainingDataStore()

    /// The collection of training samples. Accessible for reading by other components.
    internal private(set) var trainingSamples: [TrainingSample] = []

    /// The file URL for storing training data.
    private let trainingDataURL: URL

    // MARK: - Initialization

    /// Phase 2C: Private initializer for singleton pattern
    /// Initializes the data store and loads existing data.
    private init() {
        // Get the documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Could not access documents directory.") // Consider non-fatal error handling
        }
        trainingDataURL = documentsDirectory.appendingPathComponent("pdf_extraction_training_data.json")

        // Load existing training data if available
        loadTrainingData()
        print("TrainingDataStore: Initialized with singleton pattern. Loaded \(trainingSamples.count) samples from \(trainingDataURL.lastPathComponent)")
    }

    /// Phase 2C: Public initializer for dependency injection
    /// - Parameter customURL: Optional custom URL for training data file (for testing)
    init(customURL: URL? = nil) {
        if let customURL = customURL {
            trainingDataURL = customURL
        } else {
            // Get the documents directory
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("Could not access documents directory.") // Consider non-fatal error handling
            }
            trainingDataURL = documentsDirectory.appendingPathComponent("pdf_extraction_training_data.json")
        }

        // Load existing training data if available
        loadTrainingData()
        print("TrainingDataStore: Initialized with dependency injection. Loaded \(trainingSamples.count) samples from \(trainingDataURL.lastPathComponent)")
    }

    // MARK: - Public Methods (Data Modification & Export)

    /// Records a new extraction result.
    ///
    /// - Parameters:
    ///   - sample: The TrainingSample to record.
    func recordSample(_ sample: TrainingSample) {
        trainingSamples.append(sample)
        saveTrainingData()
        print("TrainingDataStore: Recorded new sample ID \(sample.id). Total samples: \(trainingSamples.count)")
    }

    /// Updates a sample with user corrections.
    ///
    /// - Parameters:
    ///   - pdfFilename: The filename of the PDF associated with the sample.
    ///   - corrections: The snapshot of the corrected data.
    /// - Returns: The updated TrainingSample if found and updated, otherwise nil.
    @discardableResult
    func recordCorrections(pdfFilename: String, corrections: ExtractedDataSnapshot) -> TrainingSample? {
        // Find the most recent sample for this PDF
        if let index = trainingSamples.lastIndex(where: { $0.pdfFilename == pdfFilename }) {
            // Update the sample
            trainingSamples[index].userCorrections = corrections
            trainingSamples[index].isCorrect = false // Mark as incorrect since corrections were needed

            // Save the updated training data
            saveTrainingData()
            print("TrainingDataStore: Recorded corrections for sample ID \(trainingSamples[index].id) (PDF: \(pdfFilename)). Total samples: \(trainingSamples.count)")
            return trainingSamples[index]
        } else {
            print("TrainingDataStore: Could not find sample for PDF \(pdfFilename) to record corrections.")
            return nil
        }
    }

    /// Exports the training data to a specified file URL.
    ///
    /// - Parameter url: The URL to export the JSON data to.
    /// - Throws: An error if encoding or writing fails.
    func exportTrainingData(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // Ensure consistent output
        encoder.dateEncodingStrategy = .iso8601 // Use standard date format

        do {
            let data = try encoder.encode(trainingSamples)
            try data.write(to: url, options: .atomic) // Use atomic write for safety
            print("TrainingDataStore: Exported \(trainingSamples.count) samples to \(url.path)")
        } catch {
            print("TrainingDataStore: Failed to export training data: \(error)")
            throw error // Re-throw the error for the caller to handle
        }
    }


    // MARK: - Private Methods (Persistence)

    /// Loads training data from disk.
    private func loadTrainingData() {
        guard FileManager.default.fileExists(atPath: trainingDataURL.path) else {
            print("TrainingDataStore: No existing training data file found at \(trainingDataURL.path)")
            return
        }

        do {
            let data = try Data(contentsOf: trainingDataURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601 // Match encoding strategy
            trainingSamples = try decoder.decode([TrainingSample].self, from: data)
        } catch {
            print("TrainingDataStore: Failed to load or decode training data: \(error). Starting with empty dataset.")
            // Handle error gracefully, e.g., by starting fresh or attempting recovery
            trainingSamples = []
        }
    }

    /// Saves training data to disk.
    private func saveTrainingData() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // Consistent output
        encoder.dateEncodingStrategy = .iso8601 // Standard date format

        do {
            let data = try encoder.encode(trainingSamples)
            try data.write(to: trainingDataURL, options: .atomic) // Atomic write
            // Avoid overly verbose logging on every save if frequent
            // print("TrainingDataStore: Saved \(trainingSamples.count) training samples to \(trainingDataURL.lastPathComponent)")
        } catch {
            print("TrainingDataStore: Failed to save training data: \(error)")
            // Consider more robust error handling, e.g., retry logic or user notification
        }
    }
}
