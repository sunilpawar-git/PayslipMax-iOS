import Foundation

/// A system for learning and suggesting abbreviations based on frequency and context
class AbbreviationLearningSystem {
    // MARK: - Properties
    
    /// The abbreviation manager to use for checking known abbreviations
    private let abbreviationManager: AbbreviationManager
    
    /// Dictionary of unknown abbreviations and their frequency count
    private var unknownAbbreviations: [String: UnknownAbbreviationData] = [:]
    
    /// UserDefaults key for storing unknown abbreviations
    private let userDefaultsKey = "unknownAbbreviationsLearningData"
    
    // MARK: - Initialization
    
    /// Initializes a new AbbreviationLearningSystem
    /// - Parameter abbreviationManager: The abbreviation manager to use
    init(abbreviationManager: AbbreviationManager) {
        self.abbreviationManager = abbreviationManager
        loadUnknownAbbreviations()
    }
    
    // MARK: - Public Methods
    
    /// Tracks an unknown abbreviation occurrence
    /// - Parameters:
    ///   - abbreviation: The abbreviation to track
    ///   - context: The context in which the abbreviation was found (e.g., "earnings", "deductions")
    ///   - value: The value associated with the abbreviation
    func trackUnknownAbbreviation(_ abbreviation: String, context: String, value: Double) {
        // Skip if this is already a known abbreviation
        if abbreviationManager.getType(for: abbreviation) != .unknown {
            return
        }
        
        // Update or create the unknown abbreviation data
        if var data = unknownAbbreviations[abbreviation] {
            data.occurrenceCount += 1
            data.values.append(value)
            data.contexts.insert(context)
            data.lastSeen = Date()
            unknownAbbreviations[abbreviation] = data
        } else {
            unknownAbbreviations[abbreviation] = UnknownAbbreviationData(
                abbreviation: abbreviation,
                occurrenceCount: 1,
                values: [value],
                contexts: [context],
                firstSeen: Date(),
                lastSeen: Date()
            )
        }
        
        // Save the updated data
        saveUnknownAbbreviations()
        
        // Log the occurrence
        print("Unknown abbreviation tracked: \(abbreviation) with value \(value) in context: \(context)")
        
        // Check if we should suggest adding this abbreviation
        if shouldSuggestAddingAbbreviation(abbreviation) {
            print("Suggestion: Consider adding \(abbreviation) to the known abbreviations list")
            // In a real app, you might want to show a notification or UI element here
        }
    }
    
    /// Gets frequent unknown abbreviations that might be worth adding to the known list
    /// - Parameter minCount: The minimum occurrence count to consider an abbreviation frequent
    /// - Returns: Array of abbreviation data for frequent unknown abbreviations
    func getFrequentUnknownAbbreviations(minCount: Int = 3) -> [UnknownAbbreviationData] {
        return unknownAbbreviations.values
            .filter { $0.occurrenceCount >= minCount }
            .sorted { $0.occurrenceCount > $1.occurrenceCount }
    }
    
    /// Gets all unknown abbreviations
    /// - Returns: Dictionary of unknown abbreviations and their data
    func getAllUnknownAbbreviations() -> [String: UnknownAbbreviationData] {
        return unknownAbbreviations
    }
    
    /// Clears an unknown abbreviation from the tracking system
    /// - Parameter abbreviation: The abbreviation to clear
    func clearUnknownAbbreviation(_ abbreviation: String) {
        unknownAbbreviations.removeValue(forKey: abbreviation)
        saveUnknownAbbreviations()
    }
    
    /// Clears all unknown abbreviations from the tracking system
    func clearAllUnknownAbbreviations() {
        unknownAbbreviations.removeAll()
        saveUnknownAbbreviations()
    }
    
    /// Suggests a likely type for an unknown abbreviation based on its context and values
    /// - Parameter abbreviation: The abbreviation to suggest a type for
    /// - Returns: The suggested abbreviation type, or nil if no suggestion can be made
    func suggestTypeForAbbreviation(_ abbreviation: String) -> AbbreviationManager.AbbreviationType? {
        guard let data = unknownAbbreviations[abbreviation] else {
            return nil
        }
        
        // If it appears mostly in earnings contexts, suggest earning
        if data.contexts.contains("earnings") && !data.contexts.contains("deductions") {
            return .earning
        }
        
        // If it appears mostly in deductions contexts, suggest deduction
        if data.contexts.contains("deductions") && !data.contexts.contains("earnings") {
            return .deduction
        }
        
        // If the average value is positive, suggest earning
        let averageValue = data.values.reduce(0, +) / Double(data.values.count)
        if averageValue > 0 {
            return .earning
        } else {
            return .deduction
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads unknown abbreviations from UserDefaults
    private func loadUnknownAbbreviations() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedAbbreviations = try? JSONDecoder().decode([String: UnknownAbbreviationData].self, from: data) {
            unknownAbbreviations = savedAbbreviations
        }
    }
    
    /// Saves unknown abbreviations to UserDefaults
    private func saveUnknownAbbreviations() {
        if let data = try? JSONEncoder().encode(unknownAbbreviations) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    /// Determines if we should suggest adding an abbreviation to the known list
    /// - Parameter abbreviation: The abbreviation to check
    /// - Returns: True if the abbreviation should be suggested, false otherwise
    private func shouldSuggestAddingAbbreviation(_ abbreviation: String) -> Bool {
        guard let data = unknownAbbreviations[abbreviation] else {
            return false
        }
        
        // Suggest if it has been seen at least 5 times
        if data.occurrenceCount >= 5 {
            return true
        }
        
        // Suggest if it has been seen in at least 3 different payslips
        if data.contexts.count >= 3 {
            return true
        }
        
        return false
    }
}

/// Data structure for tracking unknown abbreviations
struct UnknownAbbreviationData: Codable {
    /// The abbreviation being tracked
    let abbreviation: String
    
    /// Number of times this abbreviation has been seen
    var occurrenceCount: Int
    
    /// Values associated with this abbreviation
    var values: [Double]
    
    /// Contexts in which this abbreviation has been seen
    var contexts: Set<String>
    
    /// Date when this abbreviation was first seen
    let firstSeen: Date
    
    /// Date when this abbreviation was last seen
    var lastSeen: Date
    
    /// Average value of this abbreviation
    var averageValue: Double {
        return values.reduce(0, +) / Double(values.count)
    }
} 