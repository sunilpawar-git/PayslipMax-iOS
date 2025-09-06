import Foundation

/// Military-specific patterns and classification logic
struct MilitaryPatterns {
    
    /// Military-specific classification patterns
    static let militaryPatterns: [String: ElementType] = [
        "BPAY": .label,
        "DA": .label,
        "MSP": .label,
        "RH12": .label,
        "TPTA": .label,
        "TPTADA": .label,
        "DSOP": .label,
        "AGIF": .label,
        "ITAX": .label,
        "EHCESS": .label,
        "HRA": .label,
        "CCA": .label
    ]
    
    /// Patterns for identifying labels (field names)
    static let labelPatterns: [String] = [
        // Military payslip patterns
        "BPAY", "DA", "MSP", "RH12", "TPTA", "TPTADA",
        "DSOP", "AGIF", "ITAX", "EHCESS", "HRA", "CCA",
        "WASHING", "KIT", "FIELD", "UNIFORM",
        
        // Common payslip labels
        "Name", "Rank", "Service No", "Account No", "PAN",
        "Basic Pay", "Grade Pay", "Dearness Allowance",
        "House Rent Allowance", "Transport Allowance",
        "Medical Allowance", "Special Allowance",
        
        // General field indicators
        "Total", "Gross", "Net", "Deductions", "Earnings",
        "Month", "Year", "Period", "Location", "Unit",
        
        // Field name patterns (ending with colon)
        #"[A-Z][A-Za-z\s]+:"#,
        
        // Abbreviated patterns
        #"[A-Z]{2,6}(\s*\([A-Z0-9]+\))?"#
    ]
    
    /// Patterns for identifying numeric values
    static let valuePatterns: [String] = [
        // Currency amounts
        #"₹?\s*[\d,]+\.?\d*"#,
        #"\$\s*[\d,]+\.?\d*"#,
        
        // Plain numbers
        #"^\d{1,3}(,\d{3})*(\.\d{2})?$"#,
        #"^\d+\.?\d*$"#,
        
        // Account numbers
        #"^\d{10,16}$"#,
        
        // Service numbers
        #"^[A-Z]{2,3}[\d/]+$"#,
        
        // PAN numbers
        #"^[A-Z]{5}\d{4}[A-Z]$"#
    ]
    
    /// Patterns for identifying headers
    static let headerPatterns: [String] = [
        "PAY AND ALLOWANCES",
        "STATEMENT OF PAY",
        "EARNINGS",
        "DEDUCTIONS",
        "DETAILS",
        "ALLOWANCES",
        "CONTRIBUTION",
        "MINISTRY OF DEFENCE",
        "ARMY",
        "NAVY",
        "AIR FORCE",
        
        // Header-like patterns (all caps, multiple words)
        #"^[A-Z\s]{5,}$"#
    ]
}
