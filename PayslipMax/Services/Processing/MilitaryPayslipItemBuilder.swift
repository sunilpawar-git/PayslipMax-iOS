//
//  MilitaryPayslipItemBuilder.swift
//  PayslipMax
//
//  Extracted from UnifiedMilitaryPayslipProcessor for architectural compliance
//  Handles building the final PayslipItem from processed data
//

import Foundation

/// Protocol for military payslip item building following SOLID principles
protocol MilitaryPayslipItemBuilderProtocol {
    func buildPayslipItem(
        earnings: [String: Double],
        deductions: [String: Double],
        statedCredits: Double,
        statedDebits: Double,
        extractedDate: (month: String, year: Int)?
    ) throws -> PayslipItem
}

/// Service responsible for building the final PayslipItem from processed military payslip data
/// Implements single responsibility principle for item construction
class MilitaryPayslipItemBuilder: MilitaryPayslipItemBuilderProtocol {

    /// Builds a PayslipItem from processed military payslip data
    func buildPayslipItem(
        earnings: [String: Double],
        deductions: [String: Double],
        statedCredits: Double,
        statedDebits: Double,
        extractedDate: (month: String, year: Int)?
    ) throws -> PayslipItem {

        // Calculate totals
        let totalEarnings = earnings.values.reduce(0, +)
        let totalDeductions = deductions.values.reduce(0, +)
        _ = totalEarnings - totalDeductions // netPay reserved for future use
        
        // Build date  
        _ = buildPayslipDate(from: extractedDate) // payslipDate reserved for future use

        // Log creation summary
        print("[MilitaryPayslipItemBuilder] Creating defense payslip - Credits: ₹\(statedCredits), Debits: ₹\(statedDebits), DSOP: ₹\(deductions["DSOP"] ?? 0)")

        // Create PayslipItem with defense-specific structure using convenience initializer
        let payslipItem = PayslipItem(
            id: UUID(),
            month: extractedDate?.month ?? "UNKNOWN",
            year: extractedDate?.year ?? Calendar.current.component(.year, from: Date()),
            credits: statedCredits,
            debits: statedDebits,
            dsop: deductions["DSOP"] ?? 0.0,
            tax: deductions["Income Tax"] ?? deductions["ITAX"] ?? 0.0,
            earnings: earnings,
            deductions: deductions,
            source: "Military Payslip Parser"
        )

        return payslipItem
    }

    /// Builds a proper date from extracted month and year
    private func buildPayslipDate(from extractedDate: (month: String, year: Int)?) -> Date {
        guard let extractedDate = extractedDate else {
            return Date() // Fallback to current date
        }

        let calendar = Calendar.current
        var components = DateComponents()
        components.year = extractedDate.year
        components.month = monthNumber(from: extractedDate.month)
        components.day = 1 // First day of the month

        return calendar.date(from: components) ?? Date()
    }

    /// Converts month name to number
    private func monthNumber(from monthName: String) -> Int {
        let monthMap = [
            "JANUARY": 1, "FEBRUARY": 2, "MARCH": 3, "APRIL": 4,
            "MAY": 5, "JUNE": 6, "JULY": 7, "AUGUST": 8,
            "SEPTEMBER": 9, "OCTOBER": 10, "NOVEMBER": 11, "DECEMBER": 12
        ]

        return monthMap[monthName.uppercased()] ?? 1
    }

    /// Calculates confidence score based on data completeness
    private func calculateConfidence(earnings: [String: Double], deductions: [String: Double]) -> Double {
        var score = 0.0
        let maxScore = 100.0

        // Basic structure confidence (40 points)
        if !earnings.isEmpty && !deductions.isEmpty {
            score += 40.0
        }

        // Essential components confidence (30 points)
        var essentialCount = 0
        let essentialComponents = ["Basic Pay", "Military Service Pay", "DSOP", "AGIF"]

        for component in essentialComponents {
            if earnings[component] != nil || deductions[component] != nil {
                essentialCount += 1
            }
        }

        score += (Double(essentialCount) / Double(essentialComponents.count)) * 30.0

        // Data richness confidence (20 points)
        let totalComponents = earnings.count + deductions.count
        if totalComponents >= 8 {
            score += 20.0
        } else if totalComponents >= 5 {
            score += 15.0
        } else if totalComponents >= 3 {
            score += 10.0
        }

        // RH12 detection bonus (10 points)
        if earnings["RH12_EARNINGS"] != nil || deductions["RH12_DEDUCTIONS"] != nil {
            score += 10.0
        }

        return min(score, maxScore)
    }

    /// Validates that essential data is present for PayslipItem creation
    private func validateEssentialData(earnings: [String: Double], deductions: [String: Double]) throws {
        // Must have at least one earning and one deduction
        guard !earnings.isEmpty else {
            throw PayslipError.invalidData
        }

        guard !deductions.isEmpty else {
            throw PayslipError.invalidData
        }

        // Must have basic pay
        guard earnings["Basic Pay"] != nil else {
            throw PayslipError.invalidData
        }
    }
}
