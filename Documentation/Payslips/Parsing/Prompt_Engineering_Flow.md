# Prompt Engineering Flow for Payslip Parsing

## Overview

This document shows how prompt engineering is enabled when payslips are processed through the **scan method**. There are **two main paths** with different prompts:

1. **Vision LLM Path** (Primary) - Uses image directly
2. **OCR + Text LLM Path** (Fallback) - Uses OCR text extraction

---

## Flow Diagram

```
User scans payslip image
    ↓
processScannedImages(originalImage, croppedImage)
    ↓
┌─────────────────────────────────────────┐
│ PRIMARY: Vision LLM Path                │
│ (Line 140-162 in PDFProcessingService) │
└─────────────────────────────────────────┘
    ↓
visionParser.parse(image: croppedImage)
    ↓
VisionLLMPayslipParser.parse(image:)
    ↓
┌─────────────────────────────────────────┐
│ Uses: VisionLLMPromptTemplate           │
│ .extractionPrompt                       │
└─────────────────────────────────────────┘
    ↓
[FIRST PASS] → Gemini Vision API
    ↓
If confidence < 0.9:
    ↓
┌─────────────────────────────────────────┐
│ SECOND PASS: Verification               │
│ Uses: createVerificationPrompt()        │
└─────────────────────────────────────────┘
    ↓
[SECOND PASS] → Gemini Vision API
    ↓
Compare & calculate agreement
    ↓
Return final result

┌─────────────────────────────────────────┐
│ FALLBACK: OCR + Text LLM Path           │
│ (If Vision LLM fails)                  │
└─────────────────────────────────────────┘
    ↓
OCR extraction (multiple passes)
    ↓
parser.parse(hintPrefix + ocrText)
    ↓
┌─────────────────────────────────────────┐
│ Uses: LLMPrompt.payslip                │
│ + User hint prefix                     │
└─────────────────────────────────────────┘
    ↓
[FIRST PASS] → Gemini Text API
    ↓
Return result
```

---

## Prompt 1: Vision LLM Extraction Prompt

**Location**: `VisionLLMPromptTemplate.extractionPrompt`
**Used in**: Primary Vision LLM parsing (first pass)
**File**: `PayslipMax/Services/Processing/LLM/VisionLLMPromptTemplate.swift`

### Current Prompt (Universal - works with full and cropped images):

```
Parse this Indian military payslip image. The image may be full or cropped.

⚠️ PRIVACY: Do NOT extract names, account numbers, PAN, or personal info.

📍 FIND THE MAIN TABLE (labeled "ACCOUNTS AT A GLANCE" or similar):
This table has TWO columns side-by-side:
• LEFT column header: "जमा" or "CREDITS" (₹ symbol on right)
• RIGHT column header: "नामे" or "DEBITS" (₹ symbol on right)

Each column has rows with: Hindi text | English code | Amount
Example row: "बैंड वेतन | BAND PAY | 37000"

📊 EXTRACT FROM MAIN TABLE ONLY:

CREDITS (LEFT) - These are EARNINGS:
• BAND PAY / बैंड वेतन → use key "BPAY"
• GP-X PAY / ग्रुप एक्स वेतन → use key "MSP"
• MS PAY / एम एस वेतन → add to "MSP"
• DA / महँगाई भत्ता → "DA"
• TPAL / परिवहन भत्ता → "TPAL"
• TOTAL CREDITS / कुल जमा → this is grossPay

DEBITS (RIGHT) - These are DEDUCTIONS:
• AFPP FUND SUBSCRIPTION / ए एफ पी पी निधि अभिदान → use key "DSOP"
• AGIF / ए जी आई एफ → "AGIF"
• PLI / डाक बीमा → "PLI"
• LOANS & ADVANCES / ऋण एवं अग्रिम → "LOANS & ADVANCES"
• INCOME TAX / EC → "ITAX"
• TOTAL DEBITS → IGNORE (this is a balancing figure!)
• AMOUNT CREDITED TO BANK → this is netRemittance (NOT a deduction!)

❌ IGNORE THESE SECTIONS (even if visible):
• "Rates of Pay" table (bottom-right, has PAY/ALLC column)
• "FUND" section (OP BAL, TOTAL SUB, CLOSING BALANCE)
• "LOAN" section (LOAN AMT, RECOVERY details)
• Any row containing "BALANCE", "CLOSING", "OPENING"

🔢 CALCULATE TOTALS:
• grossPay = TOTAL CREDITS value
• netRemittance = AMOUNT CREDITED TO BANK value
• totalDeductions = grossPay - netRemittance (MUST calculate this!)

📅 DATE: Look for "Month Ending: MM/YYYY" at top.

✅ VALIDATION:
• totalDeductions < grossPay (ALWAYS!)
• netRemittance = grossPay - totalDeductions (±1%)

Return ONLY valid JSON - no markdown, no explanation.
```

