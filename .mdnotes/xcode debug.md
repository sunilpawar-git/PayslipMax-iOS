-[RTIInputSystemClient remoteTextInputSessionWithID:performInputOperation:]  perform input operation requires a valid sessionID. inputModality = Keyboard, inputOperation = <null selector>, customInfoType = UIEmojiSearchOperations
-[RTIInputSystemClient remoteTextInputSessionWithID:performInputOperation:]  perform input operation requires a valid sessionID. inputModality = Keyboard, inputOperation = <null selector>, customInfoType = UIEmojiSearchOperations
-[RTIInputSystemClient remoteTextInputSessionWithID:performInputOperation:]  perform input operation requires a valid sessionID. inputModality = Keyboard, inputOperation = <null selector>, customInfoType = UIEmojiSearchOperations
-[RTIInputSystemClient remoteTextInputSessionWithID:performInputOperation:]  perform input operation requires a valid sessionID. inputModality = Keyboard, inputOperation = <null selector>, customInfoType = UIEmojiSearchOperations
Document picked: file:///private/var/mobile/Containers/Shared/AppGroup/13BEC3B8-94DE-4ABD-BD72-BE0DD9718F6E/File%20Provider%20Storage/Payslips/2023/02%20Feb%202023.pdf
Copying file to: file:///private/var/mobile/Containers/Data/Application/D67F51C5-D8BE-47B6-BC09-C70D1CFAD5DA/tmp/9E74A076-560B-474B-9340-5459A3D60504.pdf
Copied file size: 29888 bytes
[PDFProcessingCoordinator] Processing payslip PDF from: file:///private/var/mobile/Containers/Data/Application/D67F51C5-D8BE-47B6-BC09-C70D1CFAD5DA/tmp/9E74A076-560B-474B-9340-5459A3D60504.pdf
[PDFProcessingCoordinator] PDF is password protected, showing password entry
[PasswordProtectedPDFHandler] Showing password entry for PDF with 29888 bytes
[PasswordProtectedPDFHandler] Confirmed PDF is locked
[PasswordProtectedPDFHandler] Setting showPasswordEntryView to true
The view service did terminate with error: Error Domain=_UIViewServiceErrorDomain Code=1 "(null)" UserInfo={Terminated=disconnect method}
-[RTIInputSystemClient remoteTextInputSessionWithID:performInputOperation:]  perform input operation requires a valid sessionID. inputModality = Keyboard, inputOperation = <null selector>, customInfoType = UIEmojiSearchOperations
PasswordProtectedPDFView: Attempting to unlock PDF with password: 5***
PDFService: PDF unlocked successfully
PDFService: Military PDF detected
PDFService: PCDA PDF detected
PDFService: Using special military PDF handling
PDFService: Standard unlocking worked for military PDF
[PDFProcessingCoordinator] Handling unlocked PDF with 55817 bytes
[PayslipValidationService] Is password protected: false
[PDFProcessingHandler] PDF is password protected: false
[PDFProcessingHandler] PDF document is locked: false
[PDFTextExtractor] Starting memory-efficient text extraction for document with 4 pages
[PDFTextExtractionService] Memory after page 1/4: 168.7 MB (Δ336 KB)
[PDFTextExtractionService] Memory after page 2/4: 169.5 MB (Δ848 KB)
[PDFTextExtractionService] Memory after page 3/4: 169.6 MB (Δ112 KB)
[PDFTextExtractionService] Memory after page 4/4: 169.9 MB (Δ288 KB)
[PDFTextExtractionService] Successfully extracted 7013 characters from 4 pages
[PDFTextExtractor] Text extraction completed in 0.02 seconds
[PDFTextExtractor] Extracted 7013 characters
[PayslipFormatDetectionService] Detecting format from 7013 characters of text
[PayslipFormatDetectionService] Detected military format
[PDFProcessingCoordinator] Detected format: military
[PDFProcessingCoordinator] PDF document created successfully with 4 pages
[PDFProcessingCoordinator] Processing PDF data with 55817 bytes
[PDFProcessingHandler] Process PDF Data started with 55817 bytes
[PDFProcessingHandler] Valid PDF document created with 4 pages
[PayslipValidationService] Is password protected: false
[PDFProcessingHandler] PDF is password protected: false
[PDFProcessingHandler] PDF document is locked: false
[PDFTextExtractor] Starting memory-efficient text extraction for document with 4 pages
[PDFTextExtractionService] Memory after page 1/4: 169.9 MB (ΔZero KB)
[PDFTextExtractionService] Memory after page 2/4: 169.9 MB (ΔZero KB)
[PDFTextExtractionService] Memory after page 3/4: 169.9 MB (Δ16 KB)
[PDFTextExtractionService] Memory after page 4/4: 170 MB (Δ64 KB)
[PDFTextExtractionService] Successfully extracted 7013 characters from 4 pages
[PDFTextExtractor] Text extraction completed in 0.02 seconds
[PDFTextExtractor] Extracted 7013 characters
[PayslipFormatDetectionService] Detecting format from 7013 characters of text
[PayslipFormatDetectionService] Detected military format
[PDFProcessingHandler] Detected format: military
[PDFProcessingHandler] Calling pdfProcessingService.processPDFData
[PDFProcessingService] Processing PDF of size: 55817 bytes
[PayslipValidationService] Validating PDF structure
[PayslipValidationService] Is password protected: false
[ValidationStep] Completed in 0.0002110004425048828 seconds
[PDFTextExtractionService] Memory after page 1/4: 170.2 MB (Δ160 KB)
[PDFTextExtractionService] Memory after page 2/4: 170.2 MB (Δ16 KB)
[PDFTextExtractionService] Memory after page 3/4: 170.2 MB (Δ48 KB)
[PDFTextExtractionService] Memory after page 4/4: 170.2 MB (Δ16 KB)
[PDFTextExtractionService] Successfully extracted 7013 characters from 4 pages
[PayslipValidationService] Validating payslip content from 7013 characters
[PayslipValidationService] Payslip validation - valid: true, confidence: 0.6
[TextExtractionStep] Extracted 7013 characters of text
[TextExtractionStep] Completed in 0.025240063667297363 seconds
[PayslipFormatDetectionService] Detecting format from 7013 characters of text
[PayslipFormatDetectionService] Detected military format
[FormatDetectionStep] Detected format: military
[FormatDetectionStep] Completed in 3.0994415283203125e-05 seconds
[MilitaryPayslipProcessor] Processing military payslip from 7013 characters
[MilitaryPayslipProcessor] Extracted ITAX: 364590.0
[MilitaryPayslipProcessor] Attempting Phase 6.3 tabular data extraction
[MilitaryPayslipProcessor] PCDA marker detected: PCDA
[LiteRTService] Initializing LiteRT service
[MilitaryPayslipProcessor] PCDA format detected - routing to enhanced spatial parsing pipeline
[MilitaryPayslipProcessor] Creating synthetic text elements from parsed text
[MilitaryPayslipProcessor] Created 1112 synthetic text elements for spatial analysis
MilitaryFinancialDataExtractor: Starting Phase 6.3 spatial table analysis with 1112 text elements
MilitaryFinancialDataExtractor: PCDA table structure detected with 181 data rows
MilitaryFinancialDataExtractor: Created PCDA spatial table with 0 data rows
MilitaryFinancialDataExtractor: Processed PCDA rows - credits: 0, debits: 0
PCDAFinancialValidator: Starting validation - credits: 0, debits: 0
MilitaryFinancialDataExtractor: PCDA validation FAILED: No financial data extracted
MilitaryFinancialDataExtractor: All spatial methods failed, using fallback text-based extraction
MilitaryFinancialDataExtractor: Starting tabular data extraction from 7013 characters
MilitaryFinancialDataExtractor: Detected PCDA format for tabular data extraction
MilitaryFinancialDataExtractor: Trying simplified PCDA parser
SimplifiedPCDATableParser: Processing text-based PCDA format
SimplifiedPCDATableParser: Starting enhanced PCDA pattern extraction
SimplifiedPCDATableParser: Attempting PCDA table structure extraction
SimplifiedPCDATableParser: Single massive line detected, trying alternative splitting
SimplifiedPCDATableParser: Analyzing PDF text structure - Total lines: 2
SimplifiedPCDATableParser: First 10 lines:
Line 0: '02/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640-...'
Line 1: 'Basic Pay DA MSP Tpt Allc SpCmd Pay A/o Pay & Allce 136400 57722 15500 4968 25000 125000 DSOPF Subn ...'
SimplifiedPCDATableParser: Found PCDA credit/debit header at line 0: 02/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / CREDIT / DEBIT / DETAILS OF TRANSACTIONS
SimplifiedPCDATableParser: Table index issues (start: \(tableDataStartIndex), total: \(lines.count)), searching for condensed data line
SimplifiedPCDATableParser: Found condensed format line: '\(condensedLine.prefix(200))...'
SimplifiedPCDATableParser: Trying condensed format parsing for: 'Basic Pay DA MSP Tpt Allc SpCmd Pay A/o Pay & Allce 136400 57722 15500 4968 25000 125000 DSOPF Subn AGIF Incm Tax Educ Cess L Fee Fur 8184 10000 89444 4001 748 326 Cr PARA-SC Dt. 01/09/2022 to 31/01/2023 Amt : 125000 RL//3/ P-0 Dt: 05/02/2021 Bldg : 159/2.Ne Dr L fee Dt : 01/02/2023 to 28/02/2023 748 Dr. fur Dt : 01/02/2023 to 28/02/2023 326 Part II Orders adjusted in this month Pt II Order No : 0287/2022 Dated : 23/12/2022 Pt II Order No : 0289/2022 Dated : 23/12/2022'
SimplifiedPCDATableParser: Split into 92 tokens: ["Basic", "Pay", "DA", "MSP", "Tpt", "Allc", "SpCmd", "Pay", "A/o", "Pay", "&", "Allce", "136400", "57722", "15500", "4968", "25000", "125000", "DSOPF", "Subn", "AGIF", "Incm", "Tax", "Educ", "Cess", "L", "Fee", "Fur", "8184", "10000", "89444", "4001", "748", "326", "Cr", "PARA-SC", "Dt.", "01/09/2022", "to", "31/01/2023", "Amt", ":", "125000", "RL//3/", "P-0", "Dt:", "05/02/2021", "Bldg", ":", "159/2.Ne", "Dr", "L", "fee", "Dt", ":", "01/02/2023", "to", "28/02/2023", "748", "Dr.", "fur", "Dt", ":", "01/02/2023", "to", "28/02/2023", "326", "Part", "II", "Orders", "adjusted", "in", "this", "month", "Pt", "II", "Order", "No", ":", "0287/2022", "Dated", ":", "23/12/2022", "Pt", "II", "Order", "No", ":", "0289/2022", "Dated", ":", "23/12/2022"]
SimplifiedPCDATableParser: Token 0 'Basic' is not a valid amount > 100
SimplifiedPCDATableParser: Token 1 'Pay' is not a valid amount > 100
SimplifiedPCDATableParser: Token 2 'DA' is not a valid amount > 100
SimplifiedPCDATableParser: Token 3 'MSP' is not a valid amount > 100
SimplifiedPCDATableParser: Token 4 'Tpt' is not a valid amount > 100
SimplifiedPCDATableParser: Token 5 'Allc' is not a valid amount > 100
SimplifiedPCDATableParser: Token 6 'SpCmd' is not a valid amount > 100
SimplifiedPCDATableParser: Token 7 'Pay' is not a valid amount > 100
SimplifiedPCDATableParser: Token 8 'A/o' is not a valid amount > 100
SimplifiedPCDATableParser: Token 9 'Pay' is not a valid amount > 100
SimplifiedPCDATableParser: Token 10 '&' is not a valid amount > 100
SimplifiedPCDATableParser: Token 11 'Allce' is not a valid amount > 100
SimplifiedPCDATableParser: Found first amount at index 12: 136400.0
SimplifiedPCDATableParser: Found 12 descriptions and 80 amounts
SimplifiedPCDATableParser: Descriptions: ["Basic", "Pay", "DA", "MSP", "Tpt", "Allc", "SpCmd", "Pay", "A/o", "Pay", "&", "Allce"]
SimplifiedPCDATableParser: Amounts: ["136400", "57722", "15500", "4968", "25000", "125000", "DSOPF", "Subn", "AGIF", "Incm", "Tax", "Educ", "Cess", "L", "Fee", "Fur", "8184", "10000", "89444", "4001", "748", "326", "Cr", "PARA-SC", "Dt.", "01/09/2022", "to", "31/01/2023", "Amt", ":", "125000", "RL//3/", "P-0", "Dt:", "05/02/2021", "Bldg", ":", "159/2.Ne", "Dr", "L", "fee", "Dt", ":", "01/02/2023", "to", "28/02/2023", "748", "Dr.", "fur", "Dt", ":", "01/02/2023", "to", "28/02/2023", "326", "Part", "II", "Orders", "adjusted", "in", "this", "month", "Pt", "II", "Order", "No", ":", "0287/2022", "Dated", ":", "23/12/2022", "Pt", "II", "Order", "No", ":", "0289/2022", "Dated", ":", "23/12/2022"]
SimplifiedPCDATableParser: Analyzing token structure for credit/debit separation
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found amount at global index \(firstAmountIndex + index): \(amount)
SimplifiedPCDATableParser: Found \(amountTokens.count) valid amounts: \(amountTokens.map { $0.value })
SimplifiedPCDATableParser: Credit amount \(i + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Credit amount \(i + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Credit amount \(i + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Credit amount \(i + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Credit amount \(i + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Credit amount \(i + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Gap found at index \(currentGlobalIndex), expected \(expectedIndex)
SimplifiedPCDATableParser: Debit amount \(i - creditAmounts.count + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Debit amount \(i - creditAmounts.count + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Debit amount \(i - creditAmounts.count + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Debit amount \(i - creditAmounts.count + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Debit amount \(i - creditAmounts.count + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Debit amount \(i - creditAmounts.count + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Debit amount \(i - creditAmounts.count + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Debit amount \(i - creditAmounts.count + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Debit amount \(i - creditAmounts.count + 1): \(amountTokens[i].value)
SimplifiedPCDATableParser: Extracted \(creditAmounts.count) credit amounts, \(debitAmounts.count) debit amounts
SimplifiedPCDATableParser: Extracted \(debitDescriptions.count) debit descriptions: \(debitDescriptions)
SimplifiedPCDATableParser: Paired credit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired credit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired credit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired credit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired credit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired credit - \(desc): \(amount)
SimplifiedPCDATableParser: Combined credit description - \(combinedDesc): \(creditAmounts[i])
SimplifiedPCDATableParser: Combined credit description - \(combinedDesc): \(creditAmounts[i])
SimplifiedPCDATableParser: Combined credit description - \(combinedDesc): \(creditAmounts[i])
SimplifiedPCDATableParser: Combined credit description - \(combinedDesc): \(creditAmounts[i])
SimplifiedPCDATableParser: Combined credit description - \(combinedDesc): \(creditAmounts[i])
SimplifiedPCDATableParser: Combined credit description - \(combinedDesc): \(creditAmounts[i])
SimplifiedPCDATableParser: Paired debit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired debit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired debit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired debit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired debit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired debit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired debit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired debit - \(desc): \(amount)
SimplifiedPCDATableParser: Paired debit - \(desc): \(amount)
SimplifiedPCDATableParser: Combined debit description - \(combinedDesc): \(debitAmounts[i])
SimplifiedPCDATableParser: Combined debit description - \(combinedDesc): \(debitAmounts[i])
SimplifiedPCDATableParser: Combined debit description - \(combinedDesc): \(debitAmounts[i])
SimplifiedPCDATableParser: Combined debit description - \(combinedDesc): \(debitAmounts[i])
SimplifiedPCDATableParser: Combined debit description - \(combinedDesc): \(debitAmounts[i])
SimplifiedPCDATableParser: Combined debit description - \(combinedDesc): \(debitAmounts[i])
SimplifiedPCDATableParser: Combined debit description - \(combinedDesc): \(debitAmounts[i])
SimplifiedPCDATableParser: Combined debit description - \(combinedDesc): \(debitAmounts[i])
SimplifiedPCDATableParser: Combined debit description - \(combinedDesc): \(debitAmounts[i])
SimplifiedPCDATableParser: Final result - \(credits.count) credits, \(debits.count) debits
SimplifiedPCDATableParser: Extracted credit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted credit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted credit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted credit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted credit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted credit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted debit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted debit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted debit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted debit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted debit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted debit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted debit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted debit - \(desc): \(amt)
SimplifiedPCDATableParser: Extracted debit - \(desc): \(amt)
SimplifiedPCDATableParser: Successfully extracted \(totalExtracted) items via condensed format detection
SimplifiedPCDATableParser: Successfully extracted from PCDA table structure
MilitaryFinancialDataExtractor: Simplified PCDA parser successful - earnings: 6, deductions: 9
MilitaryFinancialDataExtractor: Final result - earnings: 6, deductions: 9
[MilitaryPayslipProcessor] PCDA extraction successful - earnings: 6, deductions: 9
[MilitaryPayslipProcessor] Added earning: A/O PAY: 25000.0
[MilitaryPayslipProcessor] Added earning: TPTA: 15500.0
[MilitaryPayslipProcessor] Added earning: SPCMD PAY: 4968.0
[MilitaryPayslipProcessor] Added earning: & ALLCE: 125000.0
[MilitaryPayslipProcessor] Added earning: DA MSP: 57722.0
[MilitaryPayslipProcessor] Added earning: BPAY: 136400.0
[MilitaryPayslipProcessor] Added deduction: AGIF: 89444.0
[MilitaryPayslipProcessor] Added deduction: SUBN: 10000.0
[MilitaryPayslipProcessor] Added deduction: DSOPF: 8184.0
[MilitaryPayslipProcessor] Added deduction: FEE: 326.0
[MilitaryPayslipProcessor] Added deduction: CESS: 125000.0
[MilitaryPayslipProcessor] Added deduction: L: 748.0
[MilitaryPayslipProcessor] Added deduction: INCM: 4001.0
[MilitaryPayslipProcessor] Added deduction: EDUC: 326.0
[MilitaryPayslipProcessor] Added deduction: TAX: 748.0
[MilitaryPayslipProcessor] Set total credits (computed): 364590.0
[MilitaryPayslipProcessor] Set total debits (computed): 238777.0
[MilitaryPayslipProcessor] PCDA processing completed in 0.85s
[MilitaryPayslipProcessor] Extracted date: February 2023
[MilitaryPayslipProcessor] Creating military payslip with credits: 364590.0, debits: 238777.0
[PayslipProcessingStep] Completed in 0.8487989902496338 seconds
[ModularPipeline] Total pipeline execution time: 0.8814040422439575 seconds
[PDFProcessingHandler] processPDFData completed
[PDFProcessingCoordinator] Successfully parsed payslip
[PayslipDataHandler] PDF saved at: /var/mobile/Containers/Data/Application/D67F51C5-D8BE-47B6-BC09-C70D1CFAD5DA/Documents/PDFs/D6A35861-8BC2-454C-BC38-09D43B753C18.pdf
[PayslipDataHandler] Successfully verified saved PDF
DataService: Refreshed fetch returned 4 items
PayslipDataHandler: Loaded 4 payslips
HomeViewModel: Data loading completed successfully
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 136400.0, miscCredits: 228190.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 136400.0, miscCredits: 228190.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 136400.0, miscCredits: 228190.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 136400.0, miscCredits: 228190.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 0.0, miscCredits: 2895445.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 0.0, miscCredits: 2895445.0
NotificationCoordinator: Handling payslips refresh notification
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 0.0, miscCredits: 2895445.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 136400.0, miscCredits: 228190.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 136400.0, miscCredits: 228190.0
PayslipsViewModel: Loaded 4 payslips and applied sorting with order: dateDescending
DataService: Refreshed fetch returned 4 items
PayslipDataHandler: Loaded 4 payslips
HomeViewModel: Data loading completed successfully
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 0.0, miscCredits: 2895445.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 136400.0, miscCredits: 228190.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 136400.0, miscCredits: 228190.0