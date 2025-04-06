import Foundation

/// Protocol defining how pattern definitions are stored and retrieved
protocol PatternRepositoryProtocol {
    /// Get all available patterns
    func getAllPatterns() async -> [PatternDefinition]
    
    /// Get only system-defined core patterns
    func getCorePatterns() async -> [PatternDefinition]
    
    /// Get only user-defined patterns
    func getUserPatterns() async -> [PatternDefinition]
    
    /// Get patterns for a specific category
    func getPatternsForCategory(_ category: PatternCategory) async -> [PatternDefinition]
    
    /// Get a specific pattern by ID
    func getPattern(withID id: UUID) async -> PatternDefinition?
    
    /// Save a new pattern or update an existing one
    func savePattern(_ pattern: PatternDefinition) async throws
    
    /// Delete a pattern
    func deletePattern(withID id: UUID) async throws
    
    /// Reset user patterns to defaults
    func resetToDefaults() async throws
    
    /// Export patterns to JSON data
    func exportPatternsToJSON() async throws -> Data
    
    /// Import patterns from JSON data
    func importPatternsFromJSON(_ data: Data) async throws -> Int
    
    /// Export patterns to a file
    func exportPatterns(to url: URL, includeCore: Bool) async throws -> Int
    
    /// Import patterns from a file
    func importPatterns(from url: URL) async throws -> Int
} 