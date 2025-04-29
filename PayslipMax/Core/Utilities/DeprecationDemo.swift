import Foundation

/// Demo class that showcases how to use the deprecation utilities for API evolution
public class DeprecationDemo {
    
    // MARK: - Method Deprecation Example
    
    /// Original method that is now deprecated
    /// - Parameter text: The text to process
    /// - Returns: Processed text
    @available(*, deprecated, message: "Use processTextV2 instead")
    public func processText(_ text: String) -> String {
        // Log the deprecation when the method is called
        Self.logDeprecation(
            for: "processText",
            replacedBy: "processTextV2",
            deprecatedIn: DeprecationUtilities.Version(major: 1, minor: 5, patch: 0),
            removedIn: DeprecationUtilities.Version(major: 2, minor: 5, patch: 0)
        )
        
        // Call the new method to maintain functionality
        return processTextV2(text, options: [:])
    }
    
    /// New version of the processText method with more options
    /// - Parameters:
    ///   - text: The text to process
    ///   - options: Additional processing options
    /// - Returns: Processed text
    public func processTextV2(_ text: String, options: [String: Any]) -> String {
        // New implementation
        return text.uppercased()
    }
    
    // MARK: - Property Deprecation Example
    
    /// Legacy property (deprecated)
    @available(*, deprecated, message: "Use configuration instead")
    public var settings: [String: Any] {
        // Log the deprecation
        Self.logDeprecation(
            for: "settings",
            replacedBy: "configuration",
            deprecatedIn: DeprecationUtilities.Version(major: 1, minor: 8, patch: 0)
        )
        
        // Map to the new property
        return configuration
    }
    
    /// New property that replaces the settings property
    public var configuration: [String: Any] = [:]
    
    // MARK: - Enum Deprecation Example
    
    /// Original processing mode (now deprecated)
    @available(*, deprecated, message: "Use ProcessingMode instead")
    public enum LegacyMode {
        case fast
        case accurate
    }
    
    /// New processing mode enum with more options
    public enum ProcessingMode {
        case fast
        case balanced
        case accurate
        case custom(options: [String: Any])
        
        /// Convert from legacy mode
        @available(*, deprecated, message: "LegacyMode conversion will be removed in a future version")
        public init(from legacyMode: LegacyMode) {
            // Log the deprecation
            DeprecationDemo.logDeprecation(
                for: "LegacyMode",
                replacedBy: "ProcessingMode",
                deprecatedIn: DeprecationUtilities.Version(major: 1, minor: 9, patch: 0)
            )
            
            switch legacyMode {
            case .fast:
                self = .fast
            case .accurate:
                self = .accurate
            }
        }
    }
}

// Make our demo class support deprecation utilities
extension DeprecationDemo: DeprecationSupporting {} 