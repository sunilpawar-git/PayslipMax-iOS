import Foundation
@testable import Payslip_Max

/// Mock implementation of AbbreviationManager for testing
class MockAbbreviationManager: AbbreviationManager {
    // Add tracking properties
    var getFullNameCalled = false
    var getTypeCalled = false
    var trackUnknownAbbreviationCalled = false
    
    // Lists for predefined responses
    private var earningsAbbreviations = ["BPAY", "DA", "MSP", "HRA", "TA"]
    private var deductionsAbbreviations = ["DSOP", "AGIF", "ITAX", "CGHS", "CGEIS"]
    
    // MARK: - Override methods
    
    override func getFullName(for abbreviation: String) -> String? {
        getFullNameCalled = true
        
        // Return predefined values for testing
        switch abbreviation.uppercased() {
        case "BPAY":
            return "Basic Pay"
        case "DA":
            return "Dearness Allowance"
        case "MSP":
            return "Military Service Pay"
        case "HRA":
            return "House Rent Allowance"
        case "TA":
            return "Travel Allowance"
        case "DSOP":
            return "Defence Services Officers Provident Fund"
        case "AGIF":
            return "Army Group Insurance Fund"
        case "ITAX":
            return "Income Tax"
        case "CGHS":
            return "Central Government Health Scheme"
        case "CGEIS":
            return "Central Government Employees Insurance Scheme"
        default:
            return nil
        }
    }
    
    override func getType(for abbreviation: String) -> AbbreviationType {
        getTypeCalled = true
        
        // Determine type based on predefined lists
        if earningsAbbreviations.contains(abbreviation.uppercased()) {
            return .earning
        } else if deductionsAbbreviations.contains(abbreviation.uppercased()) {
            return .deduction
        } else {
            return .unknown
        }
    }
    
    override func trackUnknownAbbreviation(_ abbreviation: String, value: Double) {
        trackUnknownAbbreviationCalled = true
        // No-op for testing
    }
    
    // MARK: - Additional test methods
    
    func addTestAbbreviation(_ abbreviation: String, type: AbbreviationType) {
        if type == .earning {
            earningsAbbreviations.append(abbreviation.uppercased())
        } else if type == .deduction {
            deductionsAbbreviations.append(abbreviation.uppercased())
        }
    }
} 