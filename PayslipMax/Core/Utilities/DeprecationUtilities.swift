import Foundation

/// Provides standardized utilities for managing API deprecation throughout the PayslipMax codebase.
/// This framework helps maintain backward compatibility while encouraging migration to newer APIs.
public enum DeprecationUtilities {
    
    // MARK: - Version Management
    
    /// Represents a semantic version for API deprecation tracking
    public struct Version: Comparable, Equatable, CustomStringConvertible {
        public let major: Int
        public let minor: Int
        public let patch: Int
        
        public init(major: Int, minor: Int, patch: Int) {
            self.major = major
            self.minor = minor
            self.patch = patch
        }
        
        public var description: String {
            return "\(major).\(minor).\(patch)"
        }
        
        /// The current app version, used as a reference for deprecation messages
        public static let current = Version(major: 2, minor: 0, patch: 0)
        
        public static func < (lhs: Version, rhs: Version) -> Bool {
            if lhs.major != rhs.major {
                return lhs.major < rhs.major
            } else if lhs.minor != rhs.minor {
                return lhs.minor < rhs.minor
            } else {
                return lhs.patch < rhs.patch
            }
        }
    }
    
    // MARK: - Message Formatting
    
    /// Generates a standardized deprecation message
    /// - Parameters:
    ///   - message: The core deprecation message
    ///   - replacedBy: The new API that should be used instead (optional)
    ///   - deprecatedIn: The version when this API was deprecated
    ///   - removedIn: The planned version when this API will be removed
    /// - Returns: A formatted deprecation message
    public static func standardDeprecationMessage(
        message: String,
        replacedBy: String? = nil,
        deprecatedIn: Version,
        removedIn: Version? = nil
    ) -> String {
        var result = "DEPRECATED: \(message)"
        
        if let replacedBy = replacedBy {
            result += " Use '\(replacedBy)' instead."
        }
        
        result += " (Deprecated in \(deprecatedIn)"
        
        if let removedIn = removedIn {
            result += ", will be removed in \(removedIn)"
        }
        
        result += ")"
        
        return result
    }
    
    // MARK: - Documentation Templates
    
    /// Returns a standardized documentation template for a deprecated method
    /// - Parameters:
    ///   - description: The method description
    ///   - replacedBy: The replacement method
    ///   - deprecatedIn: Version when deprecated
    ///   - removedIn: Version when to be removed
    /// - Returns: A documentation string
    public static func documentationTemplate(
        description: String,
        replacedBy: String? = nil,
        deprecatedIn: Version,
        removedIn: Version? = nil
    ) -> String {
        var template = """
        /// \(description)
        ///
        /// - Warning: Deprecated in version \(deprecatedIn).
        """
        
        if let replacedBy = replacedBy {
            template += "\n/// - Note: Use `\(replacedBy)` instead."
        }
        
        if let removedIn = removedIn {
            template += "\n/// - Note: Will be removed in version \(removedIn)."
        }
        
        return template
    }
} 