//
//  PayslipDisplayNameConstants.swift
//  PayslipMax
//
//  Created for Phase 4: Universal Dual-Section Implementation - Display Layer Enhancement
//  Comprehensive display name mappings for all military paycodes
//  Extracted to maintain file size compliance (<300 lines per architectural constraint)
//

import Foundation

/// Constants for comprehensive payslip display name mappings
/// Supports universal dual-section processing for all military paycodes
struct PayslipDisplayNameConstants {

    // MARK: - Universal Display Name Mappings

    /// Comprehensive mapping of internal keys to user-friendly display names
    /// Includes dual-section support for all allowances and standard paycodes
    static let displayNameMappings: [String: String] = [

        // MARK: - Basic Pay Components
        "BPAY": "Basic Pay",
        "Basic Pay": "Basic Pay",
        "BASICPAY": "Basic Pay",
        "BP": "Basic Pay",
        "MSP": "Military Service Pay",
        "Military Service Pay": "Military Service Pay",
        "GPAY": "Grade Pay",

        // MARK: - Risk & Hardship Allowances (RH Family)
        // Maintain backward compatibility with existing test expectations
        "RH11": "RH11",
        "RH11_EARNINGS": "RH11",
        "RH11_DEDUCTIONS": "RH11",
        "RH12": "RH12",
        "RH12_EARNINGS": "RH12",
        "RH12_DEDUCTIONS": "RH12",
        "RH13": "RH13",
        "RH13_EARNINGS": "RH13",
        "RH13_DEDUCTIONS": "RH13",
        "RH21": "RH21",
        "RH21_EARNINGS": "RH21",
        "RH21_DEDUCTIONS": "RH21",
        "RH22": "RH22",
        "RH22_EARNINGS": "RH22",
        "RH22_DEDUCTIONS": "RH22",
        "RH23": "RH23",
        "RH23_EARNINGS": "RH23",
        "RH23_DEDUCTIONS": "RH23",
        "RH31": "RH31",
        "RH31_EARNINGS": "RH31",
        "RH31_DEDUCTIONS": "RH31",
        "RH32": "RH32",
        "RH32_EARNINGS": "RH32",
        "RH32_DEDUCTIONS": "RH32",
        "RH33": "RH33",
        "RH33_EARNINGS": "RH33",
        "RH33_DEDUCTIONS": "RH33",
        "RH60": "RH60",
        "RH77": "RH77",

        // MARK: - Standard Allowances (Universal Dual-Section)
        "DA": "Dearness Allowance",
        "DA_EARNINGS": "Dearness Allowance",
        "DA_DEDUCTIONS": "Dearness Allowance",
        "Dearness Allowance": "Dearness Allowance",

        "HRA": "House Rent Allowance",
        "HRA_EARNINGS": "House Rent Allowance",
        "HRA_DEDUCTIONS": "House Rent Allowance",
        "HRA1": "House Rent Allowance X1",
        "HRA2": "House Rent Allowance Y2",
        "HRA3": "House Rent Allowance Z3",
        "HRAX": "House Rent Allowance X Class",
        "HRAY": "House Rent Allowance Y Class",
        "HRAZ": "House Rent Allowance Z Class",

        "CEA": "Children Education Allowance",
        "CEA_EARNINGS": "Children Education Allowance",
        "CEA_DEDUCTIONS": "Children Education Allowance",

        "CCA": "City Compensatory Allowance",
        "CCA_EARNINGS": "City Compensatory Allowance",
        "CCA_DEDUCTIONS": "City Compensatory Allowance",
        "CCA1": "City Compensatory Allowance C1",
        "CLA": "City Compensatory Allowance",

        "TPTA": "Transport Allowance",
        "TPTA_EARNINGS": "Transport Allowance",
        "TPTA_DEDUCTIONS": "Transport Allowance",
        "Transport Allowance": "Transport Allowance",
        "TPTADA": "Transport Allowance DA",
        "Transport Allowance DA": "Transport Allowance DA",

        "SICHA": "Siachen Allowance",
        "SICHA_EARNINGS": "Siachen Allowance",
        "SICHA_DEDUCTIONS": "Siachen Allowance",

        "RSHNA": "Ration Allowance",
        "RSHNA_EARNINGS": "Ration Allowance",
        "RSHNA_DEDUCTIONS": "Ration Allowance",

        "TECA": "Technical Allowance PG/Diploma Appx-A",
        "TECB": "Technical Allowance First Time PG/Diploma Appx-B",
        "TECC": "Technical Allowance First Time PG/Diploma Appx-C",
        "TECI": "Technical Allowance Tier-I",
        "TECII": "Technical Allowance Tier-II",
        "TEC": "Technical Allowance",

        // MARK: - Special Allowances
        "FLPAY": "Flying Pay",
        "FLTA": "Flight Test Allowance",
        "PARA": "Parachute Allowance",
        "HAFA": "Highly Active Field Area Allowance",
        "CFAA": "Compensatory Field Area Allowance",
        "CMFA": "Compensatory Modified Area Allowance",
        "DAA": "Difficult Area Allowance",
        "HARDA": "Hard Area Allowance",
        "HARDS": "Hardship Allowance",
        "HAZ": "Hazard Allowance",
        "HCA": "Hill Compensatory Allowance",
        "NSG": "National Security Guard Allowance",
        "NTRO": "National Training & Research Organisation Allowance",
        "SAG": "Special Action Group Allowance",
        "SRG": "Special Ranger Group Allowance",
        "SDUTY": "Special Duty Allowance",
        "SECUR": "Security Allowance",
        "SPCDO": "Special Forces Allowance",
        "PROJ": "Project Allowance",
        "PALL": "Project Allowance",
        "INSTR": "Instructor Allowance",
        "NPA": "Non Practicing Allowance",
        "ENT": "Entertainment Allowance",
        "OUTFIT": "Outfit Allowance",
        "DRESALW": "Dress Allowance",

        // MARK: - High Altitude & Climate Allowances
        "HAUC1": "High Altitude Allowance Lower Rate",
        "HAUC2": "High Altitude Allowance Higher Rate",
        "HAUC3": "High Altitude Allowance Enhanced Rate",
        "HH11": "High Altitude R1H1",
        "HH31": "High Altitude R3H1",
        "HH32": "High Altitude R3H2",
        "AVLAN": "Avalanche Allowance",

        // MARK: - Compensatory Allowances
        "BCA": "Bhutan Compensatory Allowance",
        "BCAS1": "Bhutan Compensatory Allowance with One Servant",
        "BCAS2": "Bhutan Compensatory Allowance with Two Servants",
        "MCA": "Myanmar Compensatory Allowance",
        "MCAS1": "Myanmar Compensatory Allowance with One Servant",
        "MCAS2": "Myanmar Compensatory Allowance with Two Servants",
        "SCA": "Special Compensatory Allowance",
        "SCAA": "Remote Locality Comp Allowance A",
        "SCAB": "Remote Locality Comp Allowance B",
        "SCAC": "Remote Locality Comp Allowance C",
        "SCAD": "Remote Locality Comp Allowance D",
        "EXPA": "Expatriation Allowance",

        // MARK: - Guaranteed Deductions (Never appear as earnings)
        "DSOP": "DSOP",
        "AGIF": "AGIF",
        "CGEIS": "Central Government Employees Insurance Scheme",
        "CGHS": "Central Government Health Scheme",
        "ECHS": "Ex-Servicemen Contributory Health Scheme",
        "GPF": "General Provident Fund",
        "PF": "Provident Fund",
        "AFPF": "Air Force Provident Fund",
        "NPS": "National Pension System",
        "NPSEC": "NPS Employee Contribution",
        "PLI": "PLI Premium",
        "DLI": "Deposit Link Insurance",
        "TAGIF": "TAGI Subscription",

        "ITAX": "Income Tax",
        "INCTAX": "Income Tax",
        "Income Tax": "Income Tax",
        "EHCESS": "Education and Health Cess",
        "EDCESS": "Education Cess on IT",
        "SURCH": "Surcharge on IT",
        "TDS": "Tax Deducted at Source",
        "PTAX": "Professional Tax",
        "CVP": "Deductible Value of Pension",

        "ELEC": "Electricity Charges",
        "WATER": "Water Charges",
        "FUR": "Furniture Charges",
        "LF": "License Fee",
        "QTRS": "Quarters Rent",
        "RENT": "Accommodation Rent",
        "MESSCHG": "Messing Charges",
        "CON": "Conservancy Charges",
        "FAN": "Fan Charges",
        "FRIDGE": "Fridge Charges",

        // MARK: - Arrears Patterns (Universal Dual-Section)
        "Arrears RSHNA": "Arrears Ration Allowance",
        "ARR-BPAY": "Arrears Basic Pay",
        "ARR-BPAY_EARNINGS": "Arrears Basic Pay",
        "ARR-BPAY_DEDUCTIONS": "Arrears Basic Pay",
        "ARR-DA": "Arrears Dearness Allowance",
        "ARR-DA_EARNINGS": "Arrears Dearness Allowance",
        "ARR-DA_DEDUCTIONS": "Arrears Dearness Allowance",
        "ARR-MSP": "Arrears Military Service Pay",
        "ARR-MSP_EARNINGS": "Arrears Military Service Pay",
        "ARR-MSP_DEDUCTIONS": "Arrears Military Service Pay",
        "ARR-HRA": "Arrears House Rent Allowance",
        "ARR-HRA_EARNINGS": "Arrears House Rent Allowance",
        "ARR-HRA_DEDUCTIONS": "Arrears House Rent Allowance",
        "ARR-CEA": "Arrears Children Education Allowance",
        "ARR-CEA_EARNINGS": "Arrears Children Education Allowance",
        "ARR-CEA_DEDUCTIONS": "Arrears Children Education Allowance",
        "ARR-TPTA": "Arrears Transport Allowance",
        "ARR-TPTADA": "Arrears Transport Allowance DA",
        "ARR-RSHNA": "Arrears Ration Allowance",
        "ARR-RSHNA_EARNINGS": "Arrears Ration Allowance",
        "ARR-RSHNA_DEDUCTIONS": "Arrears Ration Allowance",
        "ARR-SICHA": "Arrears Siachen Allowance",
        "ARR-CCA": "Arrears City Compensatory Allowance",
        "ARR-RH12": "Arrears Risk Allowance R1H2",

        // MARK: - Awards & Recognition (Guaranteed Earnings)
        "AC": "Ashok Chakra",
        "KC": "Kirti Chakra",
        "SC": "Shaurya Chakra",
        "PVC": "Param Vir Chakra",
        "MVC": "Maha Vir Chakra",
        "VC": "Vir Chakra",
        "GAL": "Gallantry Award",
        "SENA": "Sena Medal",

        // MARK: - Other Credits & Earnings
        "ENCASH": "Leave Encashment",
        "FSCASH": "Leave Encashment on Final Settlement",
        "WHENCASH": "Encash Withhold",
        "LTC": "Leave Travel Concession",
        "LTCSPL": "LTC Special Cash Package",
        "LTCSPLFA": "LTC Special Cash Package Fare",
        "LTCENSPL": "LTC Encash Special Cash Package",
        "MEDICAL": "Medical Reimbursement",
        "REMFUR": "Furniture Reimbursement",
        "REMHRA": "HRA Reimbursement",
        "REMWAT": "Water Reimbursement",
        "REIMACCO": "Accommodation Reimbursement",
        "LUGGAG": "Luggage Claim",
        "TERMGRAT": "Terminal Gratuity",
        "DSOPINT": "DSOP Interest",
        "DSOPREF": "DSOP Refund",
        "PAYCR": "Pay Credit from DSOP",
        "PCI": "Interest on PC",
        "OPENCR": "Opening Credit Balance",
        "BANKCR": "Credit Balance Release",
        "NPSGC": "NPS Employer Contribution"
    ]

    // MARK: - Helper Methods

    /// Gets display name for a given internal key
    /// - Parameter internalKey: The internal key to look up
    /// - Returns: Display name if found, nil otherwise
    static func getDisplayName(for internalKey: String) -> String? {
        return displayNameMappings[internalKey]
    }

    /// Checks if a key has an explicit display mapping
    /// - Parameter internalKey: The internal key to check
    /// - Returns: True if explicit mapping exists
    static func hasExplicitMapping(for internalKey: String) -> Bool {
        return displayNameMappings.keys.contains(internalKey)
    }

    /// Gets all dual-section keys for a base component
    /// - Parameter baseKey: The base component key (e.g., "HRA")
    /// - Returns: Array of dual-section keys if they exist
    static func getDualSectionKeys(for baseKey: String) -> [String] {
        let earningsKey = "\(baseKey)_EARNINGS"
        let deductionsKey = "\(baseKey)_DEDUCTIONS"

        var keys: [String] = []
        if displayNameMappings.keys.contains(earningsKey) {
            keys.append(earningsKey)
        }
        if displayNameMappings.keys.contains(deductionsKey) {
            keys.append(deductionsKey)
        }

        return keys
    }
}
