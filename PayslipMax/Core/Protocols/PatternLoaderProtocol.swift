import Foundation

/// Protocol defining the interface for pattern configuration loading services.
///
/// This protocol abstracts pattern loading functionality to enable dependency
/// injection, testing, and different sources of pattern configurations.
/// It separates the concern of loading patterns from applying them.
///
/// ## Usage
/// Implementations can load patterns from:
/// - Static configuration files
/// - Dynamic databases
/// - Remote services
/// - In-memory configurations for testing
protocol PatternLoaderProtocol {
    
    /// Loads the complete pattern configuration.
    ///
    /// This method is responsible for loading all patterns from the configured
    /// source and returning them as a structured configuration object.
    ///
    /// - Returns: A complete pattern configuration ready for use by pattern matchers
    func loadPatternConfiguration() -> PatternConfiguration
    
    /// Reloads the pattern configuration from the source.
    ///
    /// This method allows for dynamic reloading of pattern configurations,
    /// useful for runtime updates or configuration changes.
    ///
    /// - Returns: The updated pattern configuration
    func reloadPatternConfiguration() -> PatternConfiguration
    
    /// Validates that the pattern configuration is correctly formed.
    ///
    /// This method checks the loaded configuration for consistency,
    /// completeness, and validity of pattern definitions.
    ///
    /// - Parameter configuration: The configuration to validate
    /// - Returns: True if the configuration is valid, false otherwise
    func validateConfiguration(_ configuration: PatternConfiguration) -> Bool
}
