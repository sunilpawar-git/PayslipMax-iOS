import Foundation

/// Service responsible for converting internal parsing keys to user-friendly display names
///
/// This service maintains the separation between internal data storage keys (which may include
/// technical suffixes for disambiguation) and clean, user-facing display names.
///
/// ## Architecture Compliance
/// - Follows MVVM pattern by providing presentation logic separate from business logic
/// - Supports Single Source of Truth by centralizing display name mapping
/// - Maintains backward compatibility with existing parsing infrastructure
protocol PayslipDisplayNameServiceProtocol {
    /// Converts internal data key to user-friendly display name
    /// - Parameter internalKey: The key used internally for data storage/parsing
    /// - Returns: Clean, user-friendly display name
    func getDisplayName(for internalKey: String) -> String

    /// Gets clean breakdown of earnings with display names
    /// - Parameter earnings: Raw earnings dictionary with internal keys
    /// - Returns: Array of display-ready items
    func getDisplayEarnings(from earnings: [String: Double]) -> [(displayName: String, value: Double)]

    /// Gets clean breakdown of deductions with display names
    /// - Parameter deductions: Raw deductions dictionary with internal keys
    /// - Returns: Array of display-ready items
    func getDisplayDeductions(from deductions: [String: Double]) -> [(displayName: String, value: Double)]
}

/// Implementation of PayslipDisplayNameService
///
/// Enhanced for Phase 4: Universal Dual-Section Implementation
/// Handles conversion of internal parsing keys to clean display names for ALL 243+ paycodes
/// Supports universal dual-section processing while maintaining clean user presentation
///
/// Phase 2C: Converted to dual-mode pattern supporting both singleton and DI
final class PayslipDisplayNameService: PayslipDisplayNameServiceProtocol {

    // MARK: - Phase 2C: Singleton Instance (Backward Compatibility)
    static let shared = PayslipDisplayNameService()

    // MARK: - Dependencies

    /// Arrears display formatter for enhanced arrears presentation
    private let arrearsFormatter: ArrearsDisplayFormatter

    // MARK: - Initialization

    /// Phase 2C: Public initializer supporting dependency injection
    /// - Parameter arrearsFormatter: Formatter for arrears component display names
    init(arrearsFormatter: ArrearsDisplayFormatter = ArrearsDisplayFormatter()) {
        self.arrearsFormatter = arrearsFormatter
    }

    // MARK: - Public Interface

    func getDisplayName(for internalKey: String) -> String {
        // Check for exact mapping in comprehensive constants first
        if let displayName = PayslipDisplayNameConstants.getDisplayName(for: internalKey) {
            return displayName
        }

        // Handle arrears patterns with enhanced formatter
        if internalKey.hasPrefix("ARR-") || internalKey.hasPrefix("Arrears ") {
            return arrearsFormatter.formatArrearsDisplayName(internalKey)
        }

        // Handle universal dual-section suffixes for ALL allowances
        if internalKey.hasSuffix("_EARNINGS") {
            let baseKey = String(internalKey.dropLast(9)) // Remove "_EARNINGS"

            // Check if base key has explicit mapping
            if let baseDisplayName = PayslipDisplayNameConstants.getDisplayName(for: baseKey) {
                return baseDisplayName
            }

            // Recursively get display name for base key
            return getDisplayName(for: baseKey)
        }

        if internalKey.hasSuffix("_DEDUCTIONS") {
            let baseKey = String(internalKey.dropLast(11)) // Remove "_DEDUCTIONS"

            // Check if base key has explicit mapping
            if let baseDisplayName = PayslipDisplayNameConstants.getDisplayName(for: baseKey) {
                return baseDisplayName
            }

            // Recursively get display name for base key
            return getDisplayName(for: baseKey)
        }

        // Enhanced dynamic arrears patterns (for unknown codes)
        if internalKey.hasPrefix("Arrears ") {
            let component = String(internalKey.dropFirst(8)) // Remove "Arrears "
            if let baseDisplayName = PayslipDisplayNameConstants.getDisplayName(for: component) {
                return "Arrears \(baseDisplayName)"
            }
            return "Arrears \(cleanupInternalKey(component))"
        }

        // Fallback: clean up the internal key for display
        return cleanupInternalKey(internalKey)
    }

