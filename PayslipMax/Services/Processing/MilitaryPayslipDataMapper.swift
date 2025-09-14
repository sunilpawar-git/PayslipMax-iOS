//
//  MilitaryPayslipDataMapper.swift
//  PayslipMax
//
//  Extracted from UnifiedMilitaryPayslipProcessor for architectural compliance
//  Handles mapping of raw data to structured format
//

import Foundation

/// Protocol for military payslip data mapping following SOLID principles
protocol MilitaryPayslipDataMapperProtocol {
    func mapLegacyData(_ legacyData: [String: Double], earnings: inout [String: Double], deductions: inout [String: Double])
    func processRH12Components(_ rh12Instances: [(value: Double, context: String)], earnings: inout [String: Double], deductions: inout [String: Double])
}

/// Service responsible for mapping raw military payslip data to structured format
/// Implements single responsibility principle for data transformation
class MilitaryPayslipDataMapper: MilitaryPayslipDataMapperProtocol {
    
    private let sectionClassifier = PayslipSectionClassifier()
    private let rhProcessor = RiskHardshipProcessor()
    
    /// Maps legacy extracted data to structured earnings and deductions
    func mapLegacyData(_ legacyData: [String: Double], earnings: inout [String: Double], deductions: inout [String: Double]) {
        
        // Map components, skipping meta-data and totals
        for (key, value) in legacyData {
            print("[MilitaryPayslipDataMapper] Mapping component: \(key) = ₹\(value)")
            
            // Skip these meta entries - they're not individual payslip components
            if key == "credits" || key == "debits" {
                continue
            }
            
            // Skip legacy RH12 - it's handled by enhanced detection
            if key == "RH12" {
                print("[MilitaryPayslipDataMapper] Skipping legacy RH12 (\(key)) - handled by enhanced detection")
                continue
            }
            
            // Map known earnings
            switch key {
            case "BasicPay", "Basic Pay":
                earnings["Basic Pay"] = value
                print("[MilitaryPayslipDataMapper] Stored Basic Pay: ₹\(value)")
            case "DA", "Dearness Allowance":
                earnings["Dearness Allowance"] = value
                print("[MilitaryPayslipDataMapper] Stored DA: ₹\(value)")
            case "MSP", "Military Service Pay":
                earnings["Military Service Pay"] = value
                print("[MilitaryPayslipDataMapper] Stored MSP: ₹\(value)")
            case "TPTA", "Transport Allowance":
                earnings["Transport Allowance"] = value
                print("[MilitaryPayslipDataMapper] Stored TPTA: ₹\(value)")
            case "TPTADA", "Transport Allowance DA":
                earnings["Transport Allowance DA"] = value
            case "HRA":
                earnings["House Rent Allowance"] = value
            case "ARR-RSHNA", "Arrears RSHNA":
                earnings["Arrears RSHNA"] = value
                
            // Map known deductions
            case "DSOP", "DSOPF":
                deductions["DSOP"] = value
                print("[MilitaryPayslipDataMapper] Stored DSOP: ₹\(value)")
            case "AGIF":
                deductions["AGIF"] = value
                print("[MilitaryPayslipDataMapper] Stored AGIF: ₹\(value)")
            case "ITAX", "Income Tax":
                deductions["Income Tax"] = value
                print("[MilitaryPayslipDataMapper] Stored Income Tax: ₹\(value)")
            case "EHCESS":
                deductions["EHCESS"] = value
                
            default:
                // For unknown components, attempt intelligent classification
                classifyUnknownComponent(key: key, value: value, earnings: &earnings, deductions: &deductions)
            }
        }
    }
    
    /// Processes RH12 instances and adds them to appropriate sections
    func processRH12Components(_ rh12Instances: [(value: Double, context: String)], earnings: inout [String: Double], deductions: inout [String: Double]) {
        
        for rh12 in rh12Instances {
            print("[MilitaryPayslipDataMapper] Enhanced RH12 detection found: ₹\(rh12.value)")
            
            // Use the RiskHardshipProcessor to handle the component
            rhProcessor.processRiskHardshipComponent(
                key: "RH12",
                value: rh12.value,
                text: rh12.context,
                earnings: &earnings,
                deductions: &deductions
            )
        }
    }
    
    /// Attempts to classify unknown components using intelligent rules
    private func classifyUnknownComponent(key: String, value: Double, earnings: inout [String: Double], deductions: inout [String: Double]) {
        let keyUpper = key.uppercased()
        
        // Earnings patterns
        if keyUpper.contains("PAY") || keyUpper.contains("ALLOWANCE") || keyUpper.contains("BONUS") || 
           keyUpper.contains("INCENT") || keyUpper.contains("REIMB") || keyUpper.contains("ARR") {
            earnings[formatDisplayName(key)] = value
            print("[MilitaryPayslipDataMapper] Auto-classified as earnings: \(key) = ₹\(value)")
        }
        // Deduction patterns
        else if keyUpper.contains("TAX") || keyUpper.contains("DEDUCT") || keyUpper.contains("RECOV") ||
                keyUpper.contains("FINE") || keyUpper.contains("CONTRIB") || keyUpper.contains("PROV") {
            deductions[formatDisplayName(key)] = value
            print("[MilitaryPayslipDataMapper] Auto-classified as deductions: \(key) = ₹\(value)")
        }
        // Default to earnings for unknown positive values
        else if value > 0 {
            earnings[formatDisplayName(key)] = value
            print("[MilitaryPayslipDataMapper] Default classification as earnings: \(key) = ₹\(value)")
        }
    }
    
    /// Formats component key for display
    private func formatDisplayName(_ key: String) -> String {
        return key.replacingOccurrences(of: "_", with: " ")
                  .replacingOccurrences(of: "-", with: " ")
                  .capitalized
    }
}
