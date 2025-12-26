//
//  VisionLLMPromptTemplate.swift
//  PayslipMax
//
//  Prompt template for Vision LLM payslip parsing
//

import Foundation

/// Prompt template for Vision LLM payslip parsing
enum VisionLLMPromptTemplate {

    /// The main prompt for extracting payslip data from images
    static let extractionPrompt = """
        Extract from the "Accounts at a Glance" section ONLY.

        ⚠️ PRIVACY: Do NOT extract personal info.

        📊 STRUCTURE:
        LEFT = CREDITS (Earnings): BPAY, DA, MSP, TPAL, HRA, LRA, etc.
        RIGHT = DEBITS (Deductions): DSOP/AFPP, AGIF, PLI, ITAX, LOANS, etc.

        ✅ USE THESE CODE NAMES (normalize):
        • BAND PAY → BPAY
        • GP-X PAY or MSP → MSP
        • AFPP FUND SUBSCRIPTION or DSOP → DSOP

        🔢 TOTALS (CRITICAL):
        • grossPay = TOTAL CREDITS
        • netRemittance = "AMOUNT CREDITED TO BANK" (the take-home pay)
        • totalDeductions = grossPay - netRemittance (CALCULATE this!)

        ❌ DO NOT EXTRACT (these are from FUND/LOAN sections, not CREDITS/DEBITS):
        • OPENING BALANCE
        • BONUS ON CR. BALANCE
        • CREDIT BALANCE RELEASED
        • CLOSING BALANCE
        • Any row with "BALANCE" in it

        ❌ NOT DEDUCTIONS:
        • AMOUNT CREDITED TO BANK (this is netRemittance!)
        • FAMO with large value (if FAMO > 10000, it's likely netRemittance misread)

        📅 DATE: Look for "MONTH YYYY" at top (e.g., "DECEMBER 2023")

        Return ONLY JSON:
        {
          "earnings": {"BPAY": 37000, "DA": 24200, ...},
          "deductions": {"DSOP": 2220, "AGIF": 7500, ...},
          "grossPay": 86953,
          "totalDeductions": 28701,
          "netRemittance": 58252,
          "month": "DECEMBER",
          "year": 2023
        }

        RULES:
        • totalDeductions MUST be < grossPay
        • netRemittance = grossPay - totalDeductions
        • No markdown, no explanation, ONLY JSON
        """
}

