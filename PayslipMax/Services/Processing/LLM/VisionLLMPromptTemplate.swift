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
    /// Designed to work with both full payslip images and cropped sections
    /// Uses TOTALS-FIRST extraction strategy for accurate reconciliation
    static let extractionPrompt = """
        Parse this Indian military payslip image. The image may be full, cropped, or rotated.

        ⚠️ PRIVACY: Do NOT extract names, account numbers, PAN, or personal info.

        ═══════════════════════════════════════════════════════════════
        STEP 1: UNDERSTAND THE TABLE STRUCTURE
        ═══════════════════════════════════════════════════════════════

        The payslip has a TWO-COLUMN table called "ACCOUNTS AT A GLANCE":

        ┌─────────────────────────────────┬─────────────────────────────────┐
        │  LEFT COLUMN = CREDITS (जमा)    │  RIGHT COLUMN = DEBITS (नामे)   │
        │  = EARNINGS (money received)    │  = DEDUCTIONS (money taken)     │
        ├─────────────────────────────────┼─────────────────────────────────┤
        │ Hindi Label | Code | Amount     │ Hindi Label | Code | Amount     │
        │ बैंड वेतन   | BPAY | 37000      │ DSOP सब्सक्र  | DSOP | 2220     │
        │ महँगाई भत्ता | DA   | 24200      │ AGIF        | AGIF | 7500      │
        │ ...                             │ ...                             │
        └─────────────────────────────────┴─────────────────────────────────┘

        ⚠️ CRITICAL READING RULE: Each row has EXACTLY ONE code and ONE amount.
        The amount is ALWAYS on the SAME ROW as its code, in the rightmost position.
        NEVER take an amount from a different row!

        ═══════════════════════════════════════════════════════════════
        STEP 2: EXTRACT ANCHOR VALUES FIRST (MOST CRITICAL)
        ═══════════════════════════════════════════════════════════════

        Find these THREE anchor values:

        1️⃣ grossPay = "TOTAL CREDITS" (कुल जमा) - bottom of LEFT column
        2️⃣ netRemittance = "AMOUNT CREDITED TO BANK" (बैंक मे जमा राशि) - in RIGHT column
        3️⃣ totalDeductions = grossPay - netRemittance (CALCULATE THIS!)

        ⚠️ DO NOT use "TOTAL DEBITS" as totalDeductions - it equals TOTAL CREDITS (accounting balance)

        ═══════════════════════════════════════════════════════════════
        STEP 3: EXTRACT LINE ITEMS - ROW BY ROW
        ═══════════════════════════════════════════════════════════════

        Read each row LEFT to RIGHT. Each row contains:
        [Hindi text] [English code] [Amount OR blank]

        ✅ IF amount exists on THIS row → include {code: amount}
        ❌ IF amount is BLANK on THIS row → SKIP this code entirely

        EARNINGS (LEFT column) - normalize to these keys:
        • BAND PAY / बैंड वेतन → "BPAY"
        • DA / महँगाई भत्ता → "DA" (Dearness Allowance)
        • GP-X PAY / MS PAY → "MSP"
        • TPAL / परिवहन भत्ता → "TPAL" (Transport Allowance)
        • HRA → "HRA"
        • LRA → "LRA"
        • PMHA → "PMHA"
        • CL PAY → "CL PAY"
        ❌ EXCLUDE: "TOTAL CREDITS" (already captured as grossPay)

        DEDUCTIONS (RIGHT column) - normalize to these keys:
        • AFPP FUND SUBSCRIPTION / DSOP → "DSOP"
        • AGIF → "AGIF"
        • PLI → "PLI"
        • LOANS & ADVANCES → "LOANS & ADVANCES"
        • INCOME TAX / EC → "ITAX"
        • E-TICKETING → "E-TICKETING"
        ❌ EXCLUDE: "TOTAL DEBITS" (accounting balance, not actual deductions)
        ❌ EXCLUDE: "AMOUNT CREDITED TO BANK" (this is netRemittance!)

        ═══════════════════════════════════════════════════════════════
        STEP 4: HANDLE BLANK VALUES CORRECTLY
        ═══════════════════════════════════════════════════════════════

        Many rows have a code but NO AMOUNT (blank space). This is normal.

        Examples of what you might see:

        │ E-TICKETING     |        |  ← BLANK! Do NOT include in JSON
        │ FAMO            |        |  ← BLANK! Do NOT include in JSON
        │ INCOME TAX / EC |        |  ← BLANK! Do NOT include in JSON
        │ DSOP            | 2220   |  ← Has value, include as {"DSOP": 2220}

        ⚠️ NEVER assign the netRemittance value to a blank deduction code!
        If you see a large amount like 50000+ in the deductions column,
        verify it's not "AMOUNT CREDITED TO BANK" which belongs to netRemittance.

        ═══════════════════════════════════════════════════════════════
        STEP 5: SELF-VALIDATE BEFORE RETURNING
        ═══════════════════════════════════════════════════════════════

        CHECK 1: grossPay - totalDeductions = netRemittance (must be exact!)
        CHECK 2: Sum of earnings ≈ grossPay (within 5%)
        CHECK 3: Sum of deductions ≈ totalDeductions (within 5%)
        CHECK 4: totalDeductions < grossPay (ALWAYS true!)
        CHECK 5: netRemittance > 0 (take-home pay must be positive)

        If checks fail, re-examine - you likely included a wrong value or missed an item.

        ═══════════════════════════════════════════════════════════════
        SECTIONS TO IGNORE (even if visible)
        ═══════════════════════════════════════════════════════════════

        ❌ "Rates of Pay" table (bottom-right, has PAY/ALLC column header)
        ❌ "FUND" section (OP BAL, TOTAL SUB, CLOSING BALANCE)
        ❌ "LOAN" section (LOAN AMT, RECOVERY, INT RECVY)
        ❌ "ADVANCES" section
        ❌ "PLI" detail section (PLIPOL NO., MAT.DT., PREMIUM)
        ❌ Any row with "BALANCE", "CLOSING", "OPENING"

        ═══════════════════════════════════════════════════════════════
        DATE EXTRACTION
        ═══════════════════════════════════════════════════════════════

        Look at TOP of image for: "Statement of Account For Month Ending: MM/YYYY"
        Extract month (uppercase English) and year (4-digit).

        ═══════════════════════════════════════════════════════════════
        OUTPUT FORMAT
        ═══════════════════════════════════════════════════════════════

        Return ONLY valid JSON (no markdown, no explanation):
        {
          "earnings": {"BPAY": 37000, "DA": 24200, "MSP": 5875, ...},
          "deductions": {"DSOP": 2220, "AGIF": 7500, "PLI": 3396, ...},
          "grossPay": 86953,
          "totalDeductions": 28701,
          "netRemittance": 58252,
          "month": "AUGUST",
          "year": 2025
        }

        FINAL RULES:
        • totalDeductions = grossPay - netRemittance (ALWAYS calculate!)
        • All amounts are numbers (no ₹, no commas)
        • Only include codes that have values ON THE SAME ROW
        • Month is uppercase English, Year is 4-digit integer
        """

    /// Prompt for retry when totals reconciliation fails
    /// - Parameters:
    ///   - grossPay: Extracted gross pay
    ///   - netRemittance: Extracted net remittance
    ///   - expectedDeductions: Calculated expected deductions
    ///   - actualDeductionsSum: Sum of extracted deduction line items
    /// - Returns: Focused reconciliation prompt
    static func totalsReconciliationPrompt(
        grossPay: Double,
        netRemittance: Double,
        expectedDeductions: Double,
        actualDeductionsSum: Double
    ) -> String {
        let discrepancy = abs(expectedDeductions - actualDeductionsSum)
        return """
        RECONCILIATION TASK - Re-examine this payslip image.

        First pass found DISCREPANCIES in totals:
        • grossPay (TOTAL CREDITS): ₹\(Int(grossPay))
        • netRemittance (AMOUNT CREDITED TO BANK): ₹\(Int(netRemittance))
        • Expected totalDeductions (grossPay - netRemittance): ₹\(Int(expectedDeductions))
        • Sum of deduction line items extracted: ₹\(Int(actualDeductionsSum))
        • Discrepancy: ₹\(Int(discrepancy))

        Please re-examine the image using ROW-BY-ROW reading:

        1. VERIFY "TOTAL CREDITS" value at bottom of left column
        2. VERIFY "AMOUNT CREDITED TO BANK" value in right column
        3. For EACH deduction row, read the code and amount ON THE SAME ROW
        4. If a row has a code but NO AMOUNT (blank), SKIP that code entirely
        5. NEVER assign netRemittance value to a deduction code

        ⚠️ COMMON MISTAKE TO AVOID:
        Some deduction codes (E-TICKETING, FAMO, INCOME TAX) may have BLANK values.
        Do NOT pick up a value from another row - just skip these codes.

        REMEMBER:
        • totalDeductions = grossPay - netRemittance (CALCULATE, don't use TOTAL DEBITS!)
        • Sum of deductions should ≈ totalDeductions
        • Each code's value must be on the SAME ROW as the code

        Return corrected JSON:
        {
          "earnings": {...},
          "deductions": {...},
          "grossPay": number,
          "totalDeductions": number,
          "netRemittance": number,
          "month": "MONTH",
          "year": YYYY
        }
        """
    }
}

