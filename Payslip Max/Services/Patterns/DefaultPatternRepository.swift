import Foundation

/// Default implementation of the Pattern Repository Protocol
class DefaultPatternRepository: PatternRepositoryProtocol {
    
    // MARK: - Properties
    
    private let userDefaultsKey = "userDefinedPatterns"
    private let fileManager = FileManager.default
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    
    // MARK: - Core Methods
    
    /// Get all patterns - both system and user-defined
    func getAllPatterns() async -> [PatternDefinition] {
        // Get core patterns
        let corePatterns = await getCorePatterns()
        
        // Get user defined patterns
        let userPatterns = await getUserPatterns()
        
        // Combine and return patterns
        return corePatterns + userPatterns
    }
    
    /// Get only system-defined core patterns
    func getCorePatterns() async -> [PatternDefinition] {
        return CorePatternsProvider.getDefaultCorePatterns()
    }
    
    /// Get only user-defined patterns
    func getUserPatterns() async -> [PatternDefinition] {
        do {
            guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
                return []
            }
            
            return try jsonDecoder.decode([PatternDefinition].self, from: data)
        } catch {
            print("Error getting user patterns: \(error)")
            return []
        }
    }
    
    /// Get patterns for a specific category
    func getPatternsForCategory(_ category: PatternCategory) async -> [PatternDefinition] {
        let allPatterns = await getAllPatterns()
        return allPatterns.filter { $0.category == category }
    }
    
    /// Get a specific pattern by ID
    func getPattern(withID id: UUID) async -> PatternDefinition? {
        let allPatterns = await getAllPatterns()
        return allPatterns.first { $0.id == id }
    }
    
    // MARK: - Save Methods
    
    /// Save a new pattern or update an existing one
    func savePattern(_ pattern: PatternDefinition) async throws {
        var userPatterns = await getUserPatterns()
        
        // Check if pattern with same ID exists, if so replace it
        if let index = userPatterns.firstIndex(where: { $0.id == pattern.id }) {
            userPatterns[index] = pattern
        } else {
            userPatterns.append(pattern)
        }
        
        // Save back to UserDefaults
        let data = try jsonEncoder.encode(userPatterns)
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    /// Save multiple patterns at once
    func savePatterns(_ patterns: [PatternDefinition]) async throws {
        var userPatterns = await getUserPatterns()
        
        // Update or add each pattern
        for pattern in patterns {
            if let index = userPatterns.firstIndex(where: { $0.id == pattern.id }) {
                userPatterns[index] = pattern
            } else {
                userPatterns.append(pattern)
            }
        }
        
        // Save back to UserDefaults
        let data = try jsonEncoder.encode(userPatterns)
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    /// Delete a pattern
    func deletePattern(withID id: UUID) async throws {
        var userPatterns = await getUserPatterns()
        userPatterns.removeAll { $0.id == id }
        
        // Save back to UserDefaults
        let data = try jsonEncoder.encode(userPatterns)
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    /// Reset user patterns to defaults
    func resetToDefaults() async throws {
        // Clear user patterns
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Import/Export Methods
    
    func exportPatternsToJSON() async throws -> Data {
        let patterns = await getAllPatterns()
        return try jsonEncoder.encode(patterns)
    }
    
    func importPatternsFromJSON(_ data: Data) async throws -> Int {
        let patterns = try jsonDecoder.decode([PatternDefinition].self, from: data)
        try await savePatterns(patterns)
        return patterns.count
    }
    
    func exportPatterns(to url: URL, includeCore: Bool) async throws -> Int {
        var patterns = await getUserPatterns()
        
        if includeCore {
            let corePatterns = await getCorePatterns()
            patterns.append(contentsOf: corePatterns)
        }
        
        let jsonData = try jsonEncoder.encode(patterns)
        try jsonData.write(to: url)
        
        return patterns.count
    }
    
    func importPatterns(from url: URL) async throws -> Int {
        let data = try Data(contentsOf: url)
        return try await importPatternsFromJSON(data)
    }
} 