    func getDisplayEarnings(from earnings: [String: Double]) -> [(displayName: String, value: Double)] {
        return earnings.compactMap { key, value -> (displayName: String, value: Double)? in
            guard value > 0 else { return nil }
            let displayName = getDisplayName(for: key)
            return (displayName: displayName, value: value)
        }
        .sorted { $0.value > $1.value }  // Descending by value (highest first)
    }

    func getDisplayDeductions(from deductions: [String: Double]) -> [(displayName: String, value: Double)] {
        return deductions.compactMap { key, value -> (displayName: String, value: Double)? in
            guard value > 0 else { return nil }
            let displayName = getDisplayName(for: key)
            return (displayName: displayName, value: value)
        }
        .sorted { $0.value > $1.value }  // Descending by value (highest first)
    }

    // MARK: - Enhanced Universal Dual-Section Support

    /// Gets consolidated display items from both earnings and deductions with dual-section awareness
    /// Combines dual-section components (e.g., HRA_EARNINGS + HRA_DEDUCTIONS) into single display items
    /// - Parameters:
    ///   - earnings: Raw earnings dictionary
    ///   - deductions: Raw deductions dictionary
    /// - Returns: Consolidated display items with net values for dual-section components
    func getConsolidatedDisplayItems(
        from earnings: [String: Double],
        and deductions: [String: Double]
    ) -> [(displayName: String, earningsValue: Double, deductionsValue: Double, netValue: Double)] {

        var consolidatedItems: [String: (earnings: Double, deductions: Double)] = [:]

        // Process earnings
        for (key, value) in earnings where value > 0 {
            let displayName = getDisplayName(for: key)
            consolidatedItems[displayName, default: (0, 0)].earnings += value
        }

        // Process deductions
        for (key, value) in deductions where value > 0 {
            let displayName = getDisplayName(for: key)
            consolidatedItems[displayName, default: (0, 0)].deductions += value
        }

        // Convert to result format
        return consolidatedItems.map { displayName, values in
            (
                displayName: displayName,
                earningsValue: values.earnings,
                deductionsValue: values.deductions,
                netValue: values.earnings - values.deductions
            )
        }.sorted { $0.displayName < $1.displayName }
    }

    /// Checks if a display name represents a dual-section component
    /// - Parameter displayName: The display name to check
    /// - Returns: True if this component can appear in both sections
    func isDualSectionComponent(_ displayName: String) -> Bool {
        // Check if we have both _EARNINGS and _DEDUCTIONS variants in our mappings
        let mappings = PayslipDisplayNameConstants.displayNameMappings

        return mappings.values.filter { $0 == displayName }.count > 1 ||
               displayName.contains("Risk Allowance") ||
               displayName.contains("Arrears") ||
               ["House Rent Allowance", "Children Education Allowance", "Dearness Allowance",
                "Transport Allowance", "Siachen Allowance", "Ration Allowance"].contains(displayName)
    }

    // MARK: - Private Helpers

    /// Cleans up internal keys that don't have explicit mappings
    /// Enhanced for universal dual-section support
    /// - Parameter key: The internal key to clean up
    /// - Returns: A more user-friendly version of the key
    private func cleanupInternalKey(_ key: String) -> String {
        // Remove common technical suffixes
        var cleaned = key
            .replacingOccurrences(of: "_EARNINGS", with: "")
            .replacingOccurrences(of: "_DEDUCTIONS", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "ARR-", with: "")

        // Handle specific military abbreviation patterns
        if cleaned.count <= 6 && cleaned.allSatisfy({ $0.isUppercase || $0.isNumber }) {
            // Keep short military codes uppercase (e.g., HRA, CEA, RH12)
            return cleaned
        }

        // Capitalize each word for longer descriptions
        cleaned = cleaned.split(separator: " ")
            .map { word in
                String(word.prefix(1).uppercased() + word.dropFirst().lowercased())
            }
            .joined(separator: " ")

        return cleaned
    }
}
