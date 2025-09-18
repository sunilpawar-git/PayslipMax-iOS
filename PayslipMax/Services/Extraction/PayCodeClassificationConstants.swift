//
//  PayCodeClassificationConstants.swift
//  PayslipMax
//
//  Constants for Universal Dual-Section Implementation - Phase 1
//  Contains classification rules for guaranteed single-section components
//

import Foundation

/// Constants for pay code classification system
struct PayCodeClassificationConstants {
    
    /// Components that are guaranteed to only appear in earnings
    /// These are core pay components that are never recovered
    static let guaranteedEarnings: Set<String> = [
        // Core Basic Pay - Never recovered
        "BPAY", "Basic Pay", "BP",
        
        // Mandatory Service Pay - Never recovered
        "MSP", "Military Service Pay",
        
        // Awards and Medals - Never recovered (one-time payments)
        "AC", "Ashok Chakra",
        "ADCALW", "ADHOC ALLOWANCE"
    ]

    /// Components that are guaranteed to only appear in deductions
    /// These are mandatory deductions that never appear as earnings
    static let guaranteedDeductions: Set<String> = [
        // Insurance Premiums - Always deductions
        "AGIF", "Army Group Insurance Fund",
        "CGEIS", "Central Government Employees Insurance Scheme",
        "CGHS", "Central Government Health Scheme",
        "ECHS", "Ex-Servicemen Contributory Health Scheme",
        
        // Provident Fund - Always deductions
        "DSOP", "Defence Services Officers Provident Fund",
        "GPF", "General Provident Fund",
        "PF", "Provident Fund",
        "AFPF", "Armed Forces Provident Fund",
        "NPS", "National Pension System",
        
        // Tax Deductions - Always deductions
        "ITAX", "Income Tax", "IT",
        "EHCESS", "Education Cess",
        "TDS", "Tax Deducted at Source",
        "PTAX", "Professional Tax",
        
        // Utility Charges - Always deductions
        "ELEC", "Electricity Charges",
        "WATER", "Water Charges",
        "FUR", "Furniture Recovery",
        "LF", "License Fee",
        "QTRS", "Quarters Rent",
        "RENT", "Accommodation Rent",
        
        // Loan Recoveries - Always deductions
        "ADVHBA", "HBA Advance Recovery",
        "ADVCP", "Computer Advance Recovery",
        "ADVFES", "Festival Advance Recovery",
        "ADVMCA", "MCA Advance Recovery",
        "ADVPF", "PF Advance Recovery",
        "ADVSCTR", "Scooter Advance Recovery",
        "LOAN", "Loan Recovery",
        "LOANS", "Loans Recovery",
        
        // Membership and Subscriptions - Always deductions
        "MESS", "Mess Charges",
        "CLUB", "Club Subscription",
        "AWWA", "Army Wives Welfare Association",
        "NWWA", "Navy Wives Welfare Association",
        "AFWWA", "Air Force Wives Welfare Association",
        "CSD", "Canteen Stores Department",
        
        // Bank Adjustments - Always deductions
        "ADBANKC", "Adjustment against Bank CR",
        "ETKT", "E-Ticket Recovery"
    ]
    
    /// Validates if a component matches guaranteed earnings patterns
    /// - Parameter component: The normalized component code
    /// - Returns: True if it's a guaranteed earnings component
    static func isGuaranteedEarnings(_ component: String) -> Bool {
        return guaranteedEarnings.contains(component)
    }
    
    /// Validates if a component matches guaranteed deductions patterns
    /// - Parameter component: The normalized component code
    /// - Returns: True if it's a guaranteed deductions component
    static func isGuaranteedDeductions(_ component: String) -> Bool {
        return guaranteedDeductions.contains(component)
    }
}
