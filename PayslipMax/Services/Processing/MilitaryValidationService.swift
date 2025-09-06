import Foundation
import CoreGraphics

/// Service responsible for military payslip validation and business rules
/// Extracted component for single responsibility - military-specific validation logic
final class MilitaryValidationService {
    
    // MARK: - Public Interface
    
    /// Validates spatial relationship for military payslip pairs
    /// - Parameters:
    ///   - label: Label element
    ///   - value: Value element
    ///   - code: Military component code
    /// - Returns: True if the pair is valid for military payslips
    func isValidMilitaryPair(
        label: PositionalElement,
        value: PositionalElement,
        code: String
    ) -> Bool {
        
        // Check horizontal alignment (same row)
        let verticalDistance = abs(label.center.y - value.center.y)
        guard verticalDistance <= 15.0 else { return false }
        
        // Check that value is to the right of label
        guard value.bounds.minX > label.bounds.maxX else { return false }
        
        // Check reasonable horizontal distance
        let horizontalDistance = value.bounds.minX - label.bounds.maxX
        guard horizontalDistance >= 5.0 && horizontalDistance <= 200.0 else { return false }
        
        // Additional validation based on military payslip structure
        return validateMilitaryComponentPosition(code: code, label: label, value: value)
    }
    
    /// Validates component position based on military payslip structure
    /// - Parameters:
    ///   - code: Military component code
    ///   - label: Label element
    ///   - value: Value element
    /// - Returns: True if position is valid for the component type
    func validateMilitaryComponentPosition(
        code: String,
        label: PositionalElement,
        value: PositionalElement
    ) -> Bool {
        
        // Earnings components typically appear in upper portion
        let earningsComponents = ["BPAY", "DA", "MSP", "RH12", "TPTA", "TPTADA"]
        let deductionsComponents = ["DSOP", "AGIF", "ITAX", "EHCESS"]
        
        if earningsComponents.contains(code) {
            // Earnings should be in upper 60% of document
            return label.center.y < 400.0 // Approximate threshold
        } else if deductionsComponents.contains(code) {
            // Deductions can be anywhere but typically in lower sections
            return true // More flexible for deductions
        }
        
        return true
    }
    
    /// Applies military-specific validation rules to extracted data
    /// - Parameter data: Raw extracted financial data
    /// - Returns: Validated financial data with invalid entries removed
    func applyMilitaryValidation(to data: [String: Double]) -> [String: Double] {
        var validatedData = data
        
        // Remove obviously invalid values (e.g., too large for military pay)
        let maxReasonableAmount: Double = 500000 // 5 lakh max for any component
        
        for (key, value) in validatedData {
            if value > maxReasonableAmount {
                print("[MilitaryValidationService] Removing invalid amount for \(key): \(value) (exceeds reasonable limit)")
                validatedData.removeValue(forKey: key)
            }
        }
        
        // Apply military-specific business rules
        if let basicPay = validatedData["BPAY"],
           let da = validatedData["DA"] {
            // DA should typically be 17-50% of basic pay for military personnel
            let daRatio = da / basicPay
            if daRatio < 0.1 || daRatio > 0.6 {
                print("[MilitaryValidationService] Warning: DA ratio \(daRatio) seems unusual for military payslip")
            }
        }
        
        // Validate other component relationships
        validatedData = validateComponentRelationships(in: validatedData)
        
        return validatedData
    }
    
    /// Identifies military pay component from text
    /// - Parameter text: Text to analyze
    /// - Returns: Military component code if identified, nil otherwise
    func identifyMilitaryComponent(from text: String) -> String? {
        let militaryComponents = [
            "BPAY": ["BPAY", "BASIC", "PAY"],
            "DA": ["DA", "DEARNESS"],
            "MSP": ["MSP", "MEDICAL"],
            "RH12": ["RH12", "HOUSE", "RENT"],
            "TPTA": ["TPTA", "TRANSPORT"],
            "TPTADA": ["TPTADA", "TRANSPORT"],
            "DSOP": ["DSOP", "PROVIDENT"],
            "AGIF": ["AGIF", "INSURANCE"],
            "ITAX": ["ITAX", "INCOME", "TAX"],
            "EHCESS": ["EHCESS", "CESS"]
        ]
        
        for (code, keywords) in militaryComponents {
            if keywords.allSatisfy({ text.contains($0) }) {
                return code
            }
        }
        
        return nil
    }
    
    /// Extracts financial amount from text
    /// - Parameter text: Text to extract amount from
    /// - Returns: Extracted amount or nil if not found
    func extractFinancialAmount(from text: String) -> Double? {
        // Remove common currency symbols and clean up
        let cleanText = text
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract numeric value
        let numberPattern = "([0-9]+)"
        do {
            let regex = try NSRegularExpression(pattern: numberPattern)
            let nsString = cleanText as NSString
            let matches = regex.matches(in: cleanText, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first {
                let numberRange = match.range(at: 1)
                let numberString = nsString.substring(with: numberRange)
                return Double(numberString)
            }
        } catch {
            print("[MilitaryValidationService] Error extracting amount: \(error)")
        }
        
        return nil
    }
    
    // MARK: - Private Implementation
    
    /// Validates relationships between different components
    private func validateComponentRelationships(in data: [String: Double]) -> [String: Double] {
        var validatedData = data
        
        // Check for reasonable MSP (Medical Service Pay) relative to basic pay
        if let basicPay = validatedData["BPAY"],
           let msp = validatedData["MSP"] {
            let mspRatio = msp / basicPay
            if mspRatio > 0.3 { // MSP shouldn't exceed 30% of basic pay typically
                print("[MilitaryValidationService] Warning: MSP ratio \(mspRatio) seems high for military payslip")
            }
        }
        
        // Check for reasonable transport allowances
        if let tpta = validatedData["TPTA"],
           let tptada = validatedData["TPTADA"] {
            // TPTADA is usually much smaller than TPTA
            if tptada > tpta {
                print("[MilitaryValidationService] Warning: TPTADA (\(tptada)) is greater than TPTA (\(tpta))")
            }
        }
        
        // Check for reasonable deduction amounts
        if let basicPay = validatedData["BPAY"] {
            let deductionComponents = ["DSOP", "AGIF", "ITAX", "EHCESS"]
            
            for component in deductionComponents {
                if let deduction = validatedData[component] {
                    let deductionRatio = deduction / basicPay
                    if deductionRatio > 0.5 { // No single deduction should exceed 50% of basic pay
                        print("[MilitaryValidationService] Warning: \(component) deduction ratio \(deductionRatio) seems very high")
                    }
                }
            }
        }
        
        return validatedData
    }
}
