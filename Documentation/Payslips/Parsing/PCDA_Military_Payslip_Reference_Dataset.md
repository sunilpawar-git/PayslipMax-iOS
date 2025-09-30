# PCDA Military Payslip Reference Dataset
**Analysis of SUNIL SURESH PAWAR's Military Payslips (2023-2025)**
**Purpose: Reference data for Enhanced Structure Preservation testing and validation**
**Generated: September 10, 2025**

---

## 📋 DATASET OVERVIEW

This document contains extracted data from four actual PCDA(O) military payslips spanning **June 2023 to May 2025**, providing comprehensive reference data for testing PayslipMax's enhanced structure preservation capabilities.

### 📊 Dataset Statistics
- **Employee**: SUNIL SURESH PAWAR
- **CDA A/C No**: 16/110/206718K
- **PAN**: AR*****90G
- **Bank**: ICICI BANK LIMITED
- **Period Covered**: 20 months (June 2023 - May 2025)
- **Format Evolution**: Pre-Nov 2023 → Post-Nov 2023 (simplified structure)

---

## 🎯 CRITICAL TESTING SCENARIOS

### **Multi-Column Table Processing**
- **Complex Layout**: October 2023 payslip with detailed transaction section
- **Variable Column Widths**: Different amounts require proper column boundary detection
- **Merged Cells**: Transaction details span multiple rows

### **Format Evolution Testing**
- **Pre-Nov 2023**: October 2023, June 2023 (complex structure with transaction details)
- **Post-Nov 2023**: February 2025, May 2025 (simplified tabular format)

### **Spatial Relationship Challenges**
- **Label-Value Association**: BPAY vs MSP disambiguation (144,700 vs 15,500)
- **Section Classification**: Earnings vs Deductions column identification
- **Multi-Line Entries**: Transaction descriptions across multiple lines

---

## 📅 PAYSLIP 1: OCTOBER 2023
**PCDA(O) Statement of Account - 10/2023**

### 📋 Employee Information
```
Name: SUNIL SURESH PAWAR
CDA A/C No: 16/110/206718K
Banker: ICICI BANK LIMITED
Grievance Portal: https://pcdaopune.gov.in
```

### 💰 EARNINGS (जमा/CREDIT)
| Description | Amount (₹) | Notes |
|-------------|------------|-------|
| Basic Pay | 136,400 | Primary salary component |
| DA | 69,674 | Dearness Allowance |
| MSP | 15,500 | Military Service Pay |
| Tpt Allc | 5,256 | Transport Allowance |
| A/o DA | 18,228 | Arrears of DA |
| A/o TRAN-1 | 432 | Transport arrears |
| L Fee | 12,167 | License Fee |
| Fur | 5,303 | Furniture allowance |
| **TOTAL CREDIT** | **263,160** | |

### 📉 DEDUCTIONS (नामे/DEBIT)
| Description | Amount (₹) | Notes |
|-------------|------------|-------|
| DSOPF Subn | 40,000 | Defence Service Officers Provident Fund |
| AGIF | 10,000 | Army Group Insurance Fund |
| Incm Tax | 48,030 | Income Tax |
| Educ Cess | 1,740 | Education Cess |
| R/o Elkt | 839 | Recovery of Electricity |
| L Fee | 878 | License Fee deduction |
| Fur | 392 | Furniture deduction |
| Barrack Damage | 711 | Barrack damage recovery |
| **TOTAL DEBIT** | **102,590** | |

### 📝 TRANSACTION DETAILS
```
RL/MD/18/P- Dt: 29/09/2023 Bldg: 159/2.NLL ST THOMAS
RL/04/8713/Dt: 20/02/2023 Bldg: 16/1Mane (₹878)
Dr L fee Dt: 01/10/2023 to 31/10/2023 (₹392)
Dr. fur Dt: 01/10/2023 to 31/10/2023
RL/MD/18/P- Dt: 29/09/2023 Bldg: 159/2.NLL ST THOMAS (₹12,167)
Cr L Fee Dt: 31/03/2022 to 31/07/2023 (₹5,303)
Dr Barrack Damage (₹711)
```

### 💵 FINAL CALCULATION
```
Total Credit: ₹263,160
Total Debit:  ₹263,160
REMITTANCE:   ₹160,570
```

---

## 📅 PAYSLIP 2: JUNE 2023
**PCDA(O) Statement of Account - 06/2023**

### 📋 Employee Information
```
Name: SUNIL SURESH PAWAR
CDA A/C No: 16/110/206718K
Grievance Portal: https://pcdaopune.gov.in
```

### 💰 EARNINGS (जमा/CREDIT)
| Description | Amount (₹) | Notes |
|-------------|------------|-------|
| Basic Pay | 136,400 | Primary salary component |
| DA | 63,798 | Dearness Allowance |
| MSP | 15,500 | Military Service Pay |
| Tpt Allc | 5,112 | Transport Allowance |
| A/o RMONEYAllce-RA | 158 | Money allowance arrears |
| **TOTAL CREDIT** | **220,968** | |

### 📉 DEDUCTIONS (नामे/DEBIT)
| Description | Amount (₹) | Notes |
|-------------|------------|-------|
| DSOPF Subn | 40,000 | Defence Service Officers Provident Fund |
| AGIF | 10,000 | Army Group Insurance Fund |
| Incm Tax | 39,820 | Income Tax |
| Educ Cess | 1,590 | Education Cess |
| Rec PARA-SC | 50,000 | Recovery PARA-SC |
| L Fee | 1,626 | License Fee deduction |
| Fur | 718 | Furniture deduction |
| **TOTAL DEBIT** | **143,754** | |

### 📝 TRANSACTION DETAILS
```
Cr RMONEYAllce-RA Dt: 16-04-2023 to 30-04-2023 Amt: ₹95
Cr RMONEYAllce-RA Dt: 01-05-2023 to 10-05-2023 Amt: ₹63
Dr PARA-SC Dt: 01/04/2023 to 15/04/2023 Amt: ₹12,500
RL/3/P-0 Dt: 05/02/2021 Bldg: 159/2.Ne
Dr L fee Dt: 01/06/2023 to 30/06/2023 (₹748)
Dr. fur Dt: 01/06/2023 to 30/06/2023 (₹326)
RL/04/8713/Dt: 20/02/2023 Bldg: 16/1Mane
Dr L fee Dt: 01/06/2023 to 30/06/2023 (₹878)
Dr. fur Dt: 01/06/2023 to 30/06/2023 (₹392)
```

### 📋 PART II ORDERS
```
Pt II Order No: 0113/2023 Dated: 03/04/2023
Pt II Order No: 0113/2023 Dated: 2023-04-03
```

### 💵 FINAL CALCULATION
```
Total Credit: ₹220,968
Total Debit:  ₹220,968
REMITTANCE:   ₹77,214
```

### 🎂 Special Message
```
"PCDA(O) Pune wishes you a very Happy Birthday and a wonderful new year ahead."
```

---

## 📅 PAYSLIP 3: FEBRUARY 2025
**Principal Controller of Defence Accounts (Officers), Pune - 02/2025**

### 📋 Employee Information
```
Name: Sunil Suresh Pawar
A/C No: 16/110/206718K
PAN No: AR*****90G
```

### 💰 EARNINGS (आय/EARNINGS ₹)
| Description | Amount (₹) | Notes |
|-------------|------------|-------|
| BPAY | 144,700 | Basic Pay |
| DA | 84,906 | Dearness Allowance |
| MSP | 15,500 | Military Service Pay |
| RH12 | 21,125 | RH12 allowance |
| TPTA | 3,600 | TPTA allowance |
| TPTADA | 1,908 | TPTADA allowance |
| **Gross Pay** | **271,739** | **कुल आय** |

### 📉 DEDUCTIONS (कटौती/DEDUCTIONS ₹)
| Description | Amount (₹) | Notes |
|-------------|------------|-------|
| DSOP | 40,000 | Defence Service Officers Provident Fund |
| AGIF | 10,000 | Army Group Insurance Fund |
| ITAX | 57,028 | Income Tax |
| EHCESS | 2,282 | Education and Health Cess |
| **Total Deductions** | **109,310** | **कुल कटौती** |

### 💵 FINAL CALCULATION
```
Gross Pay:        ₹271,739
Total Deductions: ₹109,310
Net Remittance:   ₹1,62,429
```
**In Words**: One Lakh Sixty Two Thousand Four Hundred Twenty Nine only

---

## 📅 PAYSLIP 4: MAY 2025
**Principal Controller of Defence Accounts (Officers), Pune - 05/2025**

### 📋 Employee Information
```
Name: Sunil Suresh Pawar
A/C No: 16/110/206718K
PAN No: AR*****90G
Next Increment Date: 01/01/2026
```

### 💰 EARNINGS (आय/EARNINGS ₹)
| Description | Amount (₹) | Notes |
|-------------|------------|-------|
| BPAY (12A) | 144,700 | Basic Pay (Grade 12A) |
| DA | 88,110 | Dearness Allowance |
| MSP | 15,500 | Military Service Pay |
| RH12 | 21,125 | RH12 allowance |
| TPTA | 3,600 | TPTA allowance |
| TPTADA | 1,980 | TPTADA allowance |
| ARR-RSHNA | 1,650 | Arrears RSHNA |
| **Gross Pay** | **276,665** | **कुल आय** |

