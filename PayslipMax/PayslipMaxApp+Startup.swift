//
//  PayslipMaxApp+Startup.swift
//  PayslipMax
//
//  Startup validation and test data setup extensions
//

import SwiftUI
import SwiftData

// MARK: - Startup Validation

extension PayslipMaxApp {
    /// Validates parsing systems at startup to ensure JSON and pattern loading works correctly
    func validateParsingSystemsAtStartup() {
        print("🚀 PayslipMax Parsing Systems Validation:")

        // 1. Validate PatternProvider (universal parsing patterns)
        let patternProvider = DefaultPatternProvider()
        print("   • Legacy Regex Patterns: \(patternProvider.patterns.count)")
        print("   • Earnings Patterns: \(patternProvider.earningsPatterns.count)")
        print("   • Deductions Patterns: \(patternProvider.deductionsPatterns.count)")

        // 2. Validate MilitaryAbbreviationsService (243 JSON codes)
        let militaryService = MilitaryAbbreviationsService.shared
        let jsonCount = militaryService.allAbbreviations.count
        let creditCount = militaryService.creditAbbreviations.count
        let debitCount = militaryService.debitAbbreviations.count

        print("   • JSON Military Codes: \(jsonCount)")
        print("   • Credit Classifications: \(creditCount)")
        print("   • Debit Classifications: \(debitCount)")

        // 3. Validate UniversalPayCodeSearchEngine (combined system)
        let patternGenerator = PayCodePatternGenerator.shared
        let totalSearchCodes = patternGenerator.getAllKnownPayCodes().count
        print("   • Universal Search Codes: \(totalSearchCodes)")

        // 4. Critical validation checks
        let warnings = performCriticalValidation(patternProvider: patternProvider, jsonCount: jsonCount, totalSearchCodes: totalSearchCodes)

        // 5. Dual-section validation
        validateDualSectionCodes(militaryService: militaryService, jsonCount: jsonCount)

        // 6. Report results
        reportValidationResults(patternCount: patternProvider.patterns.count, jsonCount: jsonCount, warnings: warnings)
    }

    private func performCriticalValidation(patternProvider: DefaultPatternProvider, jsonCount: Int, totalSearchCodes: Int) -> [String] {
        var warnings: [String] = []

        if jsonCount < 200 {
            warnings.append("🚨 JSON SYSTEM CRITICAL: Expected ~243 codes, got \(jsonCount)")
        }

        if totalSearchCodes < 240 {
            warnings.append("🚨 SEARCH SYSTEM CRITICAL: Expected ~246 codes, got \(totalSearchCodes)")
        }

        if patternProvider.patterns.count < 40 {
            warnings.append("⚠️ PATTERN SYSTEM WARNING: Expected ~51 patterns, got \(patternProvider.patterns.count)")
        }

        return warnings
    }

    private func validateDualSectionCodes(militaryService: MilitaryAbbreviationsService, jsonCount: Int) {
        guard jsonCount > 0 else { return }

        let dualSectionCodes = militaryService.allAbbreviations.filter { $0.isCredit == nil }
        print("   • Dual-Section Codes: \(dualSectionCodes.count)")

        logCodeClassification(militaryService: militaryService, code: "RH12")
        logCodeClassification(militaryService: militaryService, code: "HRA")
        logCodeClassification(militaryService: militaryService, code: "CEA", label: "CEA (Arrears Base)")
    }

    private func logCodeClassification(militaryService: MilitaryAbbreviationsService, code: String, label: String? = nil) {
        if let codeInfo = militaryService.abbreviation(forCode: code) {
            let classification = codeInfo.isCredit == nil ? "Dual" :
                codeInfo.isCredit == true ? "Credit-Only" : "Debit-Only"
            print("   • \(label ?? code) Classification: \(codeInfo.description) (\(classification))")
        }
    }

    private func reportValidationResults(patternCount: Int, jsonCount: Int, warnings: [String]) {
        let totalCoverage = patternCount + jsonCount
        print("   • Total Parsing Coverage: \(totalCoverage) patterns/codes")

        if warnings.isEmpty {
            print("✅ All parsing systems initialized successfully")
            print("🎯 Universal Dual-Section Processing: ACTIVE (243 codes in both earnings and deductions)")
        } else {
            for warning in warnings {
                print(warning)
            }
        }

        print("🔍 Startup validation completed")
    }
}

// MARK: - Test Data Setup

extension PayslipMaxApp {
    func setupTestData() {
        let context = modelContainer.mainContext

        let testPayslips = [
            createTestPayslip(monthsAgo: 60, month: "January", credits: 5000, debits: 1000, dsop: 500, tax: 800),
            createTestPayslip(monthsAgo: 30, month: "February", credits: 5500, debits: 1100, dsop: 550, tax: 880),
            createTestPayslip(monthsAgo: 0, month: "March", credits: 6000, debits: 1200, dsop: 600, tax: 960)
        ]

        for payslip in testPayslips {
            context.insert(payslip)
        }

        try? context.save()
    }

    private func createTestPayslip(monthsAgo: Int, month: String, credits: Double, debits: Double, dsop: Double, tax: Double) -> PayslipItem {
        PayslipItem(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-86400 * Double(monthsAgo)),
            month: month,
            year: 2024,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            pdfData: nil
        )
    }
}

