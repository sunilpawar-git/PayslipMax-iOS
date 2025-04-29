import Foundation

/// Helper protocol for adding deprecation functionality to any type
/// Used to standardize how deprecated APIs are marked and documented
public protocol DeprecationSupporting {}

extension DeprecationSupporting {
    
    /// Creates a standardized deprecation warning message
    /// - Parameters:
    ///   - item: The API element being deprecated (method, property, etc.)
    ///   - replacedBy: The new API that should be used instead (optional)
    ///   - deprecatedIn: The version when this API was deprecated
    ///   - removedIn: The planned version when this API will be removed
    /// - Returns: A formatted deprecation message
    public static func deprecationMessage(
        for item: String,
        replacedBy: String? = nil,
        deprecatedIn: DeprecationUtilities.Version,
        removedIn: DeprecationUtilities.Version? = nil
    ) -> String {
        return DeprecationUtilities.standardDeprecationMessage(
            message: "\(Self.self).\(item) is deprecated.",
            replacedBy: replacedBy,
            deprecatedIn: deprecatedIn,
            removedIn: removedIn
        )
    }
    
    /// Logs a deprecation warning to the console
    /// - Parameters:
    ///   - item: The API element being deprecated (method, property, etc.)
    ///   - replacedBy: The new API that should be used instead (optional)
    ///   - deprecatedIn: The version when this API was deprecated
    ///   - removedIn: The planned version when this API will be removed
    public static func logDeprecation(
        for item: String,
        replacedBy: String? = nil,
        deprecatedIn: DeprecationUtilities.Version = DeprecationUtilities.Version.current,
        removedIn: DeprecationUtilities.Version? = nil,
        file: String = #file,
        line: Int = #line
    ) {
        let message = deprecationMessage(
            for: item,
            replacedBy: replacedBy,
            deprecatedIn: deprecatedIn,
            removedIn: removedIn
        )
        print("⚠️ \(message) - called from \(file):\(line)")
    }
}

// Make standard types support deprecation helpers
extension NSObject: DeprecationSupporting {}
extension String: DeprecationSupporting {}
extension Array: DeprecationSupporting {}
extension Dictionary: DeprecationSupporting {}
extension Set: DeprecationSupporting {} 