App is being debugged, do not track this hang
Hang detected: 0.29s (debugger attached, not reporting)
Document picked: file:///private/var/mobile/Containers/Shared/AppGroup/13BEC3B8-94DE-4ABD-BD72-BE0DD9718F6E/File%20Provider%20Storage/Payslips/2023/02%20Feb%202023.pdf
Copying file to: file:///private/var/mobile/Containers/Data/Application/6A086C43-BC4A-44C2-B1AC-E559E5C57381/tmp/0F5E1172-BC73-4421-B28D-5DAD256B5FB0.pdf
Copied file size: 29888 bytes
[PDFProcessingCoordinator] Processing payslip PDF from: file:///private/var/mobile/Containers/Data/Application/6A086C43-BC4A-44C2-B1AC-E559E5C57381/tmp/0F5E1172-BC73-4421-B28D-5DAD256B5FB0.pdf
[PDFProcessingCoordinator] PDF is password protected, showing password entry
[PasswordProtectedPDFHandler] Showing password entry for PDF with 29888 bytes
[PasswordProtectedPDFHandler] Confirmed PDF is locked
[PasswordProtectedPDFHandler] Setting showPasswordEntryView to true
The view service did terminate with error: Error Domain=_UIViewServiceErrorDomain Code=1 "(null)" UserInfo={Terminated=disconnect method}
App is being debugged, do not track this hang
Hang detected: 0.51s (debugger attached, not reporting)
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
[PDFTextExtractionService] Memory after page 1/4: 141.6 MB (Δ480 KB)
[PDFTextExtractionService] Memory after page 2/4: 142.7 MB (Δ1.1 MB)
[PDFTextExtractionService] Memory after page 3/4: 143 MB (Δ336 KB)
[PDFTextExtractionService] Memory after page 4/4: 143.3 MB (Δ272 KB)
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
[PDFTextExtractionService] Memory after page 1/4: 143.8 MB (Δ64 KB)
[PDFTextExtractionService] Memory after page 2/4: 143.8 MB (Δ32 KB)
[PDFTextExtractionService] Memory after page 3/4: 143.8 MB (ΔZero KB)
[PDFTextExtractionService] Memory after page 4/4: 143.8 MB (Δ16 KB)
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
[ValidationStep] Completed in 0.00014090538024902344 seconds
[PDFTextExtractionService] Memory after page 1/4: 143.9 MB (Δ96 KB)
[PDFTextExtractionService] Memory after page 2/4: 144.1 MB (Δ224 KB)
[PDFTextExtractionService] Memory after page 3/4: 144.2 MB (Δ96 KB)
[PDFTextExtractionService] Memory after page 4/4: 144.3 MB (Δ80 KB)
[PDFTextExtractionService] Successfully extracted 7013 characters from 4 pages
[PayslipValidationService] Validating payslip content from 7013 characters
[PayslipValidationService] Payslip validation - valid: true, confidence: 0.6
[TextExtractionStep] Extracted 7013 characters of text
[TextExtractionStep] Completed in 0.023109912872314453 seconds
[PayslipFormatDetectionService] Detecting format from 7013 characters of text
[PayslipFormatDetectionService] Detected military format
[FormatDetectionStep] Detected format: military
[FormatDetectionStep] Completed in 3.600120544433594e-05 seconds
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
SimplifiedPCDATableParser: Table index issues (start: 3, total: 2), searching for condensed data line
SimplifiedPCDATableParser: Trying enhanced extraction as fallback for irregular pattern
SimplifiedPCDATableParser: Detected Feb 2023 tabulated format with specific sequence
SimplifiedPCDATableParser: Extracted 6 credit items: [("Basic Pay", 136400.0), ("DA", 57722.0), ("MSP", 15500.0), ("Tpt Allc", 4968.0), ("SpCmd Pay", 25000.0), ("A/o Pay & Allce", 125000.0)]
SimplifiedPCDATableParser: Extracted 6 debit items: [("DSOPF Subn", 8184.0), ("AGIF", 10000.0), ("Incm Tax", 89444.0), ("Educ Cess", 4001.0), ("L Fee", 748.0), ("Fur", 326.0)]
SimplifiedPCDATableParser: Tabulated format extraction successful - found 12 pairs
SimplifiedPCDATableParser: Direct earning match for Basic Pay
SimplifiedPCDATableParser: Direct earning match for DA
SimplifiedPCDATableParser: Direct earning match for MSP
SimplifiedPCDATableParser: Direct earning match for Tpt Allc
SimplifiedPCDATableParser: Direct earning match for SpCmd Pay
SimplifiedPCDATableParser: Direct earning match for A/o Pay & Allce
SimplifiedPCDATableParser: Direct deduction match for DSOPF Subn
SimplifiedPCDATableParser: Direct deduction match for DSOPF Subn
SimplifiedPCDATableParser: Direct deduction match for AGIF
SimplifiedPCDATableParser: Direct deduction match for AGIF
SimplifiedPCDATableParser: Direct deduction match for Incm Tax
SimplifiedPCDATableParser: Direct deduction match for Incm Tax
SimplifiedPCDATableParser: Direct deduction match for Educ Cess
SimplifiedPCDATableParser: Direct deduction match for Educ Cess
SimplifiedPCDATableParser: Direct deduction match for L Fee
SimplifiedPCDATableParser: Direct deduction match for L Fee
SimplifiedPCDATableParser: Direct deduction match for Fur
SimplifiedPCDATableParser: Direct deduction match for Fur
SimplifiedPCDATableParser: Extracted credit via fallback - MSP: 15500.0
SimplifiedPCDATableParser: Extracted credit via fallback - SpCmd Pay: 25000.0
SimplifiedPCDATableParser: Extracted credit via fallback - DA: 57722.0
SimplifiedPCDATableParser: Extracted credit via fallback - Basic Pay: 136400.0
SimplifiedPCDATableParser: Extracted credit via fallback - Tpt Allc: 4968.0
SimplifiedPCDATableParser: Extracted credit via fallback - A/o Pay & Allce: 125000.0
SimplifiedPCDATableParser: Extracted debit via fallback - Educ Cess: 4001.0
SimplifiedPCDATableParser: Extracted debit via fallback - Fur: 326.0
SimplifiedPCDATableParser: Extracted debit via fallback - AGIF: 10000.0
SimplifiedPCDATableParser: Extracted debit via fallback - DSOPF Subn: 8184.0
SimplifiedPCDATableParser: Extracted debit via fallback - Incm Tax: 89444.0
SimplifiedPCDATableParser: Extracted debit via fallback - L Fee: 748.0
SimplifiedPCDATableParser: Successfully extracted 12 items via enhanced fallback
SimplifiedPCDATableParser: Successfully extracted from PCDA table structure
MilitaryFinancialDataExtractor: Simplified PCDA parser successful - earnings: 6, deductions: 6
MilitaryFinancialDataExtractor: Final result - earnings: 6, deductions: 6
[MilitaryPayslipProcessor] PCDA extraction successful - earnings: 6, deductions: 6
[MilitaryPayslipProcessor] Added earning: MSP: 15500.0
[MilitaryPayslipProcessor] Added earning: SPCMD PAY: 25000.0
[MilitaryPayslipProcessor] Added earning: DA: 57722.0
[MilitaryPayslipProcessor] Added earning: TPTA: 4968.0
[MilitaryPayslipProcessor] Added earning: BPAY: 136400.0
[MilitaryPayslipProcessor] Added earning: A/O PAY & ALLCE: 125000.0
[MilitaryPayslipProcessor] Added deduction: EHCESS: 4001.0
[MilitaryPayslipProcessor] Added deduction: L FEE: 748.0
[MilitaryPayslipProcessor] Added deduction: AGIF: 10000.0
[MilitaryPayslipProcessor] Added deduction: DSOP: 8184.0
[MilitaryPayslipProcessor] Added deduction: ITAX: 89444.0
[MilitaryPayslipProcessor] Added deduction: FUR: 326.0
[MilitaryPayslipProcessor] Set total credits (computed): 364590.0
[MilitaryPayslipProcessor] Set total debits (computed): 112703.0
[MilitaryPayslipProcessor] PCDA processing completed in 0.79s
[MilitaryPayslipProcessor] Extracted date: February 2023
[MilitaryPayslipProcessor] Creating military payslip with credits: 364590.0, debits: 112703.0
[PayslipProcessingStep] Completed in 0.7959901094436646 seconds
[ModularPipeline] Total pipeline execution time: 0.8201199769973755 seconds
[PDFProcessingHandler] processPDFData completed
[PDFProcessingCoordinator] Successfully parsed payslip
CoreData: debug: PostSaveMaintenance: incremental_vacuum with freelist_count - 13 and pages_to_free 2
[PayslipDataHandler] PDF saved at: /var/mobile/Containers/Data/Application/6A086C43-BC4A-44C2-B1AC-E559E5C57381/Documents/PDFs/5BE12356-E834-4C80-8A27-0641E0B47F3A.pdf
[PayslipDataHandler] Successfully verified saved PDF
DataService: Refreshed fetch returned 3 items
PayslipDataHandler: Loaded 3 payslips
HomeViewModel: Data loading completed successfully
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 154968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 154968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: -136400.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: -136400.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 0.0, miscCredits: 2895445.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 0.0, miscCredits: 2895445.0
NotificationCoordinator: Handling payslips refresh notification
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 154968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: -136400.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 0.0, miscCredits: 2895445.0
PayslipsViewModel: Loaded 3 payslips and applied sorting with order: dateDescending
DataService: Refreshed fetch returned 3 items
PayslipDataHandler: Loaded 3 payslips
HomeViewModel: Data loading completed successfully
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 154968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: -136400.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 0.0
PayslipData: knownEarnings: 0.0, miscCredits: 2895445.0