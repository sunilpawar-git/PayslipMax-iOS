import Foundation
@testable import PayslipMax

/// Mock implementation of AbbreviationManager for testing
class MockAbbreviationManager: AbbreviationManager {
    // Add tracking properties
    var getFullNameCalled = false
    var getTypeCalled = false
    var trackUnknownAbbreviationCalled = false
    
    // Lists for predefined responses
    private var earningsAbbreviations = ["BPAY", "DA", "MSP", "HRA", "TA", "ALLOWANCE1", "ALLOWANCE2", "BONUS", "DSOP", "DSOPINT", "DSOPREF", "TRAN1", "TRAN2", "TRAN3", "TRAN4", "TRAN5", "TPTA", "TPTADA", "BCA", "BCAS1", "BCAS2", "MCA", "MCAS1", "MCAS2", "SICHA", "HAFA", "CFAA", "CMFA", "ADBANKC", "ADLTA", "ARR-DA", "ARR-SPCDO", "ARR-TPTADA", "HBA", "LOAN", "LTC"]
    private var deductionsAbbreviations = ["DSOP", "AGIF", "ITAX", "CGHS", "CGEIS", "DEDUCTION1", "DEDUCTION2", "LOAN", "INCTAX", "SURCH", "EDCESS", "EHCESS", "RH12", "TPTADA", "ADBNKDR", "ADCGEIS", "ADCGHIS", "ADCGHS", "ADCSD", "ADDSOP", "ADGPF", "ADHBA", "ADHBAI", "ADIT", "ADLIC", "ADLOAN", "ADLOANI", "ADMC", "ADNGIS", "ADPLI", "ADRENT", "ADWATER", "HBAI", "LOANI", "CSD", "ETKT", "FUR", "LF", "MC", "PLI", "RENT", "WATER"]
    
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