import Foundation
import PDFKit
@testable import PayslipMax

/// Generator for public sector payslip test data
class PublicSectorPayslipGenerator {
    
    // MARK: - Standard Public Sector Payslips
    
    /// Creates a standard public sector payslip with relevant allowances and deductions
    static func standardPublicSectorPayslip(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        grade: GovernmentGrade = .gs12,
        name: String = "Daniel Thompson",
        serviceYears: Int = 10,
        department: GovernmentDepartment = .interior
    ) -> PayslipItem {
        let baseSalary = baseSalaryForGrade(grade, serviceYears: serviceYears)
        let standardAllowances = governmentAllowances(forGrade: grade, department: department)
        let standardDeductions = governmentDeductions(baseSalary: baseSalary, grade: grade)
        
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: baseSalary + standardAllowances,
            debits: standardDeductions,
            dsop: calculatePensionContribution(baseSalary: baseSalary, grade: grade),
            tax: calculateTax(baseSalary: baseSalary, grade: grade),
            name: name,
            accountNumber: "GOV-\(String(format: "%04d", Int.random(in: 1000...9999)))",
            panNumber: "GOVT\(String(format: "%05d", Int.random(in: 10000...99999)))G",
        )
    }
    
    /// Creates a payslip for special governmental assignment with additional allowances
    static func specialAssignmentPayslip(
        id: UUID = UUID(),
        month: String = "March",
        year: Int = 2023,
        grade: GovernmentGrade = .gs13,
        name: String = "Catherine Parker",
        serviceYears: Int = 15,
        department: GovernmentDepartment = .state,
        assignmentType: SpecialAssignmentType = .overseas,
        locationFactor: Double = 1.25
    ) -> PayslipItem {
        let baseSalary = baseSalaryForGrade(grade, serviceYears: serviceYears)
        let standardAllowances = governmentAllowances(forGrade: grade, department: department)
        let specialAllowance = calculateSpecialAssignmentAllowance(
            baseSalary: baseSalary, 
            grade: grade, 
            type: assignmentType, 
            locationFactor: locationFactor
        )
        let standardDeductions = governmentDeductions(baseSalary: baseSalary, grade: grade)
        
        let totalCredits = baseSalary + standardAllowances + specialAllowance
        
        var creditBreakdown = generateGovernmentCreditBreakdown(grade: grade, serviceYears: serviceYears, department: department)
        creditBreakdown[assignmentType.rawValue + " Allowance"] = specialAllowance
        
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: totalCredits,
            debits: standardDeductions,
            dsop: calculatePensionContribution(baseSalary: baseSalary, grade: grade),
            tax: calculateTax(baseSalary: baseSalary, grade: grade),
            name: name,
            accountNumber: "GOV-\(String(format: "%04d", Int.random(in: 1000...9999)))",
            panNumber: "GOVT\(String(format: "%05d", Int.random(in: 10000...99999)))G",
        )
    }
    
    // MARK: - PDF Generation
    
    /// Creates a PDF document for a public sector payslip
    static func publicSectorPayslipPDF(
        payslip: PayslipItem? = nil,
        grade: GovernmentGrade = .gs12
    ) -> PDFDocument {
        let actualPayslip = payslip ?? standardPublicSectorPayslip(grade: grade)
        return TestDataGenerator.samplePayslipPDF(
            name: actualPayslip.name,
            rank: "Grade \(grade.rawValue)",
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
    
    /// Calculates base salary based on government grade and years of service
    private static func baseSalaryForGrade(_ grade: GovernmentGrade, serviceYears: Int) -> Double {
        let baseSalary: Double
        
        switch grade {
        case .gs1:
            baseSalary = 20000.0
        case .gs5:
            baseSalary = 30000.0
        case .gs7:
            baseSalary = 35000.0
        case .gs9:
            baseSalary = 45000.0
        case .gs11:
            baseSalary = 55000.0
        case .gs12:
            baseSalary = 65000.0
        case .gs13:
            baseSalary = 78000.0
        case .gs14:
            baseSalary = 92000.0
        case .gs15:
            baseSalary = 110000.0
        case .ses:
            baseSalary = 140000.0
        }
        
        // Add step increments based on years of service
        // Government typically has steps within each grade based on years of service
        let stepMultiplier = min(1.0 + (Double(serviceYears) * 0.02), 1.4)
        return baseSalary * stepMultiplier
    }
    
    /// Calculates standard government allowances based on grade and department
    private static func governmentAllowances(forGrade grade: GovernmentGrade, department: GovernmentDepartment) -> Double {
        let gradeMultiplier: Double
        
        switch grade {
        case .gs1, .gs5, .gs7:
            gradeMultiplier = 0.05
        case .gs9, .gs11, .gs12:
            gradeMultiplier = 0.07
        case .gs13, .gs14, .gs15:
            gradeMultiplier = 0.09
        case .ses:
            gradeMultiplier = 0.12
        }
        
        let baseSalary = baseSalaryForGrade(grade, serviceYears: 0)
        
        // Add department-specific allowance
        let departmentAllowance: Double
        switch department {
        case .state, .defense:
            departmentAllowance = baseSalary * 0.05  // Higher risk or overseas work
        case .treasury, .justice:
            departmentAllowance = baseSalary * 0.04  // Specialized financial or legal expertise
        case .interior, .agriculture, .commerce, .labor, .transportation, .energy, .education, .veterans:
            departmentAllowance = baseSalary * 0.02
        case .healthAndHumanServices, .housingAndUrbanDevelopment:
            departmentAllowance = baseSalary * 0.03
        }
        
        return (baseSalary * gradeMultiplier) + departmentAllowance
    }
    
    /// Calculates standard government deductions
    private static func governmentDeductions(baseSalary: Double, grade: GovernmentGrade) -> Double {
        // Standard deductions like federal employee health benefits, etc.
        let baseDeductionRate = 0.07
        
        // Higher grades might have higher benefit costs
        let gradeAdjustment: Double
        switch grade {
        case .gs1, .gs5, .gs7, .gs9:
            gradeAdjustment = 0.0
        case .gs11, .gs12, .gs13:
            gradeAdjustment = 0.01
        case .gs14, .gs15, .ses:
            gradeAdjustment = 0.02
        }
        
        return baseSalary * (baseDeductionRate + gradeAdjustment)
    }
    
    /// Calculates government pension contribution (FERS, etc.)
    private static func calculatePensionContribution(baseSalary: Double, grade: GovernmentGrade) -> Double {
        // Federal employees typically contribute to FERS or similar systems
        return baseSalary * 0.08
    }
    
    /// Calculates income tax based on salary and grade
    private static func calculateTax(baseSalary: Double, grade: GovernmentGrade) -> Double {
        let taxRate: Double
        
        switch grade {
        case .gs1, .gs5, .gs7:
            taxRate = 0.12
        case .gs9, .gs11, .gs12:
            taxRate = 0.22
        case .gs13, .gs14:
            taxRate = 0.24
        case .gs15, .ses:
            taxRate = 0.32
        }
        
        return baseSalary * taxRate
    }
    
    /// Calculates special assignment allowance
    private static func calculateSpecialAssignmentAllowance(
        baseSalary: Double,
        grade: GovernmentGrade,
        type: SpecialAssignmentType,
        locationFactor: Double
    ) -> Double {
        let baseAllowanceRate: Double
        
        switch type {
        case .overseas:
            baseAllowanceRate = 0.20
        case .hardship:
            baseAllowanceRate = 0.25
        case .danger:
            baseAllowanceRate = 0.30
        case .temporary:
            baseAllowanceRate = 0.15
        case .technical:
            baseAllowanceRate = 0.10
        }
        
        // Grade adjustment - higher grades might get proportionally different allowances
        let gradeAdjustment: Double
        switch grade {
        case .gs1, .gs5, .gs7, .gs9:
            gradeAdjustment = 0.0
        case .gs11, .gs12, .gs13:
            gradeAdjustment = 0.02
        case .gs14, .gs15, .ses:
            gradeAdjustment = 0.04
        }
        
        return baseSalary * (baseAllowanceRate + gradeAdjustment) * locationFactor
    }
    
    /// Creates a breakdown of government credits/allowances
    private static func generateGovernmentCreditBreakdown(grade: GovernmentGrade, serviceYears: Int, department: GovernmentDepartment) -> [String: Double] {
        let baseSalary = baseSalaryForGrade(grade, serviceYears: 0)
        let stepIncrement = baseSalary * (min(Double(serviceYears) * 0.02, 0.4))
        
        var breakdown: [String: Double] = [
            "Base Salary": baseSalary,
            "Step Increment": stepIncrement,
            "Locality Pay": baseSalary * 0.15,  // Standard for many government positions
            "Cost of Living Adjustment": baseSalary * 0.02
        ]
        
        // Add grade-specific allowances
        switch grade {
        case .gs11, .gs12, .gs13, .gs14, .gs15:
            breakdown["Position Supplement"] = baseSalary * 0.03
        case .gs13, .gs14, .gs15:
            breakdown["Responsibility Premium"] = baseSalary * 0.05
        case .ses:
            breakdown["Executive Allowance"] = baseSalary * 0.08
        default:
            break
        }
        
        // Add department-specific allowances
        switch department {
        case .state:
            breakdown["Foreign Service Premium"] = baseSalary * 0.05
            breakdown["Language Proficiency"] = baseSalary * 0.03
        case .defense:
            breakdown["National Security Premium"] = baseSalary * 0.05
            if grade >= .gs11 {
                breakdown["Command Responsibility"] = baseSalary * 0.04
            }
        case .treasury:
            breakdown["Financial Expertise"] = baseSalary * 0.04
            breakdown["Fiscal Responsibility"] = baseSalary * 0.02
        case .justice:
            breakdown["Legal Expertise"] = baseSalary * 0.04
            breakdown["Enforcement Allowance"] = baseSalary * 0.03
        case .interior:
            breakdown["Field Work Allowance"] = baseSalary * 0.02
            breakdown["Resource Management"] = baseSalary * 0.02
        case .agriculture:
            breakdown["Rural Development"] = baseSalary * 0.02
            breakdown["Food Safety Premium"] = baseSalary * 0.02
        case .commerce:
            breakdown["Economic Development"] = baseSalary * 0.02
            breakdown["Trade Expertise"] = baseSalary * 0.02
        case .labor:
            breakdown["Labor Relations"] = baseSalary * 0.02
            breakdown["Workforce Development"] = baseSalary * 0.02
        case .healthAndHumanServices:
            breakdown["Public Health Premium"] = baseSalary * 0.03
            breakdown["Medical Research"] = baseSalary * 0.02
        case .housingAndUrbanDevelopment:
            breakdown["Urban Planning"] = baseSalary * 0.02
            breakdown["Community Development"] = baseSalary * 0.03
        case .transportation:
            breakdown["Infrastructure Planning"] = baseSalary * 0.02
            breakdown["Safety Oversight"] = baseSalary * 0.02
        case .energy:
            breakdown["Scientific Research"] = baseSalary * 0.03
            breakdown["Technical Operations"] = baseSalary * 0.02
        case .education:
            breakdown["Educational Development"] = baseSalary * 0.02
            breakdown["Program Administration"] = baseSalary * 0.02
        case .veterans:
            breakdown["Veteran Service"] = baseSalary * 0.03
            breakdown["Benefits Administration"] = baseSalary * 0.02
        }
        
        return breakdown
    }
    
    /// Creates a breakdown of government debits/deductions
    private static func generateGovernmentDebitBreakdown(baseSalary: Double, grade: GovernmentGrade) -> [String: Double] {
        let taxAmount = calculateTax(baseSalary: baseSalary, grade: grade)
        let pensionAmount = calculatePensionContribution(baseSalary: baseSalary, grade: grade)
        
        var deductions: [String: Double] = [
            "Income Tax": taxAmount,
            "FERS Contribution": pensionAmount,
            "Federal Health Benefits": baseSalary * 0.03,
            "Life Insurance": baseSalary * 0.01,
            "Medicare": baseSalary * 0.0145,
            "Social Security": baseSalary * 0.062
        ]
        
        // Add grade-specific deductions
        switch grade {
        case .gs11, .gs12, .gs13, .gs14, .gs15, .ses:
            deductions["Thrift Savings Plan"] = baseSalary * 0.05
        case .gs14, .gs15, .ses:
            deductions["Executive Life Insurance"] = baseSalary * 0.015
        default:
            break
        }
        
        return deductions
    }
    
    // MARK: - Batch Generation
    
    /// Generates an array of various government payslips
    static func batchOfPublicSectorPayslips() -> [PayslipItem] {
        return [
            standardPublicSectorPayslip(grade: .gs5, name: "James Wilson", serviceYears: 2, department: .interior),
            standardPublicSectorPayslip(grade: .gs7, name: "Sarah Martinez", serviceYears: 4, department: .agriculture),
            standardPublicSectorPayslip(grade: .gs9, name: "Robert Taylor", serviceYears: 6, department: .commerce),
            standardPublicSectorPayslip(grade: .gs11, name: "Emily Brown", serviceYears: 8, department: .labor),
            standardPublicSectorPayslip(grade: .gs12, name: "Michael Lewis", serviceYears: 10, department: .transportation),
            standardPublicSectorPayslip(grade: .gs13, name: "Jennifer Harris", serviceYears: 15, department: .energy),
            standardPublicSectorPayslip(grade: .gs14, name: "David Rodriguez", serviceYears: 20, department: .education),
            standardPublicSectorPayslip(grade: .gs15, name: "Lisa Johnson", serviceYears: 25, department: .veterans),
            specialAssignmentPayslip(grade: .gs12, name: "Jason Morgan", serviceYears: 12, department: .state, assignmentType: .overseas),
            specialAssignmentPayslip(grade: .gs14, name: "Amanda Clark", serviceYears: 18, department: .defense, assignmentType: .hardship, locationFactor: 1.35)
        ]
    }
    
    // MARK: - Types
    
    /// Government grade enumeration (General Schedule)
    enum GovernmentGrade: String, Comparable {
        case gs1 = "GS-1"
        case gs5 = "GS-5"
        case gs7 = "GS-7"
        case gs9 = "GS-9"
        case gs11 = "GS-11"
        case gs12 = "GS-12"
        case gs13 = "GS-13"
        case gs14 = "GS-14"
        case gs15 = "GS-15"
        case ses = "SES"  // Senior Executive Service
        
        // Implementation of Comparable protocol
        static func < (lhs: GovernmentGrade, rhs: GovernmentGrade) -> Bool {
            let gradeOrder: [GovernmentGrade] = [.gs1, .gs5, .gs7, .gs9, .gs11,
                                                 .gs12, .gs13, .gs14, .gs15, .ses]
            
            guard let lhsIndex = gradeOrder.firstIndex(of: lhs),
                  let rhsIndex = gradeOrder.firstIndex(of: rhs) else {
                return false
            }
            
            return lhsIndex < rhsIndex
        }
    }
    
    /// Government department enumeration
    enum GovernmentDepartment {
        case state
        case treasury
        case defense
        case justice
        case interior
        case agriculture
        case commerce
        case labor
        case healthAndHumanServices
        case housingAndUrbanDevelopment
        case transportation
        case energy
        case education
        case veterans
    }
    
    /// Special assignment type enumeration
    enum SpecialAssignmentType: String {
        case overseas = "Overseas"
        case hardship = "Hardship"
        case danger = "Danger"
        case temporary = "Temporary"
        case technical = "Technical"
    }
} 