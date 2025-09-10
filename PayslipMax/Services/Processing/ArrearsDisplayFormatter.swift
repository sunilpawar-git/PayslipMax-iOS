//
//  ArrearsDisplayFormatter.swift
//  PayslipMax
//
//  Created for Phase 3: Universal Arrears System - Display Formatting Component
//  Extracted to maintain <300 line limit per architectural constraints
//

import Foundation

/// Service responsible for formatting arrears component names for display
/// Extracted component to maintain single responsibility and file size limits
class ArrearsDisplayFormatter {
    
    // MARK: - Public Methods
    
    /// Formats arrears component names for display in payslip
    /// Converts technical names like "ARR-BPAY" to user-friendly "Arrears Basic Pay"
    /// - Parameter component: The arrears component identifier
    /// - Returns: Formatted display name
    func formatArrearsDisplayName(_ component: String) -> String {
        let baseComponent = extractBaseComponent(from: component)
        
        let displayNames = getDisplayNameMappings()
        return displayNames[baseComponent] ?? "Arrears \(baseComponent)"
    }
    
    /// Extracts base component from arrears identifier
    /// Handles various formats: ARR-BPAY, ARREARS BPAY, etc.
    /// - Parameter component: The arrears component identifier
    /// - Returns: Base component name
    func extractBaseComponent(from component: String) -> String {
        let uppercaseComponent = component.uppercased()
        
        // Remove ARR- prefix
        if uppercaseComponent.hasPrefix("ARR-") {
            return String(uppercaseComponent.dropFirst(4))
        }
        
        // Remove ARREARS prefix with flexible spacing
        if uppercaseComponent.hasPrefix("ARREARS") {
            return uppercaseComponent
                .replacingOccurrences(of: "ARREARS", with: "")
                .trimmingCharacters(in: .whitespaces)
        }
        
        return uppercaseComponent
    }
    
    // MARK: - Private Methods
    
    /// Gets comprehensive mapping of component codes to display names
    /// Covers all known military pay codes with user-friendly names
    private func getDisplayNameMappings() -> [String: String] {
        return [
            // Basic pay components
            "BPAY": "Arrears Basic Pay",
            "BASICPAY": "Arrears Basic Pay",
            "MSP": "Arrears Military Service Pay",
            
            // Allowances
            "DA": "Arrears Dearness Allowance",
            "HRA": "Arrears House Rent Allowance",
            "TPTA": "Arrears Transport Allowance",
            "TPTADA": "Arrears Transport Allowance DA",
            "CEA": "Arrears Children Education Allowance",
            "CCA": "Arrears City Compensatory Allowance",
            "RSHNA": "Arrears Rashtriya Sainik Na Allowance",
            
            // Risk and Hardship allowances
            "RH11": "Arrears Risk & Hardship Level 11",
            "RH12": "Arrears Risk & Hardship Level 12",
            "RH13": "Arrears Risk & Hardship Level 13",
            "RH21": "Arrears Risk & Hardship Level 21",
            "RH22": "Arrears Risk & Hardship Level 22",
            "RH23": "Arrears Risk & Hardship Level 23",
            "RH31": "Arrears Risk & Hardship Level 31",
            "RH32": "Arrears Risk & Hardship Level 32",
            "RH33": "Arrears Risk & Hardship Level 33",
            
            // Special allowances
            "SPLALLOW": "Arrears Special Allowance",
            "FIELDALLOW": "Arrears Field Allowance",
            "TECPAY": "Arrears Technical Pay",
            "FLYALLOW": "Arrears Flying Allowance",
            "SUBALLOW": "Arrears Submarine Allowance",
            
            // Deduction-based arrears (rare but possible)
            "DSOP": "Arrears DSOP Adjustment",
            "AGIF": "Arrears AGIF Adjustment",
            "AFPF": "Arrears Air Force Provident Fund",
            "ITAX": "Arrears Income Tax Adjustment",
            "IT": "Arrears Income Tax Adjustment",
            "EHCESS": "Arrears Education Health Cess",
            "PF": "Arrears Provident Fund",
            "GPF": "Arrears General Provident Fund",
            
            // Other components
            "CONVALLOW": "Arrears Conveyance Allowance",
            "WASHALLOW": "Arrears Washing Allowance",
            "KIALLOW": "Arrears Kit Allowance",
            "HAIRCUTALLOW": "Arrears Haircut Allowance",
            "UNIFORM": "Arrears Uniform Allowance",
            "MESS": "Arrears Mess Allowance",
            "CLUB": "Arrears Club Allowance",
            "CANTEEN": "Arrears Canteen Allowance",
            "MEDICAL": "Arrears Medical Allowance",
            "FAMILY": "Arrears Family Allowance",
            "EDUCATION": "Arrears Education Allowance",
            "TRANSPORT": "Arrears Transport Allowance",
            "FUEL": "Arrears Fuel Allowance",
            "MAINTENANCE": "Arrears Maintenance Allowance",
            "INSURANCE": "Arrears Insurance Allowance"
        ]
    }
}
