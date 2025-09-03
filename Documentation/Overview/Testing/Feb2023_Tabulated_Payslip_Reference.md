# February 2023 Tabulated Payslip Reference

## Overview
This document contains the complete data structure from a February 2023 payslip (Statement of Account for 02/2023) which represents the **pre-November 2023 tabulated format** that poses parsing challenges due to its complex tabular structure.

**Document Type**: Statement of Account  
**Period**: February 2023  
**Format**: Tabulated (Pre-Nov 2023)  
**Parsing Difficulty**: High (due to tabular layout)

## Employee Information
- **Name**: SUNIL SURESH PAWAR
- **Employee ID**: 18/110/206718K
- **CDA A/C NO**: [Account number field]

## Contact Information
- **Contact Tel Nos in PCDA(O), Pune**:
  - PRO CIVIL: (020) 2640-1111/1333/1353/1356
  - PRO ARMY: 6512/6528/7756/7761/7762/7763

## Email Contacts
- **TA/DA Grievance**: tada-pcdaopune@nic.in
- **Ledger Grievance**: ledger-pcdaopune@nic.in
- **Rank pay related issue**: rankpay-pcdaopune@nic.in
- **Other grievances**: generalquery-pcdaopune@nic.in

## Grievance Portal
- **URL**: https://pcdaopune.gov.in

## Financial Data Structure

### CREDIT Section (जमा / CREDIT)
| Description | Amount (₹) |
|-------------|------------|
| Basic Pay | 136400 |
| DA | 57722 |
| MSP | 15500 |
| Tpt Allc | 4968 |
| SpCmd Pay | 25000 |
| A/o Pay & Allce | 125000 |
| **Total Credit** | **364590** |

### DEBIT Section (नामे / DEBIT)
| Description | Amount (₹) |
|-------------|------------|
| DSOPF Subn | 8184 |
| AGIF | 10000 |
| Incm Tax | 89444 |
| Educ Cess | 4001 |
| L Fee | 748 |
| Fur | 326 |
| **REMITTANCE** | **251887** |
| **Total Debit** | **364590** |

## Transaction Details (लेन देन का विवरण / DETAILS OF TRANSACTIONS)

### Para-SC Dt. Information
- **Cr PARA-SC Dt.**: 01/09/2022 to 31/01/2023
- **Amount**: ₹125000

### Recovery Details
- **RL/J/P-o Dt.**: 05/02/2021
- **Bldg**: 159/2,Ne

### Date Ranges
- **Dr L fee Dt.**: 01/02/2023 to 28/02/2023 | Amount: ₹748
- **Dr. fur Dt.**: 01/02/2023 to 28/02/2023 | Amount: ₹326

### Part II Orders
- **Part II Orders adjusted in this month**:
  - **Pt II Order No.**: 0287/2022 | **Dated**: 23/12/2022
  - **Pt II Order No.**: 0289/2022 | **Dated**: 23/12/2022

## Key Parsing Challenges

### 1. Tabular Structure Issues
- **Dual Column Layout**: Credit and Debit sections are side-by-side
- **Mixed Languages**: Hindi and English text mixed throughout
- **Complex Headers**: Multiple header levels with translations

### 2. Data Extraction Complexities
- **Nested Information**: Transaction details embedded within main structure
- **Date Ranges**: Multiple date formats and ranges
- **Reference Numbers**: Various order numbers and reference codes
- **Watermark Interference**: Government seal/watermark overlaying text

### 3. Calculation Verification
- **Gross Pay**: ₹364,590
- **Total Deductions**: ₹112,703 (excluding remittance)
- **Net Remittance**: ₹251,887
- **Balance Check**: Credit (₹364,590) = Debit (₹364,590) ✓

## Parser Testing Scenarios

### Expected Extraction Results
When testing parsers against this document, the following should be accurately extracted:

```json
{
  "employeeName": "SUNIL SURESH PAWAR",
  "employeeId": "18/110/206718K",
  "period": "02/2023",
  "basicPay": 136400,
  "da": 57722,
  "msp": 15500,
  "transportAllowance": 4968,
  "specialCommandPay": 25000,
  "arrearsPay": 125000,
  "grossPay": 364590,
  "dsopfContribution": 8184,
  "agif": 10000,
  "incomeTax": 89444,
  "educationCess": 4001,
  "licenceFee": 748,
  "furniture": 326,
  "totalDeductions": 112703,
  "netRemittance": 251887,
  "documentType": "Statement of Account",
  "isTabulated": true,
  "parsingDifficulty": "High"
}
```

### Common Parser Failures
1. **Column Misalignment**: Tabular data often gets misread
2. **Language Confusion**: Hindi/English mixed text causes errors
3. **Watermark Interference**: Government seal affects OCR accuracy
4. **Complex Calculations**: Remittance vs. net pay confusion

## Development Notes

### For Future Enhancements
- **Tabular Detection**: Implement pre-processing to detect tabular layouts
- **Multi-language Support**: Enhanced Hindi/English text recognition
- **Watermark Filtering**: Remove background elements before parsing
- **Context-aware Extraction**: Use field positioning and context clues

### Testing Recommendations
1. Use this document as a **baseline test case** for tabulated payslip parsing
2. Verify all numerical values are extracted correctly
3. Ensure proper handling of dual-language content
4. Test watermark/seal interference resilience

## Important Alert
**PLEASE SEE NEXT PAGE FOR IMPORTANT ALERTS** - Note in original document indicating additional pages with critical information.

---

**Document Purpose**: Reference for testing PayslipMax parser accuracy on pre-Nov 2023 tabulated payslip formats  
**Creation Date**: January 2025  
**Usage**: Parser testing, accuracy validation, format comparison
