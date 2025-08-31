# January 2023 Tabulated Payslip Reference

## Overview
This document contains the complete data structure from a January 2023 payslip (Statement of Account for 01/2023) which represents the **pre-November 2023 tabulated format** with **4 credit items** instead of the 6 items in Feb 2023.

**Document Type**: Statement of Account  
**Period**: January 2023  
**Format**: Tabulated (Pre-Nov 2023) - 4 Credit Structure  
**Parsing Difficulty**: High (due to tabular layout and variable structure)

## Employee Information
- **Name**: SUNIL SURESH PAWAR
- **Employee ID**: 18/110/206718K
- **CDA A/C NO**: [Account number field]

## Contact Information
- **Contact Tel Nos in PCDA(O), Pune**:
  - PRO CIVIL: (020) 2640-1111/1333/1353/1356
  - PRO ARMY: 6512/6528/7756/7761/7762/7763

## Financial Data Structure

### CREDIT Section (जमा / CREDIT)
| Description | Amount (₹) |
|-------------|------------|
| Basic Pay | 136400 |
| DA | 57722 |
| MSP | 15500 |
| Tpt Allc | 4968 |
| **Total Credit** | **214590** |

### DEBIT Section (नामे / DEBIT)
| Description | Amount (₹) |
|-------------|------------|
| DSOPF Subn | 8184 |
| AGIF | 10000 |
| Incm Tax | 44440 |
| Educ Cess | 2210 |
| L Fee | 748 |
| Fur | 326 |
| Water | 157 |
| **REMITTANCE** | **148525** |
| **Total Debit** | **214590** |

## Key Differences from Feb 2023

### Structural Differences
| **Aspect** | **Jan 2023** | **Feb 2023** |
|------------|--------------|--------------|
| Credit Items | 4 | 6 |
| Missing Credits | SpCmd Pay, A/o Pay & Allce | None |
| Extra Debits | Water (157) | None |
| Total Credits | 214,590 | 364,590 |
| Total Debits | 214,590 | 364,590 |

### Format Analysis
- **4-Credit Structure**: Basic Pay, DA, MSP, Tpt Allc
- **7-Debit Structure**: DSOPF Subn, AGIF, Incm Tax, Educ Cess, L Fee, Fur, Water
- **Parsing Challenge**: Variable number of items requires dynamic detection

## Parser Testing Scenarios

### Expected Extraction Results
When testing parsers against this document, the following should be accurately extracted:

```json
{
  "employeeName": "SUNIL SURESH PAWAR",
  "employeeId": "18/110/206718K",
  "period": "01/2023",
  "basicPay": 136400,
  "da": 57722,
  "msp": 15500,
  "transportAllowance": 4968,
  "grossPay": 214590,
  "dsopfContribution": 8184,
  "agif": 10000,
  "incomeTax": 44440,
  "educationCess": 2210,
  "licenceFee": 748,
  "furniture": 326,
  "water": 157,
  "totalDeductions": 66065,
  "netRemittance": 148525,
  "documentType": "Statement of Account",
  "isTabulated": true,
  "creditStructure": "4-item",
  "parsingDifficulty": "High"
}
```

### Common Parser Failures
1. **Hard-coded 6-item expectation**: Expecting SpCmd Pay and A/o Pay & Allce
2. **Amount misalignment**: Mapping wrong amounts to descriptions
3. **Variable structure handling**: Not adapting to 4-credit format
4. **Dynamic detection failure**: Missing the Water deduction

## Dynamic Parsing Requirements

### For Future Enhancements
- **Variable Structure Detection**: Must detect 4 vs 6 credit items dynamically
- **Adaptive Amount Mapping**: Map amounts based on actual descriptions present
- **Format-Agnostic Logic**: Handle both Jan 2023 and Feb 2023 structures
- **Sequential Extraction**: Extract amounts in order of detected descriptions

### Testing Recommendations
1. Use this document as a **baseline test case** for 4-credit tabulated payslip parsing
2. Verify dynamic detection handles variable credit counts
3. Ensure proper amount-to-description mapping
4. Test both Jan 2023 (4 credits) and Feb 2023 (6 credits) formats

## Parser Implementation Notes

### Dynamic Detection Algorithm
```
1. Scan text for all possible credit descriptions
2. Identify which descriptions are actually present
3. Extract amounts dynamically based on present descriptions
4. Map amounts to descriptions in order
5. Handle variable deduction counts similarly
```

### Validation Checks
- **Credit Count**: 4 items for Jan 2023
- **Debit Count**: 7 items for Jan 2023 (including Water)
- **Total Balance**: Credits = Debits = 214,590
- **Remittance**: 148,525

---

**Document Purpose**: Reference for testing PayslipMax parser accuracy on Jan 2023 4-credit tabulated payslip format  
**Creation Date**: January 2025  
**Usage**: Parser testing, dynamic format validation, variable structure testing
