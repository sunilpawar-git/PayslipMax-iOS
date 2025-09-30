import Foundation
@testable import PayslipMax

/// Test data constants for PayCodeClassificationEngine tests
struct PayCodeClassificationTestData {

    // MARK: - Common Test Codes

    static let basicPayCodes = ["BPAY", "MSP"]
    static let deductionCodes = ["DSOP", "AGIF", "ITAX"]
    static let specialForcesCodes = ["SPCDO", "FLYALLOW", "SICHA"]
    static let arrearsCodes = ["ARR-BPAY", "ARR-CEA", "ARR-SPCDO", "ARR-DSOP", "ARR-ITAX"]
    static let dualSectionCodes = ["RH12", "RH13", "HRA", "TPTA"]
    static let nonDualSectionCodes = ["BPAY", "DSOP", "AGIF"]

    // MARK: - Performance Test Data

    static let commonMilitaryCodes = [
        "BPAY", "MSP", "DA", "HRA", "TPTA", "CEA", "RH12", "RH13",
        "DSOP", "AGIF", "ITAX", "EHCESS", "SPCDO", "FLYALLOW", "SICHA"
    ]

    static let allTestCodes = [
        "BPAY", "MSP", "DA", "HRA", "RH11", "RH12", "RH13", "TPTA",
        "DSOP", "AGIF", "ITAX", "SPCDO", "FLYALLOW", "SICHA"
    ]

    // MARK: - Test Case Data

    static let jsonBasedTestCases: [(code: String, expectedSection: PayslipSection)] = [
        // Basic Pay & Allowances (Earnings)
        ("BPAY", .earnings), ("MSP", .earnings), ("DA", .earnings), ("HRA", .earnings),
        ("TPTA", .earnings), ("TPTADA", .earnings), ("CEA", .earnings),

        // Special Forces (Earnings)
        ("SPCDO", .earnings), ("FLYALLOW", .earnings), ("SICHA", .earnings), ("HAUC3", .earnings),

        // Deductions
        ("DSOP", .deductions), ("AGIF", .deductions), ("ITAX", .deductions), ("EHCESS", .deductions),
        ("GPF", .deductions), ("PF", .deductions)
    ]

    static let complexCodes = ["RH12", "RH21", "HAUC3", "SPCDO"]

    // MARK: - Sample Values

    static let sampleValues = [
        "BPAY": 144700,
        "MSP": 15500,
        "DSOP": 40000,
        "AGIF": 10000,
        "ITAX": 25000,
        "SPCDO": 45000,
        "FLYALLOW": 25000,
        "SICHA": 50000,
        "RH12": 21125,
        "ARR-BPAY": 12000,
        "ARR-CEA": 8000,
        "ARR-SPCDO": 15000,
        "ARR-DSOP": 5000,
        "ARR-ITAX": 3000
    ]
}
