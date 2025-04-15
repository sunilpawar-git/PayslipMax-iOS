import Foundation

/// Errors that can occur when loading abbreviations
enum AbbreviationLoaderError: Error {
    case fileNotFound
    case invalidJSON
    case invalidData
    case invalidVersion
    case invalidCategory
}

/// Service responsible for loading military abbreviations from JSON
final class AbbreviationLoader {
    // MARK: - Properties
    
    /// The URL of the JSON file containing abbreviations
    private let jsonURL: URL
    
    /// Cache of loaded abbreviations
    private var cachedAbbreviations: [PayslipAbbreviation]?
    
    /// Cache of component mappings
    private var cachedComponentMappings: [String: String]?
    
    /// The last time the data was loaded
    private var lastLoadTime: Date?
    
    // MARK: - Initialization
    
    init() {
        guard let url = Bundle.main.url(forResource: "military_abbreviations", withExtension: "json") else {
            fatalError("military_abbreviations.json not found in bundle")
        }
        self.jsonURL = url
    }
    
    // MARK: - Public Methods
    
    /// Loads abbreviations from the JSON file
    /// - Returns: Array of PayslipAbbreviation objects
    /// - Throws: AbbreviationLoaderError if loading fails
    func loadAbbreviations() throws -> [PayslipAbbreviation] {
        // Check if we have cached data that's less than an hour old
        if let cached = cachedAbbreviations,
           let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < 3600 {
            return cached
        }
        
        // Load and parse the JSON file
        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        
        // Decode the JSON structure
        let json = try decoder.decode(AbbreviationData.self, from: data)
        
        // Validate version
        guard json.version >= 1 else {
            throw AbbreviationLoaderError.invalidVersion
        }
        
        // Cache the loaded data
        cachedAbbreviations = json.abbreviations
        cachedComponentMappings = json.componentMappings
        lastLoadTime = Date()
        
        return json.abbreviations
    }
    
    /// Loads component mappings from the JSON file
    /// - Returns: Dictionary mapping variations to standardized names
    /// - Throws: AbbreviationLoaderError if loading fails
    func loadComponentMappings() throws -> [String: String] {
        // Check cache first
        if let cached = cachedComponentMappings,
           let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < 3600 {
            return cached
        }
        
        // If not cached, load abbreviations which will also cache the mappings
        _ = try loadAbbreviations()
        
        return cachedComponentMappings ?? [:]
    }
    
    /// Forces a reload of the data, ignoring the cache
    /// - Returns: Array of PayslipAbbreviation objects
    /// - Throws: AbbreviationLoaderError if loading fails
    func forceReload() throws -> [PayslipAbbreviation] {
        cachedAbbreviations = nil
        cachedComponentMappings = nil
        lastLoadTime = nil
        return try loadAbbreviations()
    }
}

// MARK: - Private Types

/// Internal structure for decoding the JSON data
private struct AbbreviationData: Codable {
    let version: Int
    let abbreviations: [PayslipAbbreviation]
    let componentMappings: [String: String]
} 