### Where It's Used:

```swift
// VisionLLMPayslipParser.swift, line 43-47
let request = LLMRequest(
    prompt: VisionLLMPromptTemplate.extractionPrompt,
    systemPrompt: nil,
    jsonMode: true
)
```

---

## Prompt 2: Vision LLM Verification Prompt

**Location**: `VisionLLMVerificationService.createVerificationPrompt()`
**Used in**: Second pass verification (when confidence < 0.9)
**File**: `PayslipMax/Services/Processing/LLM/VisionLLMVerificationService.swift`

### Current Prompt Template:

```
VERIFICATION TASK: Cross-check the following extracted values against the payslip image.

Previously extracted values (VERIFY THESE):
Earnings: {earnings_list}
Deductions: {deductions_list}
Gross Pay: {grossPay}
Total Deductions: {totalDeductions}
Net Remittance: {netRemittance}
Month: {month}
Year: {year}

Your task: Re-extract ALL values from the image independently. Do NOT simply copy the values above.
Look at the image carefully and extract earnings, deductions, and totals as you see them.

Return the same JSON format:
{
  "earnings": {"BPAY": <amount>, "DA": <amount>, ...},
  "deductions": {"DSOP": <amount>, "ITAX": <amount>, ...},
  "grossPay": <amount>,
  "totalDeductions": <amount>,
  "netRemittance": <amount>,
  "month": "MONTH_NAME",
  "year": <year>
}

CRITICAL: Extract what you see in the image, not what was previously extracted.
```

### Where It's Used:

```swift
// VisionLLMVerificationService.swift, line 38
let verificationPrompt = createVerificationPrompt(firstPassResult: firstPassResult)

let request = LLMRequest(
    prompt: verificationPrompt,
    systemPrompt: nil,
    jsonMode: true
)
```

### Verification Logic:

- **High Agreement (≥90%)**: Use verified result, boost confidence
- **Moderate Agreement (80-90%)**: Use verified result, reduce confidence slightly
- **Low Agreement (<80%)**: Revert to first pass, reduce confidence

---

## Prompt 3: Text LLM Prompt (OCR Fallback)

**Location**: `LLMPrompt.payslip`
**Used in**: OCR fallback path when Vision LLM fails
**File**: `PayslipMax/Services/Processing/LLM/LLMPrompt.swift`

### Current Prompt:

```
You are a military payslip parser. Extract earnings and deductions from payslips.

PRIVACY PROTECTION: The payslip text has been selectively redacted for privacy:
- ***NAME*** = Personal name (redacted for privacy)
- ***ACCOUNT*** = Bank/account number (redacted)
- ***PAN*** = PAN card number (redacted)
- ***SERVICE*** = Service/SUS number (redacted)
- ***PHONE*** = Phone number (redacted)
- ***EMAIL*** = Email address (redacted)

REQUIRED KEYS (fill 0.0 if not present in source):
- earnings: BPAY, DA, MSP
- deductions: DSOP/AFPP, ITAX (Income Tax), AGIF
- totals: grossPay, totalDeductions, netRemittance
- metadata: month (full uppercase), year (YYYY)

RECONCILIATION RULES:
- grossPay should be the sum of earnings (±5%)
- totalDeductions should be the sum of deductions (±5%)
- netRemittance must equal grossPay - totalDeductions (±5%)

IMPORTANT: These placeholders protect user privacy. Focus on extracting:
- Pay codes (BPAY, DA, MSP, etc.) and their amounts
- Deduction codes (DSOP, AGIF, ITAX, etc.) and their amounts
- Totals (Gross Pay, Total Deductions, Net Remittance)
- Month and year

Ignore the redacted placeholders - they are not pay codes.

IMPORTANT: Return ONLY valid JSON, no markdown formatting or explanations.

Return JSON in this exact format:
{
  "earnings": {
    "BPAY": <amount>,
    "DA": <amount>,
    "MSP": <amount>,
    ...
  },
  "deductions": {
    "DSOP": <amount>,
    "AGIF": <amount>,
    "ITAX": <amount>,
    ...
  },
  "grossPay": <amount>,
  "totalDeductions": <amount>,
  "netRemittance": <amount>,
  "month": "JUNE", // Full month name in uppercase
  "year": 2025
}
```

### Where It's Used:

```swift
// PDFProcessingService+Scan.swift, line 192-193
let hintPrefix = llmHintPrefix(for: hint)
let payslip = try await parser.parse(hintPrefix + best.text)
```

### User Hint Prefixes:

```swift
// PDFProcessingService+Scan.swift, line 220-229
private func llmHintPrefix(for hint: PayslipUserHint) -> String {
    switch hint {
    case .auto:
        return ""
    case .officer:
        return "[CONTEXT] This payslip belongs to an OFFICER rank. Parse using officer pay structure.\n"
    case .jcoOr:
        return "[CONTEXT] This payslip belongs to a JCO/OR rank. Parse using JCO/OR pay structure.\n"
    }
}
```

---

## Code Flow Summary

### Entry Point:
```swift
// PDFProcessingService+Scan.swift, line 124
func processScannedImages(
    originalImage: UIImage,
    croppedImage: UIImage,
    imageIdentifier: UUID?,
    hint: PayslipUserHint
) async -> Result<PayslipItem, PDFProcessingError>
```

### Primary Path (Vision LLM):
```swift
// Line 140-162
if let visionConfig = resolveVisionLLMConfiguration(),
   let visionParser = LLMPayslipParserFactory.createVisionParser(for: visionConfig) {
    let payslip = try await visionParser.parse(image: croppedImage)
    // Uses VisionLLMPromptTemplate.extractionPrompt
}
```

### Fallback Path (OCR + Text LLM):
```swift
// Line 164-207
// 1. OCR extraction (multiple passes)
// 2. Text LLM parsing
let hintPrefix = llmHintPrefix(for: hint)
let payslip = try await parser.parse(hintPrefix + best.text)
// Uses LLMPrompt.payslip + hint prefix
```

---

## Key Configuration Points

### Verification Threshold:
```swift
// ValidationThresholds.swift
static let verificationTriggerThreshold: Double = 0.9  // 90%
```

### Image Compression:
```swift
// VisionLLMOptimizationConfig.swift
static let defaultCompressionQuality: CGFloat = 0.75  // 75% quality
```

### JSON Mode:
```swift
// Both Vision and Text LLM use:
jsonMode: true  // Forces structured JSON output
```

---

## Current Performance

- **Confidence**: 95% (when parsing succeeds)
- **Verification**: Automatically triggered when confidence < 90%
- **Success Rate**: High (Vision LLM path is primary, OCR is fallback)

---

## Areas for Improvement

1. **Vision Prompt**: Could be more specific about table structure
2. **Verification Prompt**: Could include more guidance on what to check
3. **Text Prompt**: Could include more code normalization rules
4. **Error Handling**: Could provide better feedback on parsing failures

---

**Last Updated**: December 26, 2025
**Related Files**:
- `VisionLLMPromptTemplate.swift`
- `VisionLLMVerificationService.swift`
- `LLMPrompt.swift`
- `PDFProcessingService+Scan.swift`
- `VisionLLMPayslipParser.swift`

