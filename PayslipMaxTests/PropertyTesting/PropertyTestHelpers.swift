import XCTest
import SwiftCheck
import PDFKit
@testable import PayslipMax

/// Helper utilities for property-based testing
enum PropertyTestHelpers {
    
    // MARK: - Custom Generators
    
    /// Creates a generator for valid month strings
    static var monthGenerator: Gen<String> {
        Gen<String>.fromElements(in: [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ])
    }
    
    /// Creates a generator for valid years (within a reasonable range)
    static var yearGenerator: Gen<Int> {
        Gen<Int>.choose((2000, 2030))
    }
    
    /// Creates a generator for reasonable credit amounts
    static var creditsGenerator: Gen<Double> {
        Gen<Double>.choose((100.0, 100000.0))
    }
    
    /// Creates a generator for reasonable debit amounts
    static var debitsGenerator: Gen<Double> {
        Gen<Double>.choose((10.0, 50000.0))
    }
    
    /// Creates a generator for reasonable tax amounts
    static var taxGenerator: Gen<Double?> {
        Gen<Double?>.fromOptional(Gen<Double>.choose((0.0, 30000.0)))
    }
    
    /// Creates a generator for reasonable pension contribution amounts
    static var dsopGenerator: Gen<Double?> {
        Gen<Double?>.fromOptional(Gen<Double>.choose((0.0, 15000.0)))
    }
    
    /// Creates a generator for plausible names
    static var nameGenerator: Gen<String> {
        let firstNames = ["John", "Jane", "Robert", "Sarah", "Michael", "Emily", 
                         "David", "Lisa", "William", "Mary", "James", "Patricia",
                         "Richard", "Jennifer", "Thomas", "Elizabeth", "Charles", "Susan"]
        
        let lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Miller",
                        "Davis", "Garcia", "Rodriguez", "Wilson", "Martinez", "Anderson",
                        "Taylor", "Thomas", "Moore", "Jackson", "Martin", "Lee"]
        
        return Gen<Int>.choose((0, firstNames.count - 1)).flatMap { firstIndex in
            return Gen<Int>.choose((0, lastNames.count - 1)).map { lastIndex in
                return "\(firstNames[firstIndex]) \(lastNames[lastIndex])"
            }
        }
    }
    
    // MARK: - Random PayslipItem Creation
    
    /// Creates a random valid PayslipItem
    static var randomPayslipGenerator: Gen<PayslipItem> {
        return Gen.compose { composer in
            let month = composer.generate(using: monthGenerator)
            let year = composer.generate(using: yearGenerator)
            let credits = composer.generate(using: creditsGenerator)
            let debits = composer.generate(using: debitsGenerator.suchThat { $0 <= credits })
            let dsop = composer.generate(using: dsopGenerator)
            let tax = composer.generate(using: taxGenerator)
            let name = composer.generate(using: nameGenerator)
            
            return PayslipItem(
                id: UUID(),
                month: month,
                year: year,
                credits: credits,
                debits: debits,
                dsop: dsop,
                tax: tax,
                name: name,
                accountNumber: "TEST-\(Int.random(in: 1000...9999))",
                panNumber: "PAN-\(Int.random(in: 10000...99999))"
            )
        }
    }
    
    /// Creates a random military payslip
    static var randomMilitaryPayslipGenerator: Gen<PayslipItem> {
        return Gen<Int>.choose((0, 1)).flatMap { typeIndex in
            if typeIndex == 0 {
                // Standard military payslip
                return Gen.compose { composer in
                    let rankIndex = composer.generate(using: Gen<Int>.choose((0, MilitaryPayslipGenerator.MilitaryRank.allCases.count - 1)))
                    let branchIndex = composer.generate(using: Gen<Int>.choose((0, 5))) // 6 branches
                    let serviceYears = composer.generate(using: Gen<Int>.choose((1, 30)))
                    
                    let rank = MilitaryPayslipGenerator.MilitaryRank.allCases[rankIndex]
                    let branch = branchTypeFromIndex(branchIndex)
                    
                    return MilitaryPayslipGenerator.standardMilitaryPayslip(
                        rank: rank,
                        serviceYears: serviceYears,
                        branch: branch
                    )
                }
            } else {
                // Deployed military payslip
                return Gen.compose { composer in
                    let rankIndex = composer.generate(using: Gen<Int>.choose((0, MilitaryPayslipGenerator.MilitaryRank.allCases.count - 1)))
                    let branchIndex = composer.generate(using: Gen<Int>.choose((0, 5))) // 6 branches
                    let serviceYears = composer.generate(using: Gen<Int>.choose((1, 30)))
                    let hazardIndex = composer.generate(using: Gen<Int>.choose((0, 4))) // 5 hazard levels
                    
                    let rank = MilitaryPayslipGenerator.MilitaryRank.allCases[rankIndex]
                    let branch = branchTypeFromIndex(branchIndex)
                    let hazardLevel = hazardLevelFromIndex(hazardIndex)
                    
                    return MilitaryPayslipGenerator.deployedMilitaryPayslip(
                        rank: rank,
                        serviceYears: serviceYears,
                        branch: branch,
                        deploymentStatus: .combat,
                        hazardLevel: hazardLevel
                    )
                }
            }
        }
    }
    
    /// Creates a random corporate payslip
    static var randomCorporatePayslipGenerator: Gen<PayslipItem> {
        return Gen<Int>.choose((0, 1)).flatMap { typeIndex in
            if typeIndex == 0 {
                // Standard corporate payslip
                return Gen.compose { composer in
                    let levelIndex = composer.generate(using: Gen<Int>.choose((0, 7))) // 8 corporate levels
                    let departmentIndex = composer.generate(using: Gen<Int>.choose((0, 7))) // 8 departments
                    let serviceYears = composer.generate(using: Gen<Int>.choose((1, 25)))
                    
                    let level = CorporatePayslipGenerator.CorporateLevel.allCases[levelIndex]
                    let department = corporateDepartmentFromIndex(departmentIndex)
                    
                    return CorporatePayslipGenerator.standardCorporatePayslip(
                        level: level,
                        serviceYears: serviceYears,
                        department: department
                    )
                }
            } else {
                // Bonus payslip
                return Gen.compose { composer in
                    let levelIndex = composer.generate(using: Gen<Int>.choose((0, 7))) // 8 corporate levels
                    let departmentIndex = composer.generate(using: Gen<Int>.choose((0, 7))) // 8 departments
                    let serviceYears = composer.generate(using: Gen<Int>.choose((1, 25)))
                    let bonusIndex = composer.generate(using: Gen<Int>.choose((0, 4))) // 5 bonus types
                    let bonusMultiplier = composer.generate(using: Gen<Double>.choose((0.5, 2.0)))
                    
                    let level = CorporatePayslipGenerator.CorporateLevel.allCases[levelIndex]
                    let department = corporateDepartmentFromIndex(departmentIndex)
                    let bonusType = bonusTypeFromIndex(bonusIndex)
                    
                    return CorporatePayslipGenerator.bonusPayslip(
                        level: level,
                        serviceYears: serviceYears,
                        department: department,
                        bonusType: bonusType,
                        bonusMultiplier: bonusMultiplier
                    )
                }
            }
        }
    }
    
    // MARK: - PDF Generation Helpers
    
    /// Creates a PDF with random variations of a given PayslipItem
    static func generateRandomPayslipPDF(from payslip: PayslipItem) -> PDFDocument {
        let formatIndex = Int.random(in: 0...3)
        
        switch formatIndex {
        case 0:
            // Standard format
            return TestDataGenerator.generatePDFDocument(
                forPayslip: payslip,
                withTitle: "Standard Payslip"
            )
        case 1:
            // Minimal format
            let minimalContent = """
            PAYSLIP
            \(payslip.name)
            \(payslip.month) \(payslip.year)
            
            CREDITS: \(String(format: "%.2f", payslip.credits))
            DEBITS: \(String(format: "%.2f", payslip.debits))
            """
            return TestDataGenerator.generatePDFDocumentFromText(minimalContent)
        case 2:
            // Detailed format with breakdowns
            var detailedContent = """
            PAYSLIP
            Name: \(payslip.name)
            Month: \(payslip.month)
            Year: \(payslip.year)
            
            INCOME:
            """
            
            // Add credit breakdown
            if let creditBreakdown = payslip.creditBreakdown, !creditBreakdown.isEmpty {
                for (description, amount) in creditBreakdown {
                    detailedContent += "\n\(description): \(String(format: "%.2f", amount))"
                }
            } else {
                detailedContent += "\nBase Pay: \(String(format: "%.2f", payslip.credits))"
            }
            
            detailedContent += "\n\nTotal Credits: \(String(format: "%.2f", payslip.credits))"
            detailedContent += "\n\nDEDUCTIONS:"
            
            // Add debit breakdown
            if let debitBreakdown = payslip.debitBreakdown, !debitBreakdown.isEmpty {
                for (description, amount) in debitBreakdown {
                    detailedContent += "\n\(description): \(String(format: "%.2f", amount))"
                }
            } else {
                detailedContent += "\nStandard Deductions: \(String(format: "%.2f", payslip.debits))"
            }
            
            detailedContent += "\n\nTotal Debits: \(String(format: "%.2f", payslip.debits))"
            detailedContent += "\n\nNET AMOUNT: \(String(format: "%.2f", payslip.netAmount))"
            
            return TestDataGenerator.generatePDFDocumentFromText(detailedContent)
        case 3:
            // Tabular format
            let tabularContent = """
            PAYSLIP FOR \(payslip.name)
            Period: \(payslip.month) \(payslip.year)
            
            ------------------------------------------------
            SUMMARY                       |  AMOUNT
            ------------------------------------------------
            Total Credits                 |  \(String(format: "%.2f", payslip.credits))
            Total Debits                  |  \(String(format: "%.2f", payslip.debits))
            ------------------------------------------------
            DSOP Contribution             |  \(payslip.dsop != nil ? String(format: "%.2f", payslip.dsop!) : "N/A")
            Tax                           |  \(payslip.tax != nil ? String(format: "%.2f", payslip.tax!) : "N/A")
            ------------------------------------------------
            Net Amount                    |  \(String(format: "%.2f", payslip.netAmount))
            ------------------------------------------------
            """
            return TestDataGenerator.generatePDFDocumentFromText(tabularContent)
        default:
            return TestDataGenerator.generatePDFDocument(forPayslip: payslip)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Converts an index to a military branch type
    private static func branchTypeFromIndex(_ index: Int) -> MilitaryPayslipGenerator.MilitaryBranch {
        switch index {
        case 0: return .army
        case 1: return .navy
        case 2: return .airForce
        case 3: return .marines
        case 4: return .coastGuard
        case 5: return .spaceForce
        default: return .army
        }
    }
    
    /// Converts an index to a hazard level
    private static func hazardLevelFromIndex(_ index: Int) -> MilitaryPayslipGenerator.HazardLevel {
        switch index {
        case 0: return .minimal
        case 1: return .low
        case 2: return .moderate
        case 3: return .high
        case 4: return .extreme
        default: return .minimal
        }
    }
    
    /// Converts an index to a corporate department
    private static func corporateDepartmentFromIndex(_ index: Int) -> CorporatePayslipGenerator.CorporateDepartment {
        switch index {
        case 0: return .technology
        case 1: return .finance
        case 2: return .sales
        case 3: return .marketing
        case 4: return .humanResources
        case 5: return .operations
        case 6: return .legal
        case 7: return .research
        default: return .technology
        }
    }
    
    /// Converts an index to a bonus type
    private static func bonusTypeFromIndex(_ index: Int) -> CorporatePayslipGenerator.BonusType {
        switch index {
        case 0: return .performance
        case 1: return .annual
        case 2: return .retention
        case 3: return .signing
        case 4: return .projectCompletion
        default: return .performance
        }
    }
}

// MARK: - Extensions for Generators

extension MilitaryPayslipGenerator.MilitaryRank: CaseIterable {
    public static var allCases: [MilitaryPayslipGenerator.MilitaryRank] {
        return [
            // Enlisted
            .e1, .e2, .e3, .e4, .e5, .e6, .e7, .e8, .e9,
            // Warrant Officers
            .w1, .w2, .w3, .w4, .w5,
            // Officers
            .o1, .o2, .o3, .o4, .o5, .o6, .o7, .o8, .o9, .o10
        ]
    }
}

extension CorporatePayslipGenerator.CorporateLevel: CaseIterable {
    public static var allCases: [CorporatePayslipGenerator.CorporateLevel] {
        return [.intern, .associate, .seniorAssociate, .manager, 
                .seniorManager, .director, .vicePresident, .cSuite]
    }
} 