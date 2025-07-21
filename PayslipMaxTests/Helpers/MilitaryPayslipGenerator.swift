import Foundation
import PDFKit
@testable import PayslipMax

/// Generator for military payslip test data
class MilitaryPayslipGenerator {
    
    // MARK: - Standard Military Payslips
    
    /// Creates a standard military payslip with relevant allowances and deductions
    static func standardMilitaryPayslip(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        rank: MilitaryRank = .o3,
        name: String = "Cpt. James Miller",
        serviceYears: Int = 6,
        branch: MilitaryBranch = .army,
        deploymentStatus: DeploymentStatus = .domestic
    ) -> PayslipItem {
        let basePay = calculateBasePay(rank: rank, serviceYears: serviceYears)
        let allowances = calculateAllowances(rank: rank, branch: branch, deploymentStatus: deploymentStatus)
        let deductions = calculateDeductions(basePay: basePay, rank: rank, deploymentStatus: deploymentStatus)
        
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: basePay + allowances,
            debits: deductions,
            dsop: calculateRetirementContribution(basePay: basePay),
            tax: calculateTax(basePay: basePay, deploymentStatus: deploymentStatus),
            name: name,
            accountNumber: "MIL-\(String(format: "%04d", Int.random(in: 1000...9999)))",
            panNumber: "MIL\(String(format: "%05d", Int.random(in: 10000...99999)))T",
        )
    }
    
    /// Creates a deployed military payslip with combat pay and additional allowances
    static func deployedMilitaryPayslip(
        id: UUID = UUID(),
        month: String = "March",
        year: Int = 2023,
        rank: MilitaryRank = .o4,
        name: String = "Maj. Sarah Johnson",
        serviceYears: Int = 12,
        branch: MilitaryBranch = .marines,
        deploymentStatus: DeploymentStatus = .combat,
        hazardLevel: HazardLevel = .moderate
    ) -> PayslipItem {
        let basePay = calculateBasePay(rank: rank, serviceYears: serviceYears)
        let standardAllowances = calculateAllowances(rank: rank, branch: branch, deploymentStatus: deploymentStatus)
        let combatPay = calculateCombatPay(rank: rank, hazardLevel: hazardLevel)
        let deductions = calculateDeductions(basePay: basePay, rank: rank, deploymentStatus: deploymentStatus)
        
        let totalCredits = basePay + standardAllowances + combatPay
        
        var creditBreakdown = generateCreditBreakdown(rank: rank, serviceYears: serviceYears, branch: branch, deploymentStatus: deploymentStatus)
        creditBreakdown["Combat Zone Tax Exclusion"] = combatPay
        
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: totalCredits,
            debits: deductions,
            dsop: calculateRetirementContribution(basePay: basePay),
            tax: calculateTax(basePay: basePay, deploymentStatus: deploymentStatus),
            name: name,
            accountNumber: "MIL-\(String(format: "%04d", Int.random(in: 1000...9999)))",
            panNumber: "MIL\(String(format: "%05d", Int.random(in: 10000...99999)))T",
        )
    }
    
    // MARK: - PDF Generation
    
    /// Creates a PDF document for a military payslip
    static func militaryPayslipPDF(
        payslip: PayslipItem? = nil,
        rank: MilitaryRank = .o3,
        deploymentStatus: DeploymentStatus = .domestic
    ) -> PDFDocument {
        let actualPayslip = payslip ?? standardMilitaryPayslip(rank: rank, deploymentStatus: deploymentStatus)
        return TestDataGenerator.samplePayslipPDF(
            name: actualPayslip.name,
            rank: rank.rawValue,
            id: actualPayslip.id.uuidString,
            month: actualPayslip.month,
            year: actualPayslip.year,
            credits: actualPayslip.credits,
            debits: actualPayslip.debits,
            dsop: actualPayslip.dsop,
            tax: actualPayslip.tax
        )
    }
    
    // MARK: - Helper Methods
    
    /// Calculates base pay based on military rank and years of service
    private static func calculateBasePay(rank: MilitaryRank, serviceYears: Int) -> Double {
        let basePay: Double
        
        // Base pay by rank
        switch rank {
        case .e1:
            basePay = 1785.00
        case .e2:
            basePay = 2000.70
        case .e3:
            basePay = 2103.90
        case .e4:
            basePay = 2330.40
        case .e5:
            basePay = 2541.60
        case .e6:
            basePay = 2774.40
        case .e7:
            basePay = 3210.30
        case .e8:
            basePay = 4480.20
        case .e9:
            basePay = 5475.30
        case .w1:
            basePay = 3213.30
        case .w2:
            basePay = 3661.80
        case .w3:
            basePay = 4146.60
        case .w4:
            basePay = 4537.50
        case .w5:
            basePay = 8520.90
        case .o1:
            basePay = 3477.30
        case .o2:
            basePay = 4019.10
        case .o3:
            basePay = 4600.80
        case .o4:
            basePay = 5671.50
        case .o5:
            basePay = 6741.00
        case .o6:
            basePay = 8040.60
        case .o7:
            basePay = 10506.00
        case .o8:
            basePay = 12638.40
        case .o9:
            basePay = 13989.00
        case .o10:
            basePay = 16974.90
        }
        
        // Apply longevity increase based on years of service
        // Military pay tables increase with both rank and years of service
        let longevityMultiplier: Double
        
        if serviceYears < 2 {
            longevityMultiplier = 1.0
        } else if serviceYears < 4 {
            longevityMultiplier = 1.05
        } else if serviceYears < 6 {
            longevityMultiplier = 1.10
        } else if serviceYears < 8 {
            longevityMultiplier = 1.15
        } else if serviceYears < 10 {
            longevityMultiplier = 1.20
        } else if serviceYears < 12 {
            longevityMultiplier = 1.25
        } else if serviceYears < 14 {
            longevityMultiplier = 1.30
        } else if serviceYears < 16 {
            longevityMultiplier = 1.35
        } else if serviceYears < 18 {
            longevityMultiplier = 1.40
        } else if serviceYears < 20 {
            longevityMultiplier = 1.45
        } else if serviceYears < 22 {
            longevityMultiplier = 1.50
        } else if serviceYears < 24 {
            longevityMultiplier = 1.55
        } else if serviceYears < 26 {
            longevityMultiplier = 1.60
        } else {
            longevityMultiplier = 1.65
        }
        
        return basePay * longevityMultiplier
    }
    
    /// Calculates standard military allowances
    private static func calculateAllowances(rank: MilitaryRank, branch: MilitaryBranch, deploymentStatus: DeploymentStatus) -> Double {
        let basePay = calculateBasePay(rank: rank, serviceYears: 0)
        var totalAllowances = 0.0
        
        // Basic Allowance for Housing (BAH) - varies by rank and location
        let bahRate: Double
        switch rank {
        case .e1, .e2, .e3, .e4:
            bahRate = 0.15
        case .e5, .e6, .e7:
            bahRate = 0.18
        case .e8, .e9, .w1, .w2, .w3:
            bahRate = 0.20
        case .w4, .w5, .o1, .o2, .o3:
            bahRate = 0.22
        case .o4, .o5:
            bahRate = 0.24
        case .o6, .o7, .o8, .o9, .o10:
            bahRate = 0.26
        }
        
        // Basic Allowance for Subsistence (BAS) - fixed rate
        let basRate: Double
        if rank.isEnlisted {
            basRate = 372.71 // Enlisted BAS rate
        } else {
            basRate = 256.68 // Officer BAS rate
        }
        
        // Add branch-specific allowances
        var branchMultiplier = 1.0
        switch branch {
        case .navy, .marines:
            branchMultiplier = 1.05 // Sea pay or fleet assignment
        case .airForce:
            branchMultiplier = 1.03 // Flight pay
        case .army:
            branchMultiplier = 1.02 // Standard
        case .coastGuard:
            branchMultiplier = 1.04 // Maritime pay
        case .spaceForce:
            branchMultiplier = 1.06 // Technical specialty
        }
        
        // Add deployment status effects
        var deploymentMultiplier = 1.0
        switch deploymentStatus {
        case .domestic:
            deploymentMultiplier = 1.0
        case .overseas:
            deploymentMultiplier = 1.15 // Overseas Housing Allowance
        case .combat:
            deploymentMultiplier = 1.25 // Combat Zone Tax Exclusion plus other incentives
        case .hazardous:
            deploymentMultiplier = 1.35 // Hazardous Duty Pay
        case .training:
            deploymentMultiplier = 1.05 // Field training exercises
        }
        
        // Calculate total allowances
        let bah = basePay * bahRate * deploymentMultiplier
        totalAllowances = bah + (basRate * branchMultiplier)
        
        return totalAllowances
    }
    
    /// Calculates combat pay based on rank and hazard level
    private static func calculateCombatPay(rank: MilitaryRank, hazardLevel: HazardLevel) -> Double {
        let baseCombatPay: Double
        
        if rank.isEnlisted {
            baseCombatPay = 225.0
        } else if rank.isWarrantOfficer {
            baseCombatPay = 275.0
        } else {
            baseCombatPay = 325.0
        }
        
        // Adjust for hazard level
        switch hazardLevel {
        case .minimal:
            return baseCombatPay * 1.0
        case .low:
            return baseCombatPay * 1.25
        case .moderate:
            return baseCombatPay * 1.5
        case .high:
            return baseCombatPay * 2.0
        case .extreme:
            return baseCombatPay * 2.5
        }
    }
    
    /// Calculates standard military deductions
    private static func calculateDeductions(basePay: Double, rank: MilitaryRank, deploymentStatus: DeploymentStatus) -> Double {
        // Military benefits have specific deduction structures
        var deductionRate = 0.05 // Base deduction rate for standard benefits
        
        // Officers typically pay more for some benefits
        if !rank.isEnlisted {
            deductionRate += 0.01
        }
        
        // Warrant officers have a slightly different structure
        if rank.isWarrantOfficer {
            deductionRate += 0.005
        }
        
        // Deployment affects deductions
        if deploymentStatus == .combat || deploymentStatus == .hazardous {
            deductionRate -= 0.01 // Some deductions waived in combat zones
        }
        
        return basePay * deductionRate
    }
    
    /// Calculates military retirement contribution
    private static func calculateRetirementContribution(basePay: Double) -> Double {
        // Military retirement system (e.g., BRS - Blended Retirement System)
        return basePay * 0.05
    }
    
    /// Calculates income tax based on deployment status
    private static func calculateTax(basePay: Double, deploymentStatus: DeploymentStatus) -> Double {
        // Combat Zone Tax Exclusion affects taxation
        if deploymentStatus == .combat {
            return 0.0 // No federal income tax in combat zones
        }
        
        // Standard tax calculation
        let taxRate = 0.15 // Simplified for example
        return basePay * taxRate
    }
    
    /// Creates a breakdown of military credits/allowances
    private static func generateCreditBreakdown(rank: MilitaryRank, serviceYears: Int, branch: MilitaryBranch, deploymentStatus: DeploymentStatus) -> [String: Double] {
        let basePay = calculateBasePay(rank: rank, serviceYears: serviceYears)
        let baseAllowance = calculateBasePay(rank: rank, serviceYears: 0) * 0.05
        
        var breakdown: [String: Double] = [
            "Base Pay": basePay
        ]
        
        // Add Basic Allowances
        if rank.isEnlisted {
            breakdown["Basic Allowance for Subsistence (BAS)"] = 372.71
        } else {
            breakdown["Basic Allowance for Subsistence (BAS)"] = 256.68
        }
        
        let bahRate: Double
        switch rank {
        case .e1, .e2, .e3, .e4:
            bahRate = 0.15
        case .e5, .e6, .e7:
            bahRate = 0.18
        case .e8, .e9, .w1, .w2, .w3:
            bahRate = 0.20
        case .w4, .w5, .o1, .o2, .o3:
            bahRate = 0.22
        case .o4, .o5:
            bahRate = 0.24
        case .o6, .o7, .o8, .o9, .o10:
            bahRate = 0.26
        }
        
        breakdown["Basic Allowance for Housing (BAH)"] = basePay * bahRate
        
        // Add special pay based on branch
        switch branch {
        case .navy:
            breakdown["Sea Pay"] = basePay * 0.05
            if rank.isEnlisted {
                breakdown["Submarine Duty Pay"] = baseAllowance * 1.2
            }
        case .marines:
            breakdown["Hazardous Duty Pay"] = basePay * 0.03
            breakdown["Marine Corps Specialty Pay"] = baseAllowance * 1.1
        case .airForce:
            breakdown["Flight Pay"] = basePay * 0.03
            breakdown["Aviation Career Incentive Pay"] = baseAllowance * 1.2
        case .army:
            breakdown["Hostile Fire Pay"] = basePay * 0.02
            breakdown["Parachute Duty Pay"] = baseAllowance * 1.0
        case .coastGuard:
            breakdown["Maritime Pay"] = basePay * 0.04
            breakdown["Boarding Team Pay"] = baseAllowance * 1.1
        case .spaceForce:
            breakdown["Technical Specialty Pay"] = basePay * 0.06
            breakdown["Space Operations Duty Pay"] = baseAllowance * 1.3
        }
        
        // Add deployment-specific allowances
        switch deploymentStatus {
        case .domestic:
            // Standard domestic allowances
            break
        case .overseas:
            breakdown["Overseas Housing Allowance"] = basePay * 0.15
            breakdown["Cost of Living Allowance"] = basePay * 0.10
        case .combat:
            breakdown["Hostile Fire Pay"] = 225.0
            breakdown["Imminent Danger Pay"] = 225.0
            breakdown["Hardship Duty Pay"] = 100.0
        case .hazardous:
            breakdown["Hazardous Duty Pay"] = 150.0
            breakdown["Assignment Incentive Pay"] = basePay * 0.10
        case .training:
            breakdown["Field Training Allowance"] = basePay * 0.05
        }
        
        return breakdown
    }
    
    /// Creates a breakdown of military debits/deductions
    private static func generateDebitBreakdown(basePay: Double, rank: MilitaryRank, deploymentStatus: DeploymentStatus) -> [String: Double] {
        var deductions: [String: Double] = [
            "Retirement Plan Contribution": calculateRetirementContribution(basePay: basePay),
            "SGLI Insurance": 25.0, // Servicemembers' Group Life Insurance
            "Dental Plan": 15.0,
            "AFRH": basePay * 0.005 // Armed Forces Retirement Home
        ]
        
        // Add tax unless in combat zone
        if deploymentStatus != .combat {
            deductions["Federal Income Tax"] = calculateTax(basePay: basePay, deploymentStatus: deploymentStatus)
            deductions["FICA"] = basePay * 0.062 // Social Security
            deductions["Medicare"] = basePay * 0.0145
        }
        
        // Add any special deductions based on rank
        if !rank.isEnlisted {
            deductions["Officers' Association Dues"] = 15.0
        }
        
        if rank.isWarrantOfficer {
            deductions["Warrant Officer Association"] = 10.0
        }
        
        return deductions
    }
    
    // MARK: - Batch Generation
    
    /// Generates an array of various military payslips
    static func batchOfMilitaryPayslips() -> [PayslipItem] {
        return [
            // Enlisted personnel from different branches
            standardMilitaryPayslip(rank: .e3, name: "PFC. Robert Johnson", serviceYears: 2, branch: .army),
            standardMilitaryPayslip(rank: .e5, name: "SGT. Maria Garcia", serviceYears: 6, branch: .marines),
            standardMilitaryPayslip(rank: .e7, name: "CPO. William Davis", serviceYears: 12, branch: .navy),
            standardMilitaryPayslip(rank: .e9, name: "CMSgt. Thomas Wilson", serviceYears: 24, branch: .airForce),
            
            // Warrant officers
            standardMilitaryPayslip(rank: .w2, name: "CW2. Jennifer Brown", serviceYears: 8, branch: .army),
            standardMilitaryPayslip(rank: .w4, name: "CW4. Michael Thompson", serviceYears: 16, branch: .army),
            
            // Officers
            standardMilitaryPayslip(rank: .o1, name: "2Lt. Sarah Martinez", serviceYears: 1, branch: .airForce),
            standardMilitaryPayslip(rank: .o3, name: "Capt. James Miller", serviceYears: 6, branch: .marines),
            standardMilitaryPayslip(rank: .o5, name: "Cdr. Daniel Clark", serviceYears: 16, branch: .navy),
            standardMilitaryPayslip(rank: .o6, name: "Col. Elizabeth Taylor", serviceYears: 22, branch: .spaceForce),
            
            // Deployed personnel
            deployedMilitaryPayslip(rank: .e4, name: "SPC. David Rodriguez", serviceYears: 3, branch: .army, deploymentStatus: .combat, hazardLevel: .moderate),
            deployedMilitaryPayslip(rank: .o3, name: "Capt. Kevin Anderson", serviceYears: 5, branch: .marines, deploymentStatus: .combat, hazardLevel: .high)
        ]
    }
    
    // MARK: - Types
    
    /// Military rank enumeration covering all service branches
    enum MilitaryRank: String {
        // Enlisted
        case e1 = "E-1"
        case e2 = "E-2"
        case e3 = "E-3"
        case e4 = "E-4"
        case e5 = "E-5"
        case e6 = "E-6"
        case e7 = "E-7"
        case e8 = "E-8"
        case e9 = "E-9"
        
        // Warrant Officers
        case w1 = "W-1"
        case w2 = "W-2"
        case w3 = "W-3"
        case w4 = "W-4"
        case w5 = "W-5"
        
        // Officers
        case o1 = "O-1"
        case o2 = "O-2"
        case o3 = "O-3"
        case o4 = "O-4"
        case o5 = "O-5"
        case o6 = "O-6"
        case o7 = "O-7"
        case o8 = "O-8"
        case o9 = "O-9"
        case o10 = "O-10"
        
        /// Returns true if this is an enlisted rank
        var isEnlisted: Bool {
            return self.rawValue.hasPrefix("E")
        }
        
        /// Returns true if this is a warrant officer rank
        var isWarrantOfficer: Bool {
            return self.rawValue.hasPrefix("W")
        }
        
        /// Returns true if this is a commissioned officer rank
        var isOfficer: Bool {
            return self.rawValue.hasPrefix("O")
        }
    }
    
    /// Military branch enumeration
    enum MilitaryBranch {
        case army
        case navy
        case airForce
        case marines
        case coastGuard
        case spaceForce
    }
    
    /// Deployment status enumeration
    enum DeploymentStatus {
        case domestic
        case overseas
        case combat
        case hazardous
        case training
    }
    
    /// Hazard level enumeration for combat deployments
    enum HazardLevel {
        case minimal
        case low
        case moderate
        case high
        case extreme
    }
} 