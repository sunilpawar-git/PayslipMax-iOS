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
/// Handles the conversion of internal parsing keys to clean display names while preserving
/// the robust parsing infrastructure that uses technical suffixes for disambiguation.
final class PayslipDisplayNameService: PayslipDisplayNameServiceProtocol {
    
    // MARK: - Display Name Mappings
    
    /// Mapping of internal keys to user-friendly display names
    private let displayNameMappings: [String: String] = [
        // RH12 Components (the main issue being fixed)
        "RH12_EARNINGS": "RH12",
        "RH12_DEDUCTIONS": "RH12",
        
        // Standard Pay Components
        "BPAY": "Basic Pay",
        "Basic Pay": "Basic Pay",
        "DA": "Dearness Allowance",
        "Dearness Allowance": "Dearness Allowance", 
        "MSP": "Military Service Pay",
        "Military Service Pay": "Military Service Pay",
        
        // Transport Allowances
        "TPTA": "Transport Allowance",
        "Transport Allowance": "Transport Allowance",
        "TPTADA": "Transport Allowance DA", 
        "Transport Allowance DA": "Transport Allowance DA",
        
        // Other Risk & Hardship Allowances
        "RH11_EARNINGS": "RH11",
        "RH11_DEDUCTIONS": "RH11",
        "RH13_EARNINGS": "RH13", 
        "RH13_DEDUCTIONS": "RH13",
        "RH21_EARNINGS": "RH21",
        "RH21_DEDUCTIONS": "RH21",
        "RH22_EARNINGS": "RH22",
        "RH22_DEDUCTIONS": "RH22",
        "RH23_EARNINGS": "RH23",
        "RH23_DEDUCTIONS": "RH23",
        "RH31_EARNINGS": "RH31",
        "RH31_DEDUCTIONS": "RH31",
        "RH32_EARNINGS": "RH32",
        "RH32_DEDUCTIONS": "RH32",
        "RH33_EARNINGS": "RH33",
        "RH33_DEDUCTIONS": "RH33",
        
        // Common Deductions
        "DSOP": "DSOP",
        "AGIF": "AGIF",
        "ITAX": "Income Tax",
        "EHCESS": "Education Cess",
        
        // Arrears Components
        "Arrears RSHNA": "Arrears RSHNA",
        "ARR-BPAY": "Arrears Basic Pay",
        "ARR-DA": "Arrears Dearness Allowance",
        "ARR-MSP": "Arrears Military Service Pay"
    ]
    
    // MARK: - Public Interface
    
    func getDisplayName(for internalKey: String) -> String {
        // Check for exact mapping first
        if let displayName = displayNameMappings[internalKey] {
            return displayName
        }
        
        // Handle dynamic arrears patterns
        if internalKey.hasPrefix("Arrears ") {
            let component = String(internalKey.dropFirst(8)) // Remove "Arrears "
            if let baseDisplayName = displayNameMappings[component] {
                return "Arrears \(baseDisplayName)"
            }
        }
        
        // Handle generic _EARNINGS/_DEDUCTIONS suffixes
        if internalKey.hasSuffix("_EARNINGS") {
            let baseKey = String(internalKey.dropLast(9)) // Remove "_EARNINGS"
            return getDisplayName(for: baseKey)
        }
        
        if internalKey.hasSuffix("_DEDUCTIONS") {
            let baseKey = String(internalKey.dropLast(11)) // Remove "_DEDUCTIONS"
            return getDisplayName(for: baseKey)
        }
        
        // Fallback: clean up the internal key for display
        return cleanupInternalKey(internalKey)
    }
    
    func getDisplayEarnings(from earnings: [String: Double]) -> [(displayName: String, value: Double)] {
        return earnings.compactMap { key, value in
            guard value > 0 else { return nil }
            return (displayName: getDisplayName(for: key), value: value)
        }.sorted { $0.displayName < $1.displayName }
    }
    
    func getDisplayDeductions(from deductions: [String: Double]) -> [(displayName: String, value: Double)] {
        return deductions.compactMap { key, value in
            guard value > 0 else { return nil }
            return (displayName: getDisplayName(for: key), value: value)
        }.sorted { $0.displayName < $1.displayName }
    }
    
    // MARK: - Private Helpers
    
    /// Cleans up internal keys that don't have explicit mappings
    /// - Parameter key: The internal key to clean up
    /// - Returns: A more user-friendly version of the key
    private func cleanupInternalKey(_ key: String) -> String {
        // Remove common technical suffixes
        var cleaned = key
            .replacingOccurrences(of: "_EARNINGS", with: "")
            .replacingOccurrences(of: "_DEDUCTIONS", with: "")
            .replacingOccurrences(of: "_", with: " ")
        
        // Capitalize each word
        cleaned = cleaned.split(separator: " ")
            .map { word in
                String(word.prefix(1).uppercased() + word.dropFirst().lowercased())
            }
            .joined(separator: " ")
        
        return cleaned
    }
}
