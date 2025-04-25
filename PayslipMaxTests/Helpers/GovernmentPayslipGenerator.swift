import Foundation
import PDFKit
@testable import PayslipMax

/// Generator for government payslip test data
class GovernmentPayslipGenerator {
    
    // MARK: - Standard Government Payslips
    
    /// Creates a standard government employee payslip with common allowances and deductions
    static func standardGovernmentPayslip(
        id: UUID = UUID(),
        month: String = "January",
        year: Int = 2023,
        gradeLevel: GradeLevel = .level10,
        name: String = "John Smith",
        serviceYears: Int = 5,
        department: Department = .finance
    ) -> PayslipItem {
        let baseSalary = baseSalaryForGradeLevel(gradeLevel, serviceYears: serviceYears)
        let standardAllowances = governmentAllowances(forGradeLevel: gradeLevel, department: department)
        let standardDeductions = governmentDeductions(forGradeLevel: gradeLevel, baseSalary: baseSalary)
        
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: baseSalary + standardAllowances,
            debits: standardDeductions,
            dsop: calculatePensionContribution(baseSalary: baseSalary),
            tax: calculateTax(baseSalary: baseSalary, gradeLevel: gradeLevel),
            name: name,
            accountNumber: "GOV-\(String(format: "%04d", Int.random(in: 1000...9999)))",
            panNumber: "GOVT\(String(format: "%05d", Int.random(in: 10000...99999)))G",
            creditBreakdown: generateGovernmentCreditBreakdown(forGradeLevel: gradeLevel, serviceYears: serviceYears, department: department),
            debitBreakdown: generateGovernmentDebitBreakdown(forGradeLevel: gradeLevel, baseSalary: baseSalary)
        )
    }
    
    /// Creates a special government payslip for overtime, holidays, or special duty
    static func specialDutyPayslip(
        id: UUID = UUID(),
        month: String = "February",
        year: Int = 2023,
        gradeLevel: GradeLevel = .level12,
        name: String = "Jane Wilson",
        serviceYears: Int = 8,
        department: Department = .defense,
        specialDutyType: SpecialDutyType = .overtime,
        additionalHours: Int = 40
    ) -> PayslipItem {
        let baseSalary = baseSalaryForGradeLevel(gradeLevel, serviceYears: serviceYears)
        let standardAllowances = governmentAllowances(forGradeLevel: gradeLevel, department: department)
        let specialDutyAmount = calculateSpecialDutyPay(baseSalary: baseSalary, dutyType: specialDutyType, additionalHours: additionalHours)
        let standardDeductions = governmentDeductions(forGradeLevel: gradeLevel, baseSalary: baseSalary)
        
        let totalCredits = baseSalary + standardAllowances + specialDutyAmount
        let totalDebits = standardDeductions
        let taxAmount = calculateTax(baseSalary: baseSalary, gradeLevel: gradeLevel) + (specialDutyAmount * 0.2)
        
        var creditBreakdown = generateGovernmentCreditBreakdown(forGradeLevel: gradeLevel, serviceYears: serviceYears, department: department)
        creditBreakdown[specialDutyType.rawValue] = specialDutyAmount
        
        var debitBreakdown = generateGovernmentDebitBreakdown(forGradeLevel: gradeLevel, baseSalary: baseSalary)
        debitBreakdown["Additional Tax"] = specialDutyAmount * 0.2
        
        return PayslipItem(
            id: id,
            month: month,
            year: year,
            credits: totalCredits,
            debits: totalDebits,
            dsop: calculatePensionContribution(baseSalary: baseSalary),
            tax: taxAmount,
            name: name,
            accountNumber: "GOV-\(String(format: "%04d", Int.random(in: 1000...9999)))",
            panNumber: "GOVT\(String(format: "%05d", Int.random(in: 10000...99999)))G",
            creditBreakdown: creditBreakdown,
            debitBreakdown: debitBreakdown
        )
    }
    
    // MARK: - PDF Generation
    
    /// Creates a PDF document for a government payslip
    static func governmentPayslipPDF(
        payslip: PayslipItem? = nil,
        gradeLevel: GradeLevel = .level10
    ) -> PDFDocument {
        let actualPayslip = payslip ?? standardGovernmentPayslip(gradeLevel: gradeLevel)
        return TestDataGenerator.generatePDFDocument(
            forPayslip: actualPayslip,
            withTitle: "Government Payslip - \(gradeLevel.rawValue)"
        )
    }
    
    // MARK: - Helper Methods
    
    /// Calculates base salary based on grade level and years of service
    private static func baseSalaryForGradeLevel(_ gradeLevel: GradeLevel, serviceYears: Int) -> Double {
        let baseSalary: Double
        
        switch gradeLevel {
        case .level1:
            baseSalary = 25000.0
        case .level5:
            baseSalary = 38000.0
        case .level10:
            baseSalary = 52000.0
        case .level12:
            baseSalary = 68000.0
        case .level15:
            baseSalary = 85000.0
        case .level20:
            baseSalary = 110000.0
        }
        
        // Add increment for years of service
        let experienceMultiplier = min(1.0 + (Double(serviceYears) * 0.01), 1.3)
        return baseSalary * experienceMultiplier
    }
    
    /// Calculates standard government allowances based on grade level
    private static func governmentAllowances(forGradeLevel gradeLevel: GradeLevel, department: Department) -> Double {
        let gradeLevelMultiplier: Double
        
        switch gradeLevel {
        case .level1:
            gradeLevelMultiplier = 0.15
        case .level5:
            gradeLevelMultiplier = 0.18
        case .level10:
            gradeLevelMultiplier = 0.22
        case .level12:
            gradeLevelMultiplier = 0.25
        case .level15:
            gradeLevelMultiplier = 0.28
        case .level20:
            gradeLevelMultiplier = 0.32
        }
        
        let baseSalary = baseSalaryForGradeLevel(gradeLevel, serviceYears: 0)
        
        // Add department-specific allowance
        let departmentAllowance: Double
        switch department {
        case .defense, .intelligence:
            departmentAllowance = baseSalary * 0.08
        case .healthcare:
            departmentAllowance = baseSalary * 0.06
        case .education:
            departmentAllowance = baseSalary * 0.05
        case .finance, .justice:
            departmentAllowance = baseSalary * 0.04
        case .transportation, .energy:
            departmentAllowance = baseSalary * 0.07
        }
        
        return (baseSalary * gradeLevelMultiplier) + departmentAllowance
    }
    
    /// Calculates standard government deductions based on grade level
    private static func governmentDeductions(forGradeLevel gradeLevel: GradeLevel, baseSalary: Double) -> Double {
        // Standard deductions like health insurance, retirement contributions, etc.
        return baseSalary * 0.08
    }
    
    /// Calculates pension contribution for government employees
    private static func calculatePensionContribution(baseSalary: Double) -> Double {
        return baseSalary * 0.07 // Government pension contribution rate
    }
    
    /// Calculates income tax based on salary and grade level
    private static func calculateTax(baseSalary: Double, gradeLevel: GradeLevel) -> Double {
        let taxRate: Double
        
        switch gradeLevel {
        case .level1, .level5:
            taxRate = 0.12
        case .level10, .level12:
            taxRate = 0.20
        case .level15, .level20:
            taxRate = 0.25
        }
        
        return baseSalary * taxRate
    }
    
    /// Calculates special duty pay based on salary and duty type
    private static func calculateSpecialDutyPay(baseSalary: Double, dutyType: SpecialDutyType, additionalHours: Int) -> Double {
        let hourlyRate = baseSalary / 160.0 // Assuming 160 hours per month
        let baseMultiplier: Double
        
        switch dutyType {
        case .overtime:
            baseMultiplier = 1.5
        case .holiday:
            baseMultiplier = 2.0
        case .hazardDuty:
            baseMultiplier = 2.5
        case .remoteLocation:
            baseMultiplier = 2.0
        }
        
        return hourlyRate * baseMultiplier * Double(additionalHours)
    }
    
    /// Creates a breakdown of government credits/allowances
    private static func generateGovernmentCreditBreakdown(forGradeLevel gradeLevel: GradeLevel, serviceYears: Int, department: Department) -> [String: Double] {
        let baseSalary = baseSalaryForGradeLevel(gradeLevel, serviceYears: 0)
        let experienceIncrement = baseSalary * (min(Double(serviceYears) * 0.01, 0.3))
        
        var breakdown: [String: Double] = [
            "Base Salary": baseSalary,
            "Experience Increment": experienceIncrement,
            "Dearness Allowance": baseSalary * 0.05,
            "House Rent Allowance": baseSalary * 0.08,
            "Transport Allowance": baseSalary * 0.03
        ]
        
        // Add grade-specific allowances
        switch gradeLevel {
        case .level10, .level12, .level15, .level20:
            breakdown["Grade Pay"] = baseSalary * 0.03
        case .level15, .level20:
            breakdown["Senior Allowance"] = baseSalary * 0.04
        case .level20:
            breakdown["Executive Allowance"] = baseSalary * 0.06
        default:
            break
        }
        
        // Add department-specific allowances
        switch department {
        case .defense, .intelligence:
            breakdown["Risk Allowance"] = baseSalary * 0.05
            breakdown["Special Duty Allowance"] = baseSalary * 0.03
        case .healthcare:
            breakdown["Medical Allowance"] = baseSalary * 0.04
            breakdown["Professional Allowance"] = baseSalary * 0.02
        case .education:
            breakdown["Academic Allowance"] = baseSalary * 0.03
            breakdown["Research Allowance"] = baseSalary * 0.02
        case .finance, .justice:
            breakdown["Professional Allowance"] = baseSalary * 0.04
        case .transportation, .energy:
            breakdown["Field Duty Allowance"] = baseSalary * 0.04
            breakdown["Technical Allowance"] = baseSalary * 0.03
        }
        
        return breakdown
    }
    
    /// Creates a breakdown of government debits/deductions
    private static func generateGovernmentDebitBreakdown(forGradeLevel gradeLevel: GradeLevel, baseSalary: Double) -> [String: Double] {
        return [
            "Income Tax": calculateTax(baseSalary: baseSalary, gradeLevel: gradeLevel),
            "Government Pension Scheme": calculatePensionContribution(baseSalary: baseSalary),
            "Health Insurance": baseSalary * 0.02,
            "Professional Tax": baseSalary * 0.01,
            "Group Insurance": baseSalary * 0.015,
            "Welfare Fund": baseSalary * 0.005,
            "Union Dues": baseSalary * 0.01
        ]
    }
    
    // MARK: - Batch Generation
    
    /// Generates an array of various government payslips
    static func batchOfGovernmentPayslips() -> [PayslipItem] {
        return [
            standardGovernmentPayslip(gradeLevel: .level1, name: "Thomas Brown", serviceYears: 2, department: .transportation),
            standardGovernmentPayslip(gradeLevel: .level5, name: "Maria Lopez", serviceYears: 4, department: .education),
            standardGovernmentPayslip(gradeLevel: .level10, name: "Robert Johnson", serviceYears: 7, department: .finance),
            standardGovernmentPayslip(gradeLevel: .level12, name: "Sarah Davis", serviceYears: 10, department: .justice),
            standardGovernmentPayslip(gradeLevel: .level15, name: "James Wilson", serviceYears: 15, department: .defense),
            standardGovernmentPayslip(gradeLevel: .level20, name: "Emma Taylor", serviceYears: 20, department: .intelligence),
            specialDutyPayslip(gradeLevel: .level10, name: "Michael Clark", serviceYears: 6, department: .transportation, specialDutyType: .overtime),
            specialDutyPayslip(gradeLevel: .level15, name: "Jennifer Lee", serviceYears: 12, department: .defense, specialDutyType: .hazardDuty),
            specialDutyPayslip(gradeLevel: .level5, name: "David Miller", serviceYears: 3, department: .healthcare, specialDutyType: .holiday),
            specialDutyPayslip(gradeLevel: .level20, name: "Lisa Wang", serviceYears: 18, department: .energy, specialDutyType: .remoteLocation)
        ]
    }
    
    // MARK: - Types
    
    /// Government grade level enumeration
    enum GradeLevel: String {
        case level1 = "Grade Level 1"
        case level5 = "Grade Level 5"
        case level10 = "Grade Level 10"
        case level12 = "Grade Level 12"
        case level15 = "Grade Level 15"
        case level20 = "Grade Level 20"
    }
    
    /// Department enumeration
    enum Department {
        case defense
        case finance
        case education
        case healthcare
        case justice
        case transportation
        case energy
        case intelligence
    }
    
    /// Special duty type enumeration
    enum SpecialDutyType: String {
        case overtime = "Overtime Pay"
        case holiday = "Holiday Pay"
        case hazardDuty = "Hazard Duty Pay"
        case remoteLocation = "Remote Location Pay"
    }
} 