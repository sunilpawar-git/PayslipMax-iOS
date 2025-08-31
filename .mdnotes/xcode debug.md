App is being debugged, do not track this hang
Hang detected: 0.29s (debugger attached, not reporting)
Document picked: file:///private/var/mobile/Containers/Shared/AppGroup/13BEC3B8-94DE-4ABD-BD72-BE0DD9718F6E/File%20Provider%20Storage/Payslips/2023/03%20Mar%202023.pdf
Copying file to: file:///private/var/mobile/Containers/Data/Application/8D80AD2C-E24D-4FF6-9D0C-536472D5ABA0/tmp/E3D0CA01-3D1F-4AF5-99DD-B6E5C30064DD.pdf
Copied file size: 30073 bytes
[PDFProcessingCoordinator] Processing payslip PDF from: file:///private/var/mobile/Containers/Data/Application/8D80AD2C-E24D-4FF6-9D0C-536472D5ABA0/tmp/E3D0CA01-3D1F-4AF5-99DD-B6E5C30064DD.pdf
[PDFProcessingCoordinator] PDF is password protected, showing password entry
[PasswordProtectedPDFHandler] Showing password entry for PDF with 30073 bytes
[PasswordProtectedPDFHandler] Confirmed PDF is locked
[PasswordProtectedPDFHandler] Setting showPasswordEntryView to true
The view service did terminate with error: Error Domain=_UIViewServiceErrorDomain Code=1 "(null)" UserInfo={Terminated=disconnect method}
App is being debugged, do not track this hang
Hang detected: 0.56s (debugger attached, not reporting)
App is being debugged, do not track this hang
Hang detected: 0.25s (debugger attached, not reporting)
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
[PDFTextExtractionService] Memory after page 1/4: 144.5 MB (Δ160 KB)
[PDFTextExtractionService] Memory after page 2/4: 145.7 MB (Δ1.1 MB)
[PDFTextExtractionService] Memory after page 3/4: 146.1 MB (Δ480 KB)
[PDFTextExtractionService] Memory after page 4/4: 146.2 MB (Δ80 KB)
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
[PDFTextExtractionService] Memory after page 1/4: 146.3 MB (Δ16 KB)
[PDFTextExtractionService] Memory after page 2/4: 146.3 MB (ΔZero KB)
[PDFTextExtractionService] Memory after page 3/4: 146.3 MB (ΔZero KB)
[PDFTextExtractionService] Memory after page 4/4: 146.3 MB (Δ16 KB)
[PDFTextExtractionService] Successfully extracted 7321 characters from 4 pages
[PDFTextExtractor] Text extraction completed in 0.01 seconds
[PDFTextExtractor] Extracted 7321 characters
[PayslipFormatDetectionService] Detecting format from 7321 characters of text
[PayslipFormatDetectionService] Detected military format
[PDFProcessingHandler] Detected format: military
[PDFProcessingHandler] Calling pdfProcessingService.processPDFData
[PDFProcessingService] Processing PDF of size: 56103 bytes
[PayslipValidationService] Validating PDF structure
[PayslipValidationService] Is password protected: false
[ValidationStep] Completed in 0.00013494491577148438 seconds
[PDFTextExtractionService] Memory after page 1/4: 146.8 MB (Δ112 KB)
[PDFTextExtractionService] Memory after page 2/4: 146.8 MB (ΔZero KB)
[PDFTextExtractionService] Memory after page 3/4: 146.8 MB (Δ64 KB)
[PDFTextExtractionService] Memory after page 4/4: 146.8 MB (Δ16 KB)
[PDFTextExtractionService] Successfully extracted 7321 characters from 4 pages
[PayslipValidationService] Validating payslip content from 7321 characters
[PayslipValidationService] Payslip validation - valid: true, confidence: 0.6
[TextExtractionStep] Extracted 7321 characters of text
[TextExtractionStep] Completed in 0.023059964179992676 seconds
[PayslipFormatDetectionService] Detecting format from 7321 characters of text
[PayslipFormatDetectionService] Detected military format
[FormatDetectionStep] Detected format: military
[FormatDetectionStep] Completed in 3.0994415283203125e-05 seconds
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
SimplifiedPCDATableParser: Found data line: 03/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) STATEMENT OF ACCOU...
SimplifiedPCDATableParser: Credit clusters found: 1 items
SimplifiedPCDATableParser: Debit clusters found: 2 items
SimplifiedPCDATableParser: Cluster analysis extracted 3 items: [("A/o Pay & Allce", 0.0), ("Fur", 40000.0), ("Water", 40000.0)]
SimplifiedPCDATableParser: Tabulated format extraction successful - found 3 pairs
SimplifiedPCDATableParser: Direct earning match for A/o Pay & Allce
SimplifiedPCDATableParser: Direct deduction match for Fur
SimplifiedPCDATableParser: Direct deduction match for Fur
SimplifiedPCDATableParser: No deduction match for Water
SimplifiedPCDATableParser: No earning match for Water
SimplifiedPCDATableParser: No deduction match for Water
SimplifiedPCDATableParser: Extracted credit via fallback - A/o Pay & Allce: 0.0
SimplifiedPCDATableParser: Extracted debit via fallback - Water: 40000.0
SimplifiedPCDATableParser: Extracted debit via fallback - Fur: 40000.0
SimplifiedPCDATableParser: Successfully extracted 3 items via enhanced fallback
SimplifiedPCDATableParser: Successfully extracted from PCDA table structure
MilitaryFinancialDataExtractor: Simplified PCDA parser successful - earnings: 1, deductions: 2
MilitaryFinancialDataExtractor: Final result - earnings: 1, deductions: 2
[MilitaryPayslipProcessor] PCDA extraction successful - earnings: 1, deductions: 2
[MilitaryPayslipProcessor] Added earning: A/O PAY & ALLCE: 0.0
[MilitaryPayslipProcessor] Added deduction: WATER: 40000.0
[MilitaryPayslipProcessor] Added deduction: FUR: 40000.0
[MilitaryPayslipProcessor] Set total debits (computed): 80000.0
[MilitaryPayslipProcessor] PCDA processing completed in 0.93s
[MilitaryPayslipProcessor] Calculated credits: 136400.0
[MilitaryPayslipProcessor] Extracted date: March 2023
[MilitaryPayslipProcessor] Creating military payslip with credits: 136400.0, debits: 80000.0
[PayslipProcessingStep] Completed in 0.9457560777664185 seconds
[ModularPipeline] Total pipeline execution time: 0.9885278940200806 seconds
[PDFProcessingHandler] processPDFData completed
[PDFProcessingCoordinator] Successfully parsed payslip
[PayslipDataHandler] PDF saved at: /var/mobile/Containers/Data/Application/8D80AD2C-E24D-4FF6-9D0C-536472D5ABA0/Documents/PDFs/9C7ACD36-2479-41FA-AC16-7015D0BB9626.pdf
[PayslipDataHandler] Successfully verified saved PDF
DataService: Refreshed fetch returned 5 items
PayslipDataHandler: Loaded 5 payslips
HomeViewModel: Data loading completed successfully
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
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0
NotificationCoordinator: Handling payslips refresh notification
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 136400.0
PayslipData: knownEarnings: 136400.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0
PayslipsViewModel: Loaded 5 payslips and applied sorting with order: dateDescending
DataService: Refreshed fetch returned 5 items
PayslipDataHandler: Loaded 5 payslips
HomeViewModel: Data loading completed successfully
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 0.0, DA: 0.0, MSP: 136400.0
PayslipData: knownEarnings: 136400.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 4968.0, DA: 25000.0, MSP: 136.0
PayslipData: knownEarnings: 30104.0, miscCredits: 50136.0