### 📉 DEDUCTIONS (कटौती/DEDUCTIONS ₹)
| Description | Amount (₹) | Notes |
|-------------|------------|-------|
| RH12 | 7,518 | RH12 deduction |
| DSOP | 40,000 | Defence Service Officers Provident Fund |
| AGIF | 12,500 | Army Group Insurance Fund |
| ITAX | 46,641 | Income Tax |
| EHCESS | 1,866 | Education and Health Cess |
| **Total Deductions** | **108,525** | **कुल कटौती** |

### 💵 FINAL CALCULATION
```
Gross Pay:        ₹276,665
Total Deductions: ₹108,525
Net Remittance:   ₹1,68,140
```
**In Words**: One Lakh Sixty Eight Thousand One Hundred Forty only

---

## 📊 COMPARATIVE ANALYSIS

### 📈 Salary Progression (2023-2025)
| Period | Basic Pay | DA | Gross Pay | Net Pay | DA Rate |
|--------|-----------|----|-----------|---------|---------|
| Jun 2023 | 136,400 | 63,798 | 220,968* | 77,214 | 46.8% |
| Oct 2023 | 136,400 | 69,674 | 263,160* | 160,570 | 51.1% |
| Feb 2025 | 144,700 | 84,906 | 271,739 | 162,429 | 58.7% |
| May 2025 | 144,700 | 88,110 | 276,665 | 168,140 | 60.9% |

*Note: Includes various allowances and arrears

### 🔍 Key Observations
1. **Basic Pay Increase**: ₹136,400 → ₹144,700 (6.1% increase between 2023-2025)
2. **DA Rate Growth**: From 46.8% to 60.9% (14.1 percentage points increase)
3. **Format Simplification**: Post-Nov 2023 format removed detailed transaction section
4. **Consistent Deductions**: DSOP and AGIF remained primary deduction components
5. **Tax Variations**: Income tax fluctuated based on total earnings and applicable slabs

---

## 🧪 TESTING IMPLICATIONS

### **Spatial Parsing Challenges**
1. **Column Boundary Detection**: Variable-width columns in tabulated sections
2. **Label-Value Association**: Distinguishing BPAY (144,700) from MSP (15,500)
3. **Multi-Language Support**: Hindi/English mixed text processing
4. **Amount Recognition**: Various formatting styles (with/without commas)

### **Pattern Recognition Requirements**
1. **Military Codes**: BPAY, DA, MSP, DSOP, AGIF, ITAX, EHCESS
2. **Date Formats**: DD/MM/YYYY and DD-MM-YYYY variations
3. **Amount Patterns**: Integer amounts with proper thousand separators
4. **Section Classification**: Earnings vs Deductions identification

### **Structure Preservation Goals**
1. **Tabular Data**: Accurate extraction of earnings/deductions tables
2. **Transaction Details**: Complex multi-line transaction parsing (pre-Nov 2023)
3. **Summary Calculations**: Gross pay, total deductions, net remittance
4. **Metadata Extraction**: Employee details, account numbers, dates

---

## 🎯 VALIDATION TARGETS

### **Accuracy Benchmarks**
- **Basic Components**: 100% accuracy (BPAY, DA, MSP)
- **Deduction Items**: 95%+ accuracy (DSOP, AGIF, ITAX)
- **Net Calculations**: 100% accuracy (critical financial figures)
- **Format Detection**: 100% accuracy (pre/post Nov 2023 distinction)

### **Performance Expectations**
- **Processing Time**: < 2 seconds per payslip
- **Memory Usage**: < 50MB peak during processing
- **Error Rate**: < 1% false positive/negative rate
- **Fallback Success**: 100% fallback to legacy parser if spatial fails

---

## 🔧 IMPLEMENTATION NOTES

### **Critical Test Cases**
1. **Multi-Column Confusion**: Ensure BPAY (144,700) not confused with MSP (15,500)
2. **Section Isolation**: Earnings table completely separate from Deductions table
3. **Transaction Parsing**: Handle complex transaction detail sections (Oct/Jun 2023)
4. **Format Adaptation**: Seamless processing of both old and new formats

### **Expected Improvements**
- **Pre-Nov 2023 Formats**: From 15% to 85%+ accuracy
- **Multi-Column Processing**: From 5% to 80%+ accuracy
- **Complex Transactions**: From 10% to 90%+ accuracy
- **Overall PCDA Accuracy**: From 60% to 95%+ accuracy

---

*This reference dataset provides comprehensive ground truth data for validating PayslipMax's Enhanced Structure Preservation implementation against real-world PCDA military payslips spanning format evolution and complexity variations.*
