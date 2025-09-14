import Foundation

// MARK: - Data Extensions

extension Data {
    /// Appends a string to the data.
    ///
    /// - Parameter string: The string to append.
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
