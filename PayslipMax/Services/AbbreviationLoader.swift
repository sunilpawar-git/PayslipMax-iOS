import Foundation

/// Errors that can occur when loading abbreviations
enum AbbreviationLoaderError: Error {
    /// The abbreviation JSON file could not be found in the application bundle.
    case fileNotFound
    /// The JSON data is malformed or could not be parsed.
    case invalidJSON
    /// The data read from the file is invalid or corrupted.
    case invalidData
    /// The version specified in the JSON file is unsupported.
    case invalidVersion
    /// An invalid category was encountered during parsing (should not happen with enum).
    case invalidCategory
}

/// Service responsible for loading military abbreviations from a bundled JSON file.
/// Includes caching logic to avoid frequent reloading.
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
    
    /// Initializes the loader.
    /// Locates the `military_abbreviations.json` file within the main application bundle.
    /// - Note: If the JSON file is missing, loaders will throw `fileNotFound` instead of terminating the app.
    init() {
        if let url = Bundle.main.url(forResource: "military_abbreviations", withExtension: "json") {
            self.jsonURL = url
        } else {
            // Set a placeholder URL; methods will throw if accessed without a real file
            self.jsonURL = URL(fileURLWithPath: "/dev/null")
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads abbreviations from the JSON file, utilizing an in-memory cache.
    /// The cache is considered valid for 1 hour (3600 seconds).
    /// - Returns: An array of `PayslipAbbreviation` objects.
    /// - Throws: `AbbreviationLoaderError` if the file cannot be found, read, parsed, or if the version is invalid.
    func loadAbbreviations() throws -> [PayslipAbbreviation] {
        // Check if we have cached data that's less than an hour old
        if let cached = cachedAbbreviations,
           let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < 3600 {
            return cached
        }
        
        // Load and parse the JSON file
        guard jsonURL.isFileURL, FileManager.default.fileExists(atPath: jsonURL.path) else {
            throw AbbreviationLoaderError.fileNotFound
        }
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
    
    /// Loads component mappings from the JSON file, utilizing the same cache as abbreviations.
    /// If the cache is invalid, it triggers a reload of the abbreviations data first.
    /// - Returns: A dictionary mapping abbreviation variations to their standardized component names.
    /// - Throws: `AbbreviationLoaderError` if the underlying `loadAbbreviations` call fails.
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
    
    /// Forces a reload of the abbreviation data from the JSON file, bypassing the cache.
    /// Clears the existing cache before reloading.
    /// - Returns: An array of `PayslipAbbreviation` objects freshly loaded from the file.
    /// - Throws: `AbbreviationLoaderError` if the file cannot be found, read, parsed, or if the version is invalid.
    func forceReload() throws -> [PayslipAbbreviation] {
        cachedAbbreviations = nil
        cachedComponentMappings = nil
        lastLoadTime = nil
        return try loadAbbreviations()
    }
}

// MARK: - Private Types

/// Internal structure for decoding the JSON data from `military_abbreviations.json`.
private struct AbbreviationData: Codable {
    /// The version number of the abbreviation data format.
    let version: Int
    /// The list of abbreviation definitions.
    let abbreviations: [PayslipAbbreviation]
    /// Mappings from various text representations to standardized component keys.
    let componentMappings: [String: String]
} 