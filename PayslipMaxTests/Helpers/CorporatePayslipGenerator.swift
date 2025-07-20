import Foundation
import PDFKit
@testable import PayslipMax

/// Generator for corporate payslip test data
class CorporatePayslipGenerator {
    
    // MARK: - Standard Corporate Payslips
    
    /// Creates a standard corporate payslip with typical allowances and deductions
    static func standardCorporatePayslip(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        level: CorporateLevel = .manager,
        name: String = "Sarah Johnson",
        serviceYears: Int = 5,
        department: CorporateDepartment = .technology
    ) -> PayslipItem {
        let baseSalary = baseSalaryForLevel(level, serviceYears: serviceYears)
        let standardAllowances = corporateAllowances(forLevel: level, department: department)
        let standardDeductions = corporateDeductions(baseSalary: baseSalary, level: level)
        
        let payslip = PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: baseSalary + standardAllowances,
            debits: standardDeductions,
            dsop: calculatePensionContribution(baseSalary: baseSalary, level: level),
            tax: calculateTax(baseSalary: baseSalary, level: level),
            name: name,
            accountNumber: "CORP-\(String(format: "%04d", Int.random(in: 1000...9999)))",
            panNumber: "CORP\(String(format: "%05d", Int.random(in: 10000...99999)))C"
        )
        
        // Set the breakdown data
        payslip.earnings = generateCorporateCreditBreakdown(level: level, serviceYears: serviceYears, department: department)
        payslip.deductions = generateCorporateDebitBreakdown(baseSalary: baseSalary, level: level)
        
        return payslip
    }
    
    /// Creates a bonus payslip for special performance recognition
    static func bonusPayslip(
        id: UUID = UUID(),
        month: String = "December",
        year: Int = 2023,
        level: CorporateLevel = .director,
        name: String = "Michael Chen",
        serviceYears: Int = 8,
        department: CorporateDepartment = .finance,
        bonusType: BonusType = .annual,
        bonusMultiplier: Double = 1.0
    ) -> PayslipItem {
        let baseSalary = baseSalaryForLevel(level, serviceYears: serviceYears)
        let standardAllowances = corporateAllowances(forLevel: level, department: department)
        let bonusAmount = calculateBonus(baseSalary: baseSalary, level: level, type: bonusType, multiplier: bonusMultiplier)
        let standardDeductions = corporateDeductions(baseSalary: baseSalary, level: level)
        
        let totalCredits = baseSalary + standardAllowances + bonusAmount
        // Bonus typically has higher tax rate
        let taxAmount = calculateTax(baseSalary: baseSalary, level: level) +
                        (bonusAmount * 0.35) // Higher tax rate for bonus
        
        var creditBreakdown = generateCorporateCreditBreakdown(level: level, serviceYears: serviceYears, department: department)
        creditBreakdown[bonusType.rawValue] = bonusAmount
        
        let bonusPayslip = PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: totalCredits,
            debits: standardDeductions,
            dsop: calculatePensionContribution(baseSalary: baseSalary, level: level),
            tax: taxAmount,
            name: name,
            accountNumber: "CORP-\(String(format: "%04d", Int.random(in: 1000...9999)))",
            panNumber: "CORP\(String(format: "%05d", Int.random(in: 10000...99999)))C"
        )
        
        // Set the breakdown data
        bonusPayslip.earnings = creditBreakdown
        bonusPayslip.deductions = generateCorporateDebitBreakdown(baseSalary: baseSalary, level: level)
        
        return bonusPayslip
    }
    
    // MARK: - PDF Generation
    
    /// Creates a PDF document for a corporate payslip
    static func corporatePayslipPDF(
        payslip: PayslipItem? = nil,
        level: CorporateLevel = .manager
    ) -> PDFDocument {
        let actualPayslip = payslip ?? standardCorporatePayslip(level: level)
        return TestDataGenerator.samplePayslipPDF(
            name: actualPayslip.name,
            rank: level.rawValue,
            id: actualPayslip.accountNumber,
            month: actualPayslip.month,
            year: actualPayslip.year,
            credits: actualPayslip.credits,
            debits: actualPayslip.debits,
            dsop: actualPayslip.dsop,
            tax: actualPayslip.tax
        )
    }
    
    // MARK: - Helper Methods
    
    /// Calculates base salary based on corporate level and years of service
    private static func baseSalaryForLevel(_ level: CorporateLevel, serviceYears: Int) -> Double {
        let baseSalary: Double
        
        switch level {
        case .intern:
            baseSalary = 30000.0
        case .associate:
            baseSalary = 50000.0
        case .seniorAssociate:
            baseSalary = 75000.0
        case .manager:
            baseSalary = 100000.0
        case .seniorManager:
            baseSalary = 130000.0
        case .director:
            baseSalary = 180000.0
        case .vicePresident:
            baseSalary = 250000.0
        case .cSuite:
            baseSalary = 350000.0
        }
        
        // Add increment for years of service
        let experienceMultiplier = min(1.0 + (Double(serviceYears) * 0.03), 1.3)
        return baseSalary * experienceMultiplier
    }
    
    /// Calculates standard corporate allowances based on level and department
    private static func corporateAllowances(forLevel level: CorporateLevel, department: CorporateDepartment) -> Double {
        let levelMultiplier: Double
        
        switch level {
        case .intern, .associate:
            levelMultiplier = 0.10
        case .seniorAssociate, .manager:
            levelMultiplier = 0.15
        case .seniorManager, .director:
            levelMultiplier = 0.20
        case .vicePresident, .cSuite:
            levelMultiplier = 0.25
        }
        
        let baseSalary = baseSalaryForLevel(level, serviceYears: 0)
        
        // Add department-specific allowance
        let departmentAllowance: Double
        switch department {
        case .technology:
            departmentAllowance = baseSalary * 0.05 // Tech skills premium
        case .sales:
            departmentAllowance = baseSalary * 0.04 // Sales incentive
        case .finance:
            departmentAllowance = baseSalary * 0.03 // Financial expertise
        case .marketing, .humanResources, .operations, .legal, .research:
            departmentAllowance = baseSalary * 0.02
        }
        
        return (baseSalary * levelMultiplier) + departmentAllowance
    }
    
    /// Calculates standard corporate deductions
    private static func corporateDeductions(baseSalary: Double, level: CorporateLevel) -> Double {
        // Standard deductions like health insurance, retirement contributions, etc.
        let baseDeductionRate = 0.08
        
        // Higher levels might have higher benefit costs
        let levelAdjustment: Double
        switch level {
        case .intern, .associate, .seniorAssociate:
            levelAdjustment = 0.0
        case .manager, .seniorManager:
            levelAdjustment = 0.01
        case .director, .vicePresident, .cSuite:
            levelAdjustment = 0.02
        }
        
        return baseSalary * (baseDeductionRate + levelAdjustment)
    }
    
    /// Calculates pension contribution
    private static func calculatePensionContribution(baseSalary: Double, level: CorporateLevel) -> Double {
        // Base contribution rate
        var rate = 0.05
        
        // Higher levels often have higher contribution rates
        switch level {
        case .seniorManager, .director:
            rate = 0.06
        case .vicePresident, .cSuite:
            rate = 0.07
        default:
            break
        }
        
        return baseSalary * rate
    }
    
    /// Calculates income tax based on salary and level
    private static func calculateTax(baseSalary: Double, level: CorporateLevel) -> Double {
        let taxRate: Double
        
        switch level {
        case .intern, .associate:
            taxRate = 0.15
        case .seniorAssociate, .manager:
            taxRate = 0.20
        case .seniorManager, .director:
            taxRate = 0.25
        case .vicePresident, .cSuite:
            taxRate = 0.30
        }
        
        return baseSalary * taxRate
    }
    
    /// Calculates bonus amount based on salary, level, and type
    private static func calculateBonus(baseSalary: Double, level: CorporateLevel, type: BonusType, multiplier: Double) -> Double {
        let baseMultiplier: Double
        
        switch type {
        case .performance:
            baseMultiplier = 0.10
        case .annual:
            baseMultiplier = 0.15
        case .retention:
            baseMultiplier = 0.20
        case .signing:
            baseMultiplier = 0.25
        case .projectCompletion:
            baseMultiplier = 0.10
        }
        
        // Level adjustment - higher levels typically get larger bonuses (as percentage of salary)
        let levelAdjustment: Double
        switch level {
        case .intern, .associate:
            levelAdjustment = 0.0
        case .seniorAssociate, .manager:
            levelAdjustment = 0.05
        case .seniorManager, .director:
            levelAdjustment = 0.10
        case .vicePresident, .cSuite:
            levelAdjustment = 0.15
        }
        
        return baseSalary * (baseMultiplier + levelAdjustment) * multiplier
    }
    
    /// Creates a breakdown of corporate credits/allowances
    private static func generateCorporateCreditBreakdown(level: CorporateLevel, serviceYears: Int, department: CorporateDepartment) -> [String: Double] {
        let baseSalary = baseSalaryForLevel(level, serviceYears: 0)
        let experienceIncrement = baseSalary * (min(Double(serviceYears) * 0.03, 0.3))
        
        var breakdown: [String: Double] = [
            "Base Salary": baseSalary,
            "Experience Increment": experienceIncrement,
            "Housing Allowance": baseSalary * 0.08,
            "Transportation Allowance": baseSalary * 0.04,
            "Meal Allowance": baseSalary * 0.02
        ]
        
        // Add level-specific allowances
        switch level {
        case .manager, .seniorManager:
            breakdown["Management Allowance"] = baseSalary * 0.05
        case .director:
            breakdown["Management Allowance"] = baseSalary * 0.05
            breakdown["Leadership Bonus"] = baseSalary * 0.07
        case .vicePresident, .cSuite:
            breakdown["Management Allowance"] = baseSalary * 0.05
            breakdown["Leadership Bonus"] = baseSalary * 0.07
            breakdown["Executive Benefits"] = baseSalary * 0.10
        default:
            break
        }
        
        // Add department-specific allowances
        switch department {
        case .technology:
            breakdown["Tech Skill Allowance"] = baseSalary * 0.05
            if level >= .manager {
                breakdown["Technical Leadership"] = baseSalary * 0.03
            }
        case .sales:
            breakdown["Sales Incentive"] = baseSalary * 0.04
            breakdown["Client Relationship Allowance"] = baseSalary * 0.03
        case .finance:
            breakdown["Financial Expertise"] = baseSalary * 0.03
            if level >= .seniorManager {
                breakdown["Financial Decision Making"] = baseSalary * 0.04
            }
        case .marketing:
            breakdown["Marketing Initiative"] = baseSalary * 0.02
            breakdown["Brand Development"] = baseSalary * 0.02
        case .humanResources:
            breakdown["People Management"] = baseSalary * 0.02
            breakdown["Talent Development"] = baseSalary * 0.02
        case .operations:
            breakdown["Operational Efficiency"] = baseSalary * 0.02
            breakdown["Process Improvement"] = baseSalary * 0.02
        case .legal:
            breakdown["Legal Expertise"] = baseSalary * 0.03
            breakdown["Compliance Management"] = baseSalary * 0.02
        case .research:
            breakdown["Research & Development"] = baseSalary * 0.03
            breakdown["Innovation Incentive"] = baseSalary * 0.03
        }
        
        return breakdown
    }
    
    /// Creates a breakdown of corporate debits/deductions
    private static func generateCorporateDebitBreakdown(baseSalary: Double, level: CorporateLevel) -> [String: Double] {
        let taxAmount = calculateTax(baseSalary: baseSalary, level: level)
        let pensionAmount = calculatePensionContribution(baseSalary: baseSalary, level: level)
        
        var deductions: [String: Double] = [
            "Income Tax": taxAmount,
            "Retirement Plan": pensionAmount,
            "Health Insurance": baseSalary * 0.03,
            "Life Insurance": baseSalary * 0.01,
            "Professional Association": baseSalary * 0.005
        ]
        
        // Add level-specific deductions
        switch level {
        case .manager, .seniorManager:
            deductions["Enhanced Health Plan"] = baseSalary * 0.01
        case .director:
            deductions["Enhanced Health Plan"] = baseSalary * 0.01
            deductions["Executive Insurance"] = baseSalary * 0.015
        case .vicePresident, .cSuite:
            deductions["Enhanced Health Plan"] = baseSalary * 0.01
            deductions["Executive Insurance"] = baseSalary * 0.015
        default:
            break
        }
        
        return deductions
    }
    
    // MARK: - Batch Generation
    
    /// Generates an array of various corporate payslips
    static func batchOfCorporatePayslips() -> [PayslipItem] {
        return [
            standardCorporatePayslip(level: .intern, name: "Alex Thompson", serviceYears: 1, department: .technology),
            standardCorporatePayslip(level: .associate, name: "Jessica Lee", serviceYears: 2, department: .marketing),
            standardCorporatePayslip(level: .seniorAssociate, name: "David Wilson", serviceYears: 4, department: .operations),
            standardCorporatePayslip(level: .manager, name: "Emily Davis", serviceYears: 6, department: .humanResources),
            standardCorporatePayslip(level: .seniorManager, name: "Robert Johnson", serviceYears: 9, department: .sales),
            standardCorporatePayslip(level: .director, name: "Michelle Taylor", serviceYears: 12, department: .finance),
            standardCorporatePayslip(level: .vicePresident, name: "Christopher Brown", serviceYears: 15, department: .legal),
            standardCorporatePayslip(level: .cSuite, name: "Patricia Martinez", serviceYears: 20, department: .research),
            bonusPayslip(level: .manager, name: "Andrew Smith", serviceYears: 7, department: .technology, bonusType: .performance),
            bonusPayslip(level: .director, name: "Jennifer Williams", serviceYears: 10, department: .sales, bonusType: .annual, bonusMultiplier: 1.5)
        ]
    }
    
    // MARK: - Types
    
    /// Corporate level enumeration
    enum CorporateLevel: String, Comparable {
        case intern = "Intern"
        case associate = "Associate"
        case seniorAssociate = "Senior Associate"
        case manager = "Manager"
        case seniorManager = "Senior Manager"
        case director = "Director"
        case vicePresident = "Vice President"
        case cSuite = "C-Suite Executive"
        
        // Implementation of Comparable protocol
        static func < (lhs: CorporateLevel, rhs: CorporateLevel) -> Bool {
            let levelOrder: [CorporateLevel] = [.intern, .associate, .seniorAssociate, .manager, 
                                                .seniorManager, .director, .vicePresident, .cSuite]
            
            guard let lhsIndex = levelOrder.firstIndex(of: lhs),
                  let rhsIndex = levelOrder.firstIndex(of: rhs) else {
                return false
            }
            
            return lhsIndex < rhsIndex
        }
    }
    
    /// Corporate department enumeration
    enum CorporateDepartment {
        case technology
        case finance
        case sales
        case marketing
        case humanResources
        case operations
        case legal
        case research
    }
    
    /// Bonus type enumeration
    enum BonusType: String {
        case performance = "Performance Bonus"
        case annual = "Annual Bonus"
        case retention = "Retention Bonus"
        case signing = "Signing Bonus"
        case projectCompletion = "Project Completion Bonus"
    }
} 