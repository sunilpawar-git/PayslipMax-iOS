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
        You are a military payslip parser. Extract ONLY earnings and deductions from this payslip image.

        ⚠️ CRITICAL PRIVACY - DO NOT EXTRACT OR RETURN:
        ❌ Personal names (employee name, rank name, unit commander)
        ❌ Account numbers (bank A/C, SUS/Service number, Army/Navy/Air Force number)
        ❌ PAN card numbers
        ❌ Phone numbers
        ❌ Email addresses
        ❌ Physical addresses
        ❌ Signatures or signature blocks
        ❌ Unit names or posting locations
        ❌ Date of birth or age

        ✅ EARNINGS - Extract individual line items (money ADDED to salary):
        • Pay codes: BPAY, DA, MSP, TA, HRA, CCA, NPS, GPF, TPTA, RISK, LRA, CI Pay, HRALF, Gs Pay, RUMCIG, PMHA
        • Allowances: House Rent Allowance, Dearness Allowance, Ms Pay, TPAL
        • Extract ONLY from "EARNINGS" or "PAY" section of payslip
        • Each as separate key-value pair (e.g., "BPAY": 37000, "DA": 24200)

        ✅ DEDUCTIONS - Extract individual line items (money TAKEN OUT of salary):
        • Fund contributions: DSOP, DSOPP, AFPP, AGIF (only monthly subscription amounts)
        • Tax payments: ITAX, Income Tax
        • Insurance: CGHS, PLI Premium
        • Loan installments: Only monthly installment amounts (NOT total loan balance)
        • Extract ONLY from "DEDUCTIONS" section of payslip
        • Each as separate key-value pair (e.g., "DSOP": 2220, "ITAX": 15585)

        ❌ DO NOT EXTRACT AS DEDUCTIONS (critical - these are NOT deductions):
        • "Loans & Advances" - TOTAL/SUMMARY lines (these show cumulative amounts, not monthly deductions)
        • "Credit Balance Released" - This is a REFUND/CREDIT (money given back, not taken)
        • "Credit Balance" - Previous balance amount (not current month deduction)
        • "AFPP Fund Refund" / "DSOP Refund" - Refunds are CREDITS, not deductions
        • "Total Recovery" - Summary line, not individual deduction
        • "Balance" or "Carried Forward" - Previous amounts, not current deductions
        • Any line with words: "Total", "Balance", "Released", "Refund", "Previous", "Carried Forward", "Recovery Total"

        ❌ AVOID DUPLICATES:
        • If you see the same pay code and amount twice (e.g., "AGIF: 3396" appears twice), extract it ONLY ONCE
        • Check for duplicate entries across different sections

        ✅ TOTALS - Extract summary amounts:
        • grossPay: Total of all earnings (should match sum of earnings items ±5%)
        • totalDeductions: Total of all deductions (should match sum of deduction items ±5%)
        • netRemittance: Final take-home pay (MUST equal grossPay - totalDeductions)

        🔍 SANITY CHECK (verify before returning):
        • totalDeductions MUST be LESS than grossPay (if not, you extracted wrong values)
        • netRemittance = grossPay - totalDeductions (within ±5% tolerance)
        • Sum of earnings items should approximately equal grossPay
        • Sum of deduction items should approximately equal totalDeductions

        📋 EXAMPLE - Correct extraction for typical payslip:

        VISIBLE IN IMAGE:
        EARNINGS:
        BPAY: 37,000
        DA: 24,200
        MSP: 5,200
        HRA: 3,700
        [... other items ...]
        TOTAL EARNINGS: 86,953

        DEDUCTIONS:
        DSOP: 2,220
        AGIF: 3,396
        ITAX: 15,585
        PLI Premium: 15,585
        [... other items ...]
        TOTAL DEDUCTIONS: 28,701

        RECOVERIES/ADJUSTMENTS (DO NOT EXTRACT):
        Loans & Advances Total: 86,953  ← SKIP (summary line)
        Credit Balance Released: 58,252  ← SKIP (refund/credit)
        AFPP Fund Refund: 7,500  ← SKIP (refund, not deduction)

        CORRECT JSON OUTPUT:
        {
          "earnings": {"BPAY": 37000, "DA": 24200, "MSP": 5200, "HRA": 3700, ...},
          "deductions": {"DSOP": 2220, "AGIF": 3396, "ITAX": 15585, "PLI Premium": 15585, ...},
          "grossPay": 86953,
          "totalDeductions": 28701,
          "netRemittance": 58252,
          "month": "AUGUST",
          "year": 2025
        }

        CRITICAL RULES:
        1. Use ONLY these 7 top-level keys: earnings, deductions, grossPay, totalDeductions, netRemittance, month, year
        2. earnings and deductions are objects with string keys and numeric values
        3. All numbers are plain integers or decimals (no ₹, no commas, no strings)
        4. month is uppercase string (e.g. "AUGUST"), year is integer (e.g. 2025)
        5. netRemittance MUST equal grossPay - totalDeductions (within ±5%)
        6. Extract ONLY individual line items from earnings/deductions sections (NOT summary/total lines)
        7. Return ONLY the JSON object - no explanation, no markdown fences, no extra text

        REMINDER: Exclude ALL personal identifiers from your response. Only return financial data and pay codes.
        """
}

