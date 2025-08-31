Document picked: file:///private/var/mobile/Containers/Shared/AppGroup/13BEC3B8-94DE-4ABD-BD72-BE0DD9718F6E/File%20Provider%20Storage/Payslips/2023/03%20Mar%202023.pdf
Copying file to: file:///private/var/mobile/Containers/Data/Application/B66EC707-760C-49C2-BD08-4099DD2D3BB7/tmp/90DD891F-E282-4F05-B911-790122A030A1.pdf
Copied file size: 30073 bytes
[PDFProcessingCoordinator] Processing payslip PDF from: file:///private/var/mobile/Containers/Data/Application/B66EC707-760C-49C2-BD08-4099DD2D3BB7/tmp/90DD891F-E282-4F05-B911-790122A030A1.pdf
[PDFProcessingCoordinator] PDF is password protected, showing password entry
[PasswordProtectedPDFHandler] Showing password entry for PDF with 30073 bytes
[PasswordProtectedPDFHandler] Confirmed PDF is locked
[PasswordProtectedPDFHandler] Setting showPasswordEntryView to true
The view service did terminate with error: Error Domain=_UIViewServiceErrorDomain Code=1 "(null)" UserInfo={Terminated=disconnect method}
App is being debugged, do not track this hang
Hang detected: 0.32s (debugger attached, not reporting)
PasswordProtectedPDFView: Attempting to unlock PDF with password: 5***
PDFService: PDF unlocked successfully
PDFService: Military PDF detected
PDFService: PCDA PDF detected
PDFService: Using special military PDF handling
PDFService: Standard unlocking worked for military PDF
[PDFProcessingCoordinator] Handling unlocked PDF with 56103 bytes
[PayslipValidationService] Is password protected: false
[PDFProcessingHandler] PDF is password protected: false
[PDFProcessingHandler] PDF document is locked: false
[PDFTextExtractor] Starting memory-efficient text extraction for document with 4 pages
[PDFTextExtractionService] Memory after page 1/4: 144.8 MB (Δ144 KB)
[PDFTextExtractionService] Memory after page 2/4: 145.9 MB (Δ1.1 MB)
[PDFTextExtractionService] Memory after page 3/4: 146.3 MB (Δ352 KB)
[PDFTextExtractionService] Memory after page 4/4: 146.4 MB (Δ160 KB)
[PDFTextExtractionService] Successfully extracted 7321 characters from 4 pages
[PDFTextExtractor] Text extraction completed in 0.02 seconds
[PDFTextExtractor] Extracted 7321 characters
[PayslipFormatDetectionService] Detecting format from 7321 characters of text
[PayslipFormatDetectionService] Detected military format
[PDFProcessingCoordinator] Detected format: military
[PDFProcessingCoordinator] PDF document created successfully with 4 pages
[PDFProcessingCoordinator] Processing PDF data with 56103 bytes
[PDFProcessingHandler] Process PDF Data started with 56103 bytes
[PDFProcessingHandler] Valid PDF document created with 4 pages
[PayslipValidationService] Is password protected: false
[PDFProcessingHandler] PDF is password protected: false
[PDFProcessingHandler] PDF document is locked: false
[PDFTextExtractor] Starting memory-efficient text extraction for document with 4 pages
[PDFTextExtractionService] Memory after page 1/4: 146.9 MB (Δ128 KB)
[PDFTextExtractionService] Memory after page 2/4: 146.9 MB (ΔZero KB)
[PDFTextExtractionService] Memory after page 3/4: 146.9 MB (ΔZero KB)
[PDFTextExtractionService] Memory after page 4/4: 147 MB (Δ32 KB)
[PDFTextExtractionService] Successfully extracted 7321 characters from 4 pages
[PDFTextExtractor] Text extraction completed in 0.02 seconds
[PDFTextExtractor] Extracted 7321 characters
[PayslipFormatDetectionService] Detecting format from 7321 characters of text
[PayslipFormatDetectionService] Detected military format
[PDFProcessingHandler] Detected format: military
[PDFProcessingHandler] Calling pdfProcessingService.processPDFData
[PDFProcessingService] Processing PDF of size: 56103 bytes
[PayslipValidationService] Validating PDF structure
[PayslipValidationService] Is password protected: false
[ValidationStep] Completed in 0.0001289844512939453 seconds
[PDFTextExtractionService] Memory after page 1/4: 147.3 MB (Δ368 KB)
[PDFTextExtractionService] Memory after page 2/4: 147.4 MB (Δ80 KB)
[PDFTextExtractionService] Memory after page 3/4: 147.6 MB (Δ208 KB)
[PDFTextExtractionService] Memory after page 4/4: 147.6 MB (Δ48 KB)
[PDFTextExtractionService] Successfully extracted 7321 characters from 4 pages
[PayslipValidationService] Validating payslip content from 7321 characters
[PayslipValidationService] Payslip validation - valid: true, confidence: 0.6
[TextExtractionStep] Extracted 7321 characters of text
[TextExtractionStep] Completed in 0.02404797077178955 seconds
[PayslipFormatDetectionService] Detecting format from 7321 characters of text
[PayslipFormatDetectionService] Detected military format
[FormatDetectionStep] Detected format: military
[FormatDetectionStep] Completed in 3.3020973205566406e-05 seconds
[MilitaryPayslipProcessor] Processing military payslip from 7321 characters
[MilitaryPayslipProcessor] Extracted MSP: 136400.0
[MilitaryPayslipProcessor] Extracted ITAX: 239862.0
[MilitaryPayslipProcessor] Attempting Phase 6.3 tabular data extraction
[MilitaryPayslipProcessor] PCDA marker detected: PCDA
[LiteRTService] Initializing LiteRT service
[MilitaryPayslipProcessor] PCDA format detected - routing to enhanced spatial parsing pipeline
[MilitaryPayslipProcessor] Creating synthetic text elements from parsed text
[MilitaryPayslipProcessor] Created 1161 synthetic text elements for spatial analysis
MilitaryFinancialDataExtractor: Starting Phase 6.3 spatial table analysis with 1161 text elements
MilitaryFinancialDataExtractor: PCDA table structure detected with 189 data rows
MilitaryFinancialDataExtractor: Created PCDA spatial table with 1 data rows
MilitaryFinancialDataExtractor: Processed PCDA rows - credits: 0, debits: 0
PCDAFinancialValidator: Starting validation - credits: 0, debits: 0
MilitaryFinancialDataExtractor: PCDA validation FAILED: No financial data extracted
MilitaryFinancialDataExtractor: All spatial methods failed, using fallback text-based extraction
MilitaryFinancialDataExtractor: Starting tabular data extraction from 7321 characters
MilitaryFinancialDataExtractor: Detected PCDA format for tabular data extraction
MilitaryFinancialDataExtractor: Trying simplified PCDA parser
SimplifiedPCDATableParser: Processing text-based PCDA format
SimplifiedPCDATableParser: Starting enhanced PCDA pattern extraction
SimplifiedPCDATableParser: Attempting PCDA table structure extraction
SimplifiedPCDATableParser: Single massive line detected, trying alternative splitting
SimplifiedPCDATableParser: Analyzing PDF text structure - Total lines: 2
SimplifiedPCDATableParser: First 10 lines:
Line 0: '03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : ...'
Line 1: 'Basic Pay DA MSP 136400 57722 15500 Tpt Allc SpCmd Pay 4968 25000 A/o RMONEYAllce-RA 136 A/o Pay & A...'
SimplifiedPCDATableParser: Found PCDA credit/debit header at line 0: 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) STATEMENT OF ACCOUNT FOR 03/2023 NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / CREDIT / DEBIT / DETAILS OF TRANSACTIONS
SimplifiedPCDATableParser: Table index issues (start: 3, total: 2), searching for condensed data line
SimplifiedPCDATableParser: Trying enhanced extraction as fallback for irregular pattern
SimplifiedPCDATableParser: Detected Feb 2023 tabulated format with specific sequence
SimplifiedPCDATableParser: Starting cluster-based analysis
SimplifiedPCDATableParser: Searching through 1 lines for financial data
SimplifiedPCDATableParser: Line 0: hasFinancialCodes=true, hasAmounts=true, length=7321
SimplifiedPCDATableParser: Line 0 content: '03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) STATEMENT OF ACCOUNT FOR 03/2023 NAME : SUNIL SURESH PAWAR : 16/110/...'
SimplifiedPCDATableParser: ✅ Selected line 0 as main data line
SimplifiedPCDATableParser: Found data line: 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) STATEMENT OF ACCOU...
SimplifiedPCDATableParser: Looking for pattern 'Basic Pay DA MSP' expecting 3 amounts
SimplifiedPCDATableParser: Found pattern 'Basic Pay DA MSP' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Found pattern start at word index 65: 'Basic'
SimplifiedPCDATableParser: Searching for amounts starting from word index 69
SimplifiedPCDATableParser: Found amount 136400.0 at index 69
SimplifiedPCDATableParser: Found amount 57722.0 at index 70
SimplifiedPCDATableParser: Found amount 15500.0 at index 71
SimplifiedPCDATableParser: Extracted amounts: [136400.0, 57722.0, 15500.0]
SimplifiedPCDATableParser: Mapped to descriptions: [("Basic Pay", 136400.0), ("DA", 57722.0), ("MSP", 15500.0)]
SimplifiedPCDATableParser: Looking for pattern 'Tpt Allc SpCmd Pay' expecting 2 amounts
SimplifiedPCDATableParser: Found pattern 'Tpt Allc SpCmd Pay' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Found pattern start at word index 72: 'Tpt'
SimplifiedPCDATableParser: Searching for amounts starting from word index 76
SimplifiedPCDATableParser: Found amount 4968.0 at index 76
SimplifiedPCDATableParser: Found amount 25000.0 at index 77
SimplifiedPCDATableParser: Extracted amounts: [4968.0, 25000.0]
SimplifiedPCDATableParser: Mapped to descriptions: [("Tpt Allc", 4968.0), ("SpCmd Pay", 25000.0)]
SimplifiedPCDATableParser: Looking for pattern 'A/o.*Pay.*Allce' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'A/o RMONEYAllce-RA 136 A/o Pay & Allce 136 DSOPF Subn AGIF Incm Tax Educ Cess L Fee Fur Water 40000 10000 45630 1830 7801 3475 1235 Cr RMONEYAllce-RA Dt. 18-12-2022 to 18-12-2022 Amt : 136 Cr RMONEYAllce-RA Dt. 28/01/2023 to 28/01/2023 Amt : 136 RL/04/8713/ Dt: 20/02/2023 Bldg : 16/1Maneks AOGEEASTAG Dr L fee Dt : 03/08/2022 to 31/03/2023 7053 Dr. fur Dt : 03/08/2022 to 31/03/2023 3149 RL/04/8661/ P- Dt: 20/02/2023 Bldg : 16/1Maneks AOGEEASTAG Dr Water (142000 Units) Dt : 03/08/2022 to 31/12/2022 1235 RL//3/ P-0 Dt: 05/02/2021 Bldg : 159/2.Ne Dr L fee Dt : 01/03/2023 to 31/03/2023 748 Dr. fur Dt : 01/03/2023 to 31/03/2023 326 Part II Orders adjusted in this month Pt II Order No : 0012/2023 Dated : 09/01/2023 Pt II Order No : 0023/2023 Dated : 29/01/2023 REMITTANCE 129891 Total Credit 239862 Total Debit 239862 PLEASE SEE NEXT PAGE FOR IMPORTANT ALERTS. Note: This is a system generated document. Page - 1 / 403/2023 STATEMENT OF ACCOUNT FOR 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in * IMPORTANT ALERT * (1)  All Units / Formations are advised to ensure submission of soft copies of Part-II Orders published through HRMS. The .xml file should be uploaded on OASIS. Units not having access to ADN connectivity can send .xml files in CD to AG/MP 5&6. Hard copies may please be sent as per existing orders. (2)  a) Advances starting with DAK ID 'FB' are advances generate for booking of AIR Tickets through DTS portal by the Officers. Officers are advised to ensure submission of the corresponding claim for the Air Tickets booked through DTS along with tickets and Boarding Passes. Claims for DTS tickets, if not submitted within prescribed time limit, advance generated due to DTS will be recovered as per existing provisions. b) If the DTS tickets are cancelled, claim for reimbursement of cancellation charges along with sanction under TR 44b is required to be submitted to this office on priority to link the same. (3) w.e.f. 01.08.2020, advance for DA portion on Temporary Duty can also be obtained from DTS portal in addition to booking of Air/Train tickets from DTS. (4) Please ensure that Part-II order notifying casualties like DEPUTE/ SECONDMENT/DISMISSAL are published in time to avoid closing of IRLA with Debit Balance. (6) Officers who are willing to opt for new IT Regime may kindly use the utility available on PCDA(O) Website. HEADLINES (Please visit our website https://pcdaopune.gov.in for details.) * Based on feedback from Officers, we have increased the word limit and time limit for Grievance Module. All officers are requested to kindly use Grievance Module available on the website of PCDA(O) for prompt redressal of grievances. * Pay Slips, DSOP Fund Annual Statements and Form-16 are now available on OASIS App on ADN as well as on ARMAAN Mobile App. * Processing of all dues of retiring officers is now being completed well ahead of their date of retirement and the status intimated to them through D.O. letters alongwith a copy of their PPOs. * D.O. letters are being sent to newly commissioned officers, containing details about opening of their accounts in PCDA(O). If you see change in your CDA A/c Number .... CDA A/C No.is alloted to all officers in the format NN/NNN/NNNNNNA (N stands for Number, A stands for Alphabet.) The first five digits at the begining of this number i.e. NN/NNN are subject to CHANGE when our internal task distribution is changed in Ledger Wing.You need not worry about such change. The last six digits along with check alpha i.e. NNNNNNA is the number which will REMAIN FIXED THROUGHOUT THE SERVICE of an officer. PLEASE QUOTE CORRECT CDA ACCOUNT NUMBER IN ALL CORRESPONDENCE TO AVOID DELAY IN RESPONSE. Note: This is a system generated document. Page - 2 / 403/2023 STATEMENT OF ACCOUNT FOR 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / INCOME TAX DETAILS (New Tax Regime) 1. Pay & Allce upto 31/03/2023 2. Taxable Income upto 31/03/2023 Excluding HRA 3. Estimated future taxable pay (Curr month salary x remaining months) 239862 239590 2635490 4. H.R.A / H.R.R. (Taxable Amount) 0 5. Income from other Source/House Property 6. Total taxable pay (Sl.No. 2+3+4+5) 2875080 7. Other taxable income (Ent.Allce,etc.) * 8. Deductions Under Chapter VI-A Savings Declared Savings Cleared Actual Amount a) 80C 150000 0 0 600000 b) 80D c) 80DD d) 80E e) 80DDB f) 80U g) 80G(G1+G2) 0 0 0 0 h) Neg. Inc from House Property *Valid upto Nov 2023 Max permissible exemption from IT under Chapter VI-A Standard Deduction 50000 9. Net Taxable Income ((Sl.No. 6 + Sl.No. 7) - (Sl.No. 8)) 10. Total Income Tax (Tax on Sl.No. 9) 11. Income Tax Deducted 45630 12. Educ.Cess Deducted 1830 13. Saving Thru IRLA upto 03/2023 150000 2825352 547605 50000 14. Est.Savings for 2022-2023 600000 15. Personal Savings Declared 16. Personal Savings Cleared / DSOP FUND FOR THE CURRENT YEAR UPTO 28/02/2023 OPENING BALANCE 540908 SUBSCRIPTION 87864 REFUND 0 MISC ADJ 0 WITHDRAWAL 0 CLOSING BALANCE 628772 TYPE HBA MCA PCA / LOANS & ADVANCES UPTO 28/02/2023 TOTAL AMOUNT REFUNDED CLOSING BALANCE 0 0 0 0 0 0 0 0 0 * INDICATES RECOVERY OF INTEREST Note: This is a system generated document. Page - 3 / 403/2023 STATEMENT OF ACCOUNT FOR 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in DETAILS OF ARREARS / RECOVERY POSTED IN IRLA FROM DATE TO DATE TOTAL AARS TAX ARRS TOTAL REC TAX-REC ARR RATE REC RATE MESSAGE 18/12/2022 28/01/2023 18/12/2022 28/01/2023 136 136 0 0 0 0 0 4229 0 4229 0 Cr. RMONEYAllce-RA 0 Cr. RMONEYAllce' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Credit clusters found: 5 items
SimplifiedPCDATableParser: Looking for pattern 'DSOPF.*Subn' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'DSOPF Subn' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Looking for pattern 'AGIF' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'AGIF' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Found pattern start at word index 88: 'AGIF'
SimplifiedPCDATableParser: Searching for amounts starting from word index 89
SimplifiedPCDATableParser: Extracted amounts: []
SimplifiedPCDATableParser: Mapped to descriptions: []
SimplifiedPCDATableParser: Looking for pattern 'Incm.*Tax' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'Incm Tax Educ Cess L Fee Fur Water 40000 10000 45630 1830 7801 3475 1235 Cr RMONEYAllce-RA Dt. 18-12-2022 to 18-12-2022 Amt : 136 Cr RMONEYAllce-RA Dt. 28/01/2023 to 28/01/2023 Amt : 136 RL/04/8713/ Dt: 20/02/2023 Bldg : 16/1Maneks AOGEEASTAG Dr L fee Dt : 03/08/2022 to 31/03/2023 7053 Dr. fur Dt : 03/08/2022 to 31/03/2023 3149 RL/04/8661/ P- Dt: 20/02/2023 Bldg : 16/1Maneks AOGEEASTAG Dr Water (142000 Units) Dt : 03/08/2022 to 31/12/2022 1235 RL//3/ P-0 Dt: 05/02/2021 Bldg : 159/2.Ne Dr L fee Dt : 01/03/2023 to 31/03/2023 748 Dr. fur Dt : 01/03/2023 to 31/03/2023 326 Part II Orders adjusted in this month Pt II Order No : 0012/2023 Dated : 09/01/2023 Pt II Order No : 0023/2023 Dated : 29/01/2023 REMITTANCE 129891 Total Credit 239862 Total Debit 239862 PLEASE SEE NEXT PAGE FOR IMPORTANT ALERTS. Note: This is a system generated document. Page - 1 / 403/2023 STATEMENT OF ACCOUNT FOR 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in * IMPORTANT ALERT * (1)  All Units / Formations are advised to ensure submission of soft copies of Part-II Orders published through HRMS. The .xml file should be uploaded on OASIS. Units not having access to ADN connectivity can send .xml files in CD to AG/MP 5&6. Hard copies may please be sent as per existing orders. (2)  a) Advances starting with DAK ID 'FB' are advances generate for booking of AIR Tickets through DTS portal by the Officers. Officers are advised to ensure submission of the corresponding claim for the Air Tickets booked through DTS along with tickets and Boarding Passes. Claims for DTS tickets, if not submitted within prescribed time limit, advance generated due to DTS will be recovered as per existing provisions. b) If the DTS tickets are cancelled, claim for reimbursement of cancellation charges along with sanction under TR 44b is required to be submitted to this office on priority to link the same. (3) w.e.f. 01.08.2020, advance for DA portion on Temporary Duty can also be obtained from DTS portal in addition to booking of Air/Train tickets from DTS. (4) Please ensure that Part-II order notifying casualties like DEPUTE/ SECONDMENT/DISMISSAL are published in time to avoid closing of IRLA with Debit Balance. (6) Officers who are willing to opt for new IT Regime may kindly use the utility available on PCDA(O) Website. HEADLINES (Please visit our website https://pcdaopune.gov.in for details.) * Based on feedback from Officers, we have increased the word limit and time limit for Grievance Module. All officers are requested to kindly use Grievance Module available on the website of PCDA(O) for prompt redressal of grievances. * Pay Slips, DSOP Fund Annual Statements and Form-16 are now available on OASIS App on ADN as well as on ARMAAN Mobile App. * Processing of all dues of retiring officers is now being completed well ahead of their date of retirement and the status intimated to them through D.O. letters alongwith a copy of their PPOs. * D.O. letters are being sent to newly commissioned officers, containing details about opening of their accounts in PCDA(O). If you see change in your CDA A/c Number .... CDA A/C No.is alloted to all officers in the format NN/NNN/NNNNNNA (N stands for Number, A stands for Alphabet.) The first five digits at the begining of this number i.e. NN/NNN are subject to CHANGE when our internal task distribution is changed in Ledger Wing.You need not worry about such change. The last six digits along with check alpha i.e. NNNNNNA is the number which will REMAIN FIXED THROUGHOUT THE SERVICE of an officer. PLEASE QUOTE CORRECT CDA ACCOUNT NUMBER IN ALL CORRESPONDENCE TO AVOID DELAY IN RESPONSE. Note: This is a system generated document. Page - 2 / 403/2023 STATEMENT OF ACCOUNT FOR 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / INCOME TAX DETAILS (New Tax Regime) 1. Pay & Allce upto 31/03/2023 2. Taxable Income upto 31/03/2023 Excluding HRA 3. Estimated future taxable pay (Curr month salary x remaining months) 239862 239590 2635490 4. H.R.A / H.R.R. (Taxable Amount) 0 5. Income from other Source/House Property 6. Total taxable pay (Sl.No. 2+3+4+5) 2875080 7. Other taxable income (Ent.Allce,etc.) * 8. Deductions Under Chapter VI-A Savings Declared Savings Cleared Actual Amount a) 80C 150000 0 0 600000 b) 80D c) 80DD d) 80E e) 80DDB f) 80U g) 80G(G1+G2) 0 0 0 0 h) Neg. Inc from House Property *Valid upto Nov 2023 Max permissible exemption from IT under Chapter VI-A Standard Deduction 50000 9. Net Taxable Income ((Sl.No. 6 + Sl.No. 7) - (Sl.No. 8)) 10. Total Income Tax (Tax on Sl.No. 9) 11. Income Tax Deducted 45630 12. Educ.Cess Deducted 1830 13. Saving Thru IRLA upto 03/2023 150000 2825352 547605 50000 14. Est.Savings for 2022-2023 600000 15. Personal Savings Declared 16. Personal Savings Cleared / DSOP FUND FOR THE CURRENT YEAR UPTO 28/02/2023 OPENING BALANCE 540908 SUBSCRIPTION 87864 REFUND 0 MISC ADJ 0 WITHDRAWAL 0 CLOSING BALANCE 628772 TYPE HBA MCA PCA / LOANS & ADVANCES UPTO 28/02/2023 TOTAL AMOUNT REFUNDED CLOSING BALANCE 0 0 0 0 0 0 0 0 0 * INDICATES RECOVERY OF INTEREST Note: This is a system generated document. Page - 3 / 403/2023 STATEMENT OF ACCOUNT FOR 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in DETAILS OF ARREARS / RECOVERY POSTED IN IRLA FROM DATE TO DATE TOTAL AARS TAX ARRS TOTAL REC TAX-REC ARR RATE REC RATE MESSAGE 18/12/2022 28/01/2023 18/12/2022 28/01/2023 136 136 0 0 0 0 0 4229 0 4229 0 Cr. RMONEYAllce-RA 0 Cr. RMONEYAllce-RA TOTAL ARREARS / RECOVERIES Arrears : 272 Taxable Arrears : 0 Recovery : 0 Tax' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Looking for pattern 'Educ.*Cess' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'Educ Cess L Fee Fur Water 40000 10000 45630 1830 7801 3475 1235 Cr RMONEYAllce-RA Dt. 18-12-2022 to 18-12-2022 Amt : 136 Cr RMONEYAllce-RA Dt. 28/01/2023 to 28/01/2023 Amt : 136 RL/04/8713/ Dt: 20/02/2023 Bldg : 16/1Maneks AOGEEASTAG Dr L fee Dt : 03/08/2022 to 31/03/2023 7053 Dr. fur Dt : 03/08/2022 to 31/03/2023 3149 RL/04/8661/ P- Dt: 20/02/2023 Bldg : 16/1Maneks AOGEEASTAG Dr Water (142000 Units) Dt : 03/08/2022 to 31/12/2022 1235 RL//3/ P-0 Dt: 05/02/2021 Bldg : 159/2.Ne Dr L fee Dt : 01/03/2023 to 31/03/2023 748 Dr. fur Dt : 01/03/2023 to 31/03/2023 326 Part II Orders adjusted in this month Pt II Order No : 0012/2023 Dated : 09/01/2023 Pt II Order No : 0023/2023 Dated : 29/01/2023 REMITTANCE 129891 Total Credit 239862 Total Debit 239862 PLEASE SEE NEXT PAGE FOR IMPORTANT ALERTS. Note: This is a system generated document. Page - 1 / 403/2023 STATEMENT OF ACCOUNT FOR 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in * IMPORTANT ALERT * (1)  All Units / Formations are advised to ensure submission of soft copies of Part-II Orders published through HRMS. The .xml file should be uploaded on OASIS. Units not having access to ADN connectivity can send .xml files in CD to AG/MP 5&6. Hard copies may please be sent as per existing orders. (2)  a) Advances starting with DAK ID 'FB' are advances generate for booking of AIR Tickets through DTS portal by the Officers. Officers are advised to ensure submission of the corresponding claim for the Air Tickets booked through DTS along with tickets and Boarding Passes. Claims for DTS tickets, if not submitted within prescribed time limit, advance generated due to DTS will be recovered as per existing provisions. b) If the DTS tickets are cancelled, claim for reimbursement of cancellation charges along with sanction under TR 44b is required to be submitted to this office on priority to link the same. (3) w.e.f. 01.08.2020, advance for DA portion on Temporary Duty can also be obtained from DTS portal in addition to booking of Air/Train tickets from DTS. (4) Please ensure that Part-II order notifying casualties like DEPUTE/ SECONDMENT/DISMISSAL are published in time to avoid closing of IRLA with Debit Balance. (6) Officers who are willing to opt for new IT Regime may kindly use the utility available on PCDA(O) Website. HEADLINES (Please visit our website https://pcdaopune.gov.in for details.) * Based on feedback from Officers, we have increased the word limit and time limit for Grievance Module. All officers are requested to kindly use Grievance Module available on the website of PCDA(O) for prompt redressal of grievances. * Pay Slips, DSOP Fund Annual Statements and Form-16 are now available on OASIS App on ADN as well as on ARMAAN Mobile App. * Processing of all dues of retiring officers is now being completed well ahead of their date of retirement and the status intimated to them through D.O. letters alongwith a copy of their PPOs. * D.O. letters are being sent to newly commissioned officers, containing details about opening of their accounts in PCDA(O). If you see change in your CDA A/c Number .... CDA A/C No.is alloted to all officers in the format NN/NNN/NNNNNNA (N stands for Number, A stands for Alphabet.) The first five digits at the begining of this number i.e. NN/NNN are subject to CHANGE when our internal task distribution is changed in Ledger Wing.You need not worry about such change. The last six digits along with check alpha i.e. NNNNNNA is the number which will REMAIN FIXED THROUGHOUT THE SERVICE of an officer. PLEASE QUOTE CORRECT CDA ACCOUNT NUMBER IN ALL CORRESPONDENCE TO AVOID DELAY IN RESPONSE. Note: This is a system generated document. Page - 2 / 403/2023 STATEMENT OF ACCOUNT FOR 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / INCOME TAX DETAILS (New Tax Regime) 1. Pay & Allce upto 31/03/2023 2. Taxable Income upto 31/03/2023 Excluding HRA 3. Estimated future taxable pay (Curr month salary x remaining months) 239862 239590 2635490 4. H.R.A / H.R.R. (Taxable Amount) 0 5. Income from other Source/House Property 6. Total taxable pay (Sl.No. 2+3+4+5) 2875080 7. Other taxable income (Ent.Allce,etc.) * 8. Deductions Under Chapter VI-A Savings Declared Savings Cleared Actual Amount a) 80C 150000 0 0 600000 b) 80D c) 80DD d) 80E e) 80DDB f) 80U g) 80G(G1+G2) 0 0 0 0 h) Neg. Inc from House Property *Valid upto Nov 2023 Max permissible exemption from IT under Chapter VI-A Standard Deduction 50000 9. Net Taxable Income ((Sl.No. 6 + Sl.No. 7) - (Sl.No. 8)) 10. Total Income Tax (Tax on Sl.No. 9) 11. Income Tax Deducted 45630 12. Educ.Cess' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Looking for pattern 'L.*Fee' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'l Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) STATEMENT OF ACCOUNT FOR 03/2023 NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / CREDIT / DEBIT / DETAILS OF TRANSACTIONS DESCRIPTION AMOUNT DESCRIPTION AMOUNT Basic Pay DA MSP 136400 57722 15500 Tpt Allc SpCmd Pay 4968 25000 A/o RMONEYAllce-RA 136 A/o Pay & Allce 136 DSOPF Subn AGIF Incm Tax Educ Cess L Fee Fur Water 40000 10000 45630 1830 7801 3475 1235 Cr RMONEYAllce-RA Dt. 18-12-2022 to 18-12-2022 Amt : 136 Cr RMONEYAllce-RA Dt. 28/01/2023 to 28/01/2023 Amt : 136 RL/04/8713/ Dt: 20/02/2023 Bldg : 16/1Maneks AOGEEASTAG Dr L fee Dt : 03/08/2022 to 31/03/2023 7053 Dr. fur Dt : 03/08/2022 to 31/03/2023 3149 RL/04/8661/ P- Dt: 20/02/2023 Bldg : 16/1Maneks AOGEEASTAG Dr Water (142000 Units) Dt : 03/08/2022 to 31/12/2022 1235 RL//3/ P-0 Dt: 05/02/2021 Bldg : 159/2.Ne Dr L fee Dt : 01/03/2023 to 31/03/2023 748 Dr. fur Dt : 01/03/2023 to 31/03/2023 326 Part II Orders adjusted in this month Pt II Order No : 0012/2023 Dated : 09/01/2023 Pt II Order No : 0023/2023 Dated : 29/01/2023 REMITTANCE 129891 Total Credit 239862 Total Debit 239862 PLEASE SEE NEXT PAGE FOR IMPORTANT ALERTS. Note: This is a system generated document. Page - 1 / 403/2023 STATEMENT OF ACCOUNT FOR 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in * IMPORTANT ALERT * (1)  All Units / Formations are advised to ensure submission of soft copies of Part-II Orders published through HRMS. The .xml file should be uploaded on OASIS. Units not having access to ADN connectivity can send .xml files in CD to AG/MP 5&6. Hard copies may please be sent as per existing orders. (2)  a) Advances starting with DAK ID 'FB' are advances generate for booking of AIR Tickets through DTS portal by the Officers. Officers are advised to ensure submission of the corresponding claim for the Air Tickets booked through DTS along with tickets and Boarding Passes. Claims for DTS tickets, if not submitted within prescribed time limit, advance generated due to DTS will be recovered as per existing provisions. b) If the DTS tickets are cancelled, claim for reimbursement of cancellation charges along with sanction under TR 44b is required to be submitted to this office on priority to link the same. (3) w.e.f. 01.08.2020, advance for DA portion on Temporary Duty can also be obtained from DTS portal in addition to booking of Air/Train tickets from DTS. (4) Please ensure that Part-II order notifying casualties like DEPUTE/ SECONDMENT/DISMISSAL are published in time to avoid closing of IRLA with Debit Balance. (6) Officers who are willing to opt for new IT Regime may kindly use the utility available on PCDA(O) Website. HEADLINES (Please visit our website https://pcdaopune.gov.in for details.) * Based on fee' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Looking for pattern 'Fur' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'Fur' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Found pattern start at word index 95: 'Fur'
SimplifiedPCDATableParser: Searching for amounts starting from word index 96
SimplifiedPCDATableParser: Found amount 40000.0 at index 97
SimplifiedPCDATableParser: Extracted amounts: [40000.0]
SimplifiedPCDATableParser: Mapped to descriptions: [("Fur", 40000.0)]
SimplifiedPCDATableParser: Looking for pattern 'Water' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'Water' in text
SimplifiedPCDATableParser: Total words in line: 1161
SimplifiedPCDATableParser: Found pattern start at word index 96: 'Water'
SimplifiedPCDATableParser: Searching for amounts starting from word index 97
SimplifiedPCDATableParser: Found amount 40000.0 at index 97
SimplifiedPCDATableParser: Extracted amounts: [40000.0]
SimplifiedPCDATableParser: Mapped to descriptions: [("Water", 40000.0)]
SimplifiedPCDATableParser: Debit clusters found: 2 items
SimplifiedPCDATableParser: Cluster analysis extracted 7 items: [("Basic Pay", 136400.0), ("DA", 57722.0), ("MSP", 15500.0), ("Tpt Allc", 4968.0), ("SpCmd Pay", 25000.0), ("Fur", 40000.0), ("Water", 40000.0)]
SimplifiedPCDATableParser: Tabulated format extraction successful - found 7 pairs
SimplifiedPCDATableParser: Direct earning match for Basic Pay
SimplifiedPCDATableParser: Direct earning match for DA
SimplifiedPCDATableParser: Direct earning match for MSP
SimplifiedPCDATableParser: Direct earning match for Tpt Allc
SimplifiedPCDATableParser: Direct earning match for SpCmd Pay
SimplifiedPCDATableParser: Direct deduction match for Fur
SimplifiedPCDATableParser: Direct deduction match for Fur
SimplifiedPCDATableParser: No deduction match for Water
SimplifiedPCDATableParser: No earning match for Water
SimplifiedPCDATableParser: No deduction match for Water
SimplifiedPCDATableParser: Extracted credit via fallback - SpCmd Pay: 25000.0
SimplifiedPCDATableParser: Extracted credit via fallback - Basic Pay: 136400.0
SimplifiedPCDATableParser: Extracted credit via fallback - MSP: 15500.0
SimplifiedPCDATableParser: Extracted credit via fallback - Tpt Allc: 4968.0
SimplifiedPCDATableParser: Extracted credit via fallback - DA: 57722.0
SimplifiedPCDATableParser: Extracted debit via fallback - Fur: 40000.0
SimplifiedPCDATableParser: Extracted debit via fallback - Water: 40000.0
SimplifiedPCDATableParser: Successfully extracted 7 items via enhanced fallback
SimplifiedPCDATableParser: Successfully extracted from PCDA table structure
MilitaryFinancialDataExtractor: Simplified PCDA parser successful - earnings: 5, deductions: 2
MilitaryFinancialDataExtractor: Final result - earnings: 5, deductions: 2
[MilitaryPayslipProcessor] PCDA extraction successful - earnings: 5, deductions: 2
[MilitaryPayslipProcessor] Added earning: SPCMD PAY: 25000.0
[MilitaryPayslipProcessor] Added earning: BPAY: 136400.0
[MilitaryPayslipProcessor] Added earning: MSP: 15500.0
[MilitaryPayslipProcessor] Added earning: TPTA: 4968.0
[MilitaryPayslipProcessor] Added earning: DA: 57722.0
[MilitaryPayslipProcessor] Added deduction: FUR: 40000.0
[MilitaryPayslipProcessor] Added deduction: WATER: 40000.0
[MilitaryPayslipProcessor] Set total credits (computed): 239590.0
[MilitaryPayslipProcessor] Set total debits (computed): 80000.0
[MilitaryPayslipProcessor] PCDA processing completed in 0.92s
[MilitaryPayslipProcessor] Extracted date: March 2023
[MilitaryPayslipProcessor] Creating military payslip with credits: 239590.0, debits: 80000.0
[PayslipProcessingStep] Completed in 0.9360589981079102 seconds
[ModularPipeline] Total pipeline execution time: 0.9610519409179688 seconds
[PDFProcessingHandler] processPDFData completed
[PDFProcessingCoordinator] Successfully parsed payslip
[PayslipDataHandler] PDF saved at: /var/mobile/Containers/Data/Application/B66EC707-760C-49C2-BD08-4099DD2D3BB7/Documents/PDFs/D56E5DB6-AD6B-4490-A2AC-1513AE408C54.pdf
[PayslipDataHandler] Successfully verified saved PDF
DataService: Refreshed fetch returned 6 items
PayslipDataHandler: Loaded 6 payslips
HomeViewModel: Data loading completed successfully
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 136400.0
PayslipData: knownEarnings: 136400.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 136400.0
PayslipData: knownEarnings: 136400.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0
NotificationCoordinator: Handling payslips refresh notification
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 136400.0
PayslipData: knownEarnings: 136400.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0
PayslipsViewModel: Loaded 6 payslips and applied sorting with order: dateDescending
DataService: Refreshed fetch returned 6 items
PayslipDataHandler: Loaded 6 payslips
HomeViewModel: Data loading completed successfully
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 136400.0
PayslipData: knownEarnings: 136400.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0