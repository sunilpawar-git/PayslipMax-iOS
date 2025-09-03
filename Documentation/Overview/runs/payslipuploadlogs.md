App is being debugged, do not track this hang
Hang detected: 0.25s (debugger attached, not reporting)
Document picked: file:///private/var/mobile/Containers/Shared/AppGroup/13BEC3B8-94DE-4ABD-BD72-BE0DD9718F6E/File%20Provider%20Storage/Payslips/2023/02%20Feb%202023.pdf
Copying file to: file:///private/var/mobile/Containers/Data/Application/748222B2-F953-448C-8F56-A1D6C0BCCC70/tmp/92B293D0-AE81-4174-809A-1E5AAEC4433A.pdf
Copied file size: 29888 bytes
[PDFProcessingCoordinator] Processing payslip PDF from: file:///private/var/mobile/Containers/Data/Application/748222B2-F953-448C-8F56-A1D6C0BCCC70/tmp/92B293D0-AE81-4174-809A-1E5AAEC4433A.pdf
[PDFProcessingCoordinator] PDF is password protected, showing password entry
[PasswordProtectedPDFHandler] Showing password entry for PDF with 29888 bytes
[PasswordProtectedPDFHandler] Confirmed PDF is locked
[PasswordProtectedPDFHandler] Setting showPasswordEntryView to true
The view service did terminate with error: Error Domain=_UIViewServiceErrorDomain Code=1 "(null)" UserInfo={Terminated=disconnect method}
App is being debugged, do not track this hang
Hang detected: 0.40s (debugger attached, not reporting)
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
[PDFTextExtractionService] Using AI-enhanced extraction for page 1
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=218.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), languages=en-US, recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=982 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=965.4 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US, imageSize=(2382.0, 3367.0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,249.9 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 47 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,250.6 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,529.9 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 47 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 640 characters
[PDFTextExtractionService] Text quality analysis: readable=1.00, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 1/4: 1,530.2 MB (Δ1,381.8 MB)
[PDFMemoryTracker] ⚠️ Significant memory increase: 1,381.8 MB
[PDFTextExtractionService] Using AI-enhanced extraction for page 2
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,224.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), imageSize=(2382.0, 3367.0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,547 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,547 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,396.8 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 48 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,396.8 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), imageSize=(2382.0, 3367.0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,475.2 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 48 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 2295 characters
[PDFTextExtractionService] Text quality analysis: readable=1.00, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 2/4: 1,475.2 MB (ΔZero KB)
[PDFTextExtractionService] Using AI-enhanced extraction for page 3
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,167 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,645.3 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,645.3 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US, imageSize=(2382.0, 3367.0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,734.5 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 69 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,734.7 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), imageSize=(2382.0, 3367.0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,910.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 69 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 1091 characters
[PDFTextExtractionService] Text quality analysis: readable=0.99, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 3/4: 1,910.2 MB (Δ435 MB)
[PDFMemoryTracker] ⚠️ Significant memory increase: 435 MB
[PDFTextExtractionService] Using AI-enhanced extraction for page 4
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,584.8 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), imageSize=(2382.0, 3367.0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,946.7 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,946.7 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,965.9 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 45 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,965.9 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), imageSize=(2382.0, 3367.0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,067.2 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 45 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 553 characters
[PDFTextExtractionService] Text quality analysis: readable=1.00, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 4/4: 2,067.4 MB (Δ157.2 MB)
[PDFMemoryTracker] ⚠️ Significant memory increase: 157.2 MB
[PDFTextExtractionService] Successfully extracted 7013 characters from 4 pages
[PDFTextExtractor] Text extraction completed in 19.24 seconds
[PDFTextExtractor] Extracted 7013 characters
[PayslipFormatDetectionService] Detecting format from 7013 characters of text
[PayslipFormatDetectionService] Detected military format
[PDFProcessingCoordinator] Detected format: military
[PDFProcessingCoordinator] PDF document created successfully with 4 pages
App is being debugged, do not track this hang
Hang detected: 19.41s (debugger attached, not reporting)
[PDFProcessingCoordinator] Processing PDF data with 55817 bytes
[PDFProcessingHandler] Process PDF Data started with 55817 bytes
[PDFProcessingHandler] Valid PDF document created with 4 pages
[PayslipValidationService] Is password protected: false
[PDFProcessingHandler] PDF is password protected: false
[PDFProcessingHandler] PDF document is locked: false
[PDFTextExtractor] Starting memory-efficient text extraction for document with 4 pages
[PDFTextExtractionService] Using AI-enhanced extraction for page 1
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,762.8 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,940.5 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,940.5 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,935.5 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 47 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,935.5 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), languages=en-US, recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,986.2 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 47 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 640 characters
[PDFTextExtractionService] Text quality analysis: readable=1.00, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 1/4: 1,986.3 MB (Δ231.4 MB)
[PDFMemoryTracker] ⚠️ Significant memory increase: 231.4 MB
[PDFTextExtractionService] Using AI-enhanced extraction for page 2
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,661 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), languages=en-US, recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,966.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,966.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,020.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 48 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=2,020.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US, imageSize=(2382.0, 3367.0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,000.5 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 48 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 2295 characters
[PDFTextExtractionService] Text quality analysis: readable=1.00, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 2/4: 2,000.5 MB (Δ14.2 MB)
[PDFMemoryTracker] ⚠️ Significant memory increase: 14.2 MB
[PDFTextExtractionService] Using AI-enhanced extraction for page 3
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,675.3 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,015.9 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=2,015.9 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,043.3 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 69 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=2,043.3 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,045 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 69 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 1091 characters
[PDFTextExtractionService] Text quality analysis: readable=0.99, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 3/4: 2,045.1 MB (Δ44.5 MB)
[PDFMemoryTracker] ⚠️ Significant memory increase: 44.5 MB
[PDFTextExtractionService] Using AI-enhanced extraction for page 4
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,719.6 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,991.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,991.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US, imageSize=(2382.0, 3367.0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,040.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 45 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=2,040.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,056.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 45 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 553 characters
[PDFTextExtractionService] Text quality analysis: readable=1.00, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 4/4: 2,056.2 MB (Δ11.1 MB)
[PDFMemoryTracker] ⚠️ Significant memory increase: 11.1 MB
[PDFTextExtractionService] Successfully extracted 7013 characters from 4 pages
[PDFTextExtractor] Text extraction completed in 17.27 seconds
[PDFTextExtractor] Extracted 7013 characters
[PayslipFormatDetectionService] Detecting format from 7013 characters of text
[PayslipFormatDetectionService] Detected military format
[PDFProcessingHandler] Detected format: military
[PDFProcessingHandler] Calling pdfProcessingService.processPDFData
[PDFProcessingService] Processing PDF of size: 55817 bytes
[PayslipValidationService] Validating PDF structure
[PayslipValidationService] Is password protected: false
[ValidationStep] Completed in 0.000867009162902832 seconds
App is being debugged, do not track this hang
Hang detected: 17.49s (debugger attached, not reporting)
[PDFTextExtractionService] Using AI-enhanced extraction for page 1
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,737.5 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,860.2 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,860.2 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,824.5 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 47 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,824.5 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,806.2 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 47 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 640 characters
[PDFTextExtractionService] Text quality analysis: readable=1.00, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 1/4: 1,806.2 MB (Δ75.3 MB)
[PDFTextExtractionService] Using AI-enhanced extraction for page 2
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,480.9 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,805.7 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,805.7 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,821.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 48 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,821.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), imageSize=(2382.0, 3367.0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,817.3 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 48 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 2295 characters
[PDFTextExtractionService] Text quality analysis: readable=1.00, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 2/4: 1,817.3 MB (Δ11.1 MB)
[PDFTextExtractionService] Using AI-enhanced extraction for page 3
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,491.9 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,804.8 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,804.8 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,968 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 69 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,968 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,034.1 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 69 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 1091 characters
[PDFTextExtractionService] Text quality analysis: readable=0.99, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 3/4: 2,034.2 MB (Δ216.9 MB)
[PDFTextExtractionService] Using AI-enhanced extraction for page 4
[PDFTextExtractionService] Rendered page at 2381.76x3366.72 for enhanced OCR
[EnhancedVisionTextExtractor] Using enhanced extraction with LiteRT preprocessing
[TableStructureDetector] Starting table structure detection with ML: true
[TableStructureDetector] Using heuristic table detection
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,708.7 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US, imageSize=(2382.0, 3367.0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=1,977.8 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=1,977.8 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0), languages=en-US] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,024.3 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[TableStructureDetector] Found 0 bilingual headers
[TableStructureDetector] Detected 3 columns
[TableStructureDetector] Detected 1 rows
[TableStructureDetector] Mapped 45 cells
[TableStructureDetector] Heuristic table structure detected with confidence: 0.75
🔍 [DEBUG] [OCR] 🔧 OCR: Started: Vision text extraction from image  - OCRLogger.swift:75 in logOperation(_:level:details:)
ℹ️ [INFO] [OCR] ⚡ Performance: Vision text extraction from image [duration=0.000s] - OCRLogger.swift:49 in logPerformance(_:duration:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction start [memory=2,024.3 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
ℹ️ [INFO] [OCR] 🔍 Vision: Starting image text extraction [languages=en-US, imageSize=(2382.0, 3367.0), recognitionLevel=VNRequestTextRecognitionLevel(rawValue: 0)] - OCRLogger.swift:23 in logVisionOperation(_:details:)
ℹ️ [INFO] [OCR] 💾 Memory: Vision extraction complete [memory=2,113.8 MB] - OCRLogger.swift:57 in logMemoryUsage(_:memoryUsage:details:)
[PDFTextExtractionService] Converting 45 text elements to structured text
[PDFTextExtractionService] Organized into 1 rows
[PDFTextExtractionService] Generated structured text: 553 characters
[PDFTextExtractionService] Text quality analysis: readable=1.00, cyrillic=true, control=false, financial=true
[PDFTextExtractionService] ⚠️ AI extraction produced poor quality text, falling back to PDFKit
[PDFTextExtractionService] Memory after page 4/4: 2,113.9 MB (Δ79.7 MB)
[PDFTextExtractionService] Successfully extracted 7013 characters from 4 pages
[PayslipValidationService] Validating payslip content from 7013 characters
[PayslipValidationService] DEBUG - First 200 characters: 02/2023 STATEMENT OF ACCOUNT FOR 02/2023
CONTACT Tel Nos in PCDA(O), Pune :
PRO CIVIL : ((020) 2640- 1111/1333/1353/1356)
PRO ARMY : (6512/6528/7756/7761/7762/7763)
NAME : SUNIL SURESH PAWAR
: 16/110/
[PayslipValidationService] ❌ Name field not found
[PayslipValidationService] ✅ Month field detected with pattern: Nov\s+20[0-9]{2}
[PayslipValidationService] ✅ Year field detected with pattern: 20[0-9]{2}
[PayslipValidationService] ✅ Earnings field detected with term: Salary
[PayslipValidationService] ✅ Deductions field detected with term: Deductions
[PayslipValidationService] Detected fields: ["month", "year", "earnings", "deductions"]
[PayslipValidationService] Missing fields: ["name"]
[PayslipValidationService] Payslip validation - valid: true, confidence: 0.8
[TextExtractionStep] Extracted 7013 characters of text
[TextExtractionStep] Completed in 17.622005105018616 seconds
[PayslipFormatDetectionService] Detecting format from 7013 characters of text
[PayslipFormatDetectionService] Detected military format
[FormatDetectionStep] Detected format: military
[FormatDetectionStep] Completed in 4.100799560546875e-05 seconds
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
SimplifiedPCDATableParser: Starting cluster-based analysis
SimplifiedPCDATableParser: Searching through 1 lines for financial data
SimplifiedPCDATableParser: Line 0: hasFinancialCodes=true, hasAmounts=true, length=7013
SimplifiedPCDATableParser: Line 0 content: '02/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/...'
SimplifiedPCDATableParser: ✅ Selected line 0 as main data line
SimplifiedPCDATableParser: Found data line: 02/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7...
SimplifiedPCDATableParser: Looking for pattern 'Basic Pay DA MSP' expecting 3 amounts
SimplifiedPCDATableParser: Found pattern 'Basic Pay DA MSP' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Found pattern start at word index 65: 'Basic'
SimplifiedPCDATableParser: Searching for amounts starting from word index 69
SimplifiedPCDATableParser: Found amount 136400.0 at index 77
SimplifiedPCDATableParser: Found amount 57722.0 at index 78
SimplifiedPCDATableParser: Found amount 15500.0 at index 79
SimplifiedPCDATableParser: Extracted amounts: [136400.0, 57722.0, 15500.0]
SimplifiedPCDATableParser: Mapped to descriptions: [("Basic Pay", 136400.0), ("DA", 57722.0), ("MSP", 15500.0)]
SimplifiedPCDATableParser: Looking for pattern 'Tpt Allc SpCmd Pay' expecting 2 amounts
SimplifiedPCDATableParser: Found pattern 'Tpt Allc SpCmd Pay' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Found pattern start at word index 69: 'Tpt'
SimplifiedPCDATableParser: Searching for amounts starting from word index 73
SimplifiedPCDATableParser: Using Feb 2023 specific extraction for pattern 'Tpt Allc SpCmd Pay'
SimplifiedPCDATableParser: Looking for reference amounts: [4968.0, 25000.0]
SimplifiedPCDATableParser: Found reference amount 4968.0 at index 80
SimplifiedPCDATableParser: Found reference amount 25000.0 at index 81
SimplifiedPCDATableParser: Extracted amounts: [4968.0, 25000.0]
SimplifiedPCDATableParser: Mapped to descriptions: [("Tpt Allc", 4968.0), ("SpCmd Pay", 25000.0)]
SimplifiedPCDATableParser: Looking for pattern 'A/o.*Pay.*Allce' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'A/o Pay & Allce 136400 57722 15500 4968 25000 125000 DSOPF Subn AGIF Incm Tax Educ Cess L Fee Fur 8184 10000 89444 4001 748 326 Cr PARA-SC Dt. 01/09/2022 to 31/01/2023 Amt : 125000 RL//3/ P-0 Dt: 05/02/2021 Bldg : 159/2.Ne Dr L fee Dt : 01/02/2023 to 28/02/2023 748 Dr. fur Dt : 01/02/2023 to 28/02/2023 326 Part II Orders adjusted in this month Pt II Order No : 0287/2022 Dated : 23/12/2022 Pt II Order No : 0289/2022 Dated : 23/12/2022 REMITTANCE 251887 Total Credit 364590 Total Debit 364590 PLEASE SEE NEXT PAGE FOR IMPORTANT ALERTS. Note: This is a system generated document. Page - 1 / 402/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in * IMPORTANT ALERT * (1)  All Units / Formations are advised to ensure submission of soft copies of Part-II Orders published through HRMS. The .xml file should be uploaded on OASIS. Units not having access to ADN connectivity can send .xml files in CD to AG/MP 5&6. Hard copies may please be sent as per existing orders. (2)  a) Advances starting with DAK ID 'FB' are advances generate for booking of AIR Tickets through DTS portal by the Officers. Officers are advised to ensure submission of the corresponding claim for the Air Tickets booked through DTS along with tickets and Boarding Passes. Claims for DTS tickets, if not submitted within prescribed time limit, advance generated due to DTS will be recovered as per existing provisions. b) If the DTS tickets are cancelled, claim for reimbursement of cancellation charges along with sanction under TR 44b is required to be submitted to this office on priority to link the same. (3) w.e.f. 01.08.2020, advance for DA portion on Temporary Duty can also be obtained from DTS portal in addition to booking of Air/Train tickets from DTS. (4) Please ensure that Part-II order notifying casualties like DEPUTE/ SECONDMENT/DISMISSAL are published in time to avoid closing of IRLA with Debit Balance. (6) Officers who are willing to opt for new IT Regime may kindly use the utility available on PCDA(O) Website. HEADLINES (Please visit our website https://pcdaopune.gov.in for details.) * Based on feedback from Officers, we have increased the word limit and time limit for Grievance Module. All officers are requested to kindly use Grievance Module available on the website of PCDA(O) for prompt redressal of grievances. * Pay Slips, DSOP Fund Annual Statements and Form-16 are now available on OASIS App on ADN as well as on ARMAAN Mobile App. * Processing of all dues of retiring officers is now being completed well ahead of their date of retirement and the status intimated to them through D.O. letters alongwith a copy of their PPOs. * D.O. letters are being sent to newly commissioned officers, containing details about opening of their accounts in PCDA(O). If you see change in your CDA A/c Number .... CDA A/C No.is alloted to all officers in the format NN/NNN/NNNNNNA (N stands for Number, A stands for Alphabet.) The first five digits at the begining of this number i.e. NN/NNN are subject to CHANGE when our internal task distribution is changed in Ledger Wing.You need not worry about such change. The last six digits along with check alpha i.e. NNNNNNA is the number which will REMAIN FIXED THROUGHOUT THE SERVICE of an officer. PLEASE QUOTE CORRECT CDA ACCOUNT NUMBER IN ALL CORRESPONDENCE TO AVOID DELAY IN RESPONSE. Note: This is a system generated document. Page - 2 / 402/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / INCOME TAX DETAILS 1. Pay & Allce upto 28/02/2023 2. Taxable Income upto 28/02/2023 Excluding HRA 2895445 2874245 3. Estimated future taxable pay (Curr month salary x remaining months) 0 4. H.R.A / H.R.R. (Taxable Amount) 0 5. Income from other Source/House Property 6. Total taxable pay (Sl.No. 2+3+4+5) 2874245 7. Other taxable income (Ent.Allce' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Looking for pattern 'Basic Pay' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'Basic Pay' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Found pattern start at word index 65: 'Basic'
SimplifiedPCDATableParser: Searching for amounts starting from word index 67
SimplifiedPCDATableParser: Found amount 136400.0 at index 77
SimplifiedPCDATableParser: Extracted amounts: [136400.0]
SimplifiedPCDATableParser: Mapped to descriptions: []
SimplifiedPCDATableParser: Looking for pattern 'DA' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'DA' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Found pattern start at word index 67: 'DA'
SimplifiedPCDATableParser: Searching for amounts starting from word index 68
SimplifiedPCDATableParser: Found amount 136400.0 at index 77
SimplifiedPCDATableParser: Extracted amounts: [136400.0]
SimplifiedPCDATableParser: Mapped to descriptions: []
SimplifiedPCDATableParser: Looking for pattern 'MSP' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'MSP' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Found pattern start at word index 68: 'MSP'
SimplifiedPCDATableParser: Searching for amounts starting from word index 69
SimplifiedPCDATableParser: Found amount 136400.0 at index 77
SimplifiedPCDATableParser: Extracted amounts: [136400.0]
SimplifiedPCDATableParser: Mapped to descriptions: []
SimplifiedPCDATableParser: Looking for pattern 'Tpt Allc' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'Tpt Allc' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Found pattern start at word index 69: 'Tpt'
SimplifiedPCDATableParser: Searching for amounts starting from word index 71
SimplifiedPCDATableParser: Found amount 136400.0 at index 77
SimplifiedPCDATableParser: Extracted amounts: [136400.0]
SimplifiedPCDATableParser: Mapped to descriptions: []
SimplifiedPCDATableParser: Looking for pattern 'SpCmd Pay' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'SpCmd Pay' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Found pattern start at word index 71: 'SpCmd'
SimplifiedPCDATableParser: Searching for amounts starting from word index 73
SimplifiedPCDATableParser: Found amount 136400.0 at index 77
SimplifiedPCDATableParser: Extracted amounts: [136400.0]
SimplifiedPCDATableParser: Mapped to descriptions: []
SimplifiedPCDATableParser: Credit clusters found: 5 items
SimplifiedPCDATableParser: Trying sequential debit pattern extraction
SimplifiedPCDATableParser: Sequential debit pattern not found
SimplifiedPCDATableParser: Found known deduction DSOPF Subn: 8184.0
SimplifiedPCDATableParser: Found known deduction AGIF: 10000.0
SimplifiedPCDATableParser: Found known deduction Incm Tax: 89444.0
SimplifiedPCDATableParser: Found known deduction Educ Cess: 4001.0
SimplifiedPCDATableParser: Found known deduction L Fee: 748.0
SimplifiedPCDATableParser: Found known deduction Fur: 326.0
SimplifiedPCDATableParser: Looking for pattern 'DSOPF.*Subn' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'DSOPF Subn' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Looking for pattern 'AGIF' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'AGIF' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Found pattern start at word index 85: 'AGIF'
SimplifiedPCDATableParser: Searching for amounts starting from word index 86
SimplifiedPCDATableParser: Found amount 8184.0 at index 93
SimplifiedPCDATableParser: Extracted amounts: [8184.0]
SimplifiedPCDATableParser: Mapped to descriptions: [("AGIF", 8184.0)]
SimplifiedPCDATableParser: Looking for pattern 'Incm.*Tax' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'Incm Tax Educ Cess L Fee Fur 8184 10000 89444 4001 748 326 Cr PARA-SC Dt. 01/09/2022 to 31/01/2023 Amt : 125000 RL//3/ P-0 Dt: 05/02/2021 Bldg : 159/2.Ne Dr L fee Dt : 01/02/2023 to 28/02/2023 748 Dr. fur Dt : 01/02/2023 to 28/02/2023 326 Part II Orders adjusted in this month Pt II Order No : 0287/2022 Dated : 23/12/2022 Pt II Order No : 0289/2022 Dated : 23/12/2022 REMITTANCE 251887 Total Credit 364590 Total Debit 364590 PLEASE SEE NEXT PAGE FOR IMPORTANT ALERTS. Note: This is a system generated document. Page - 1 / 402/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in * IMPORTANT ALERT * (1)  All Units / Formations are advised to ensure submission of soft copies of Part-II Orders published through HRMS. The .xml file should be uploaded on OASIS. Units not having access to ADN connectivity can send .xml files in CD to AG/MP 5&6. Hard copies may please be sent as per existing orders. (2)  a) Advances starting with DAK ID 'FB' are advances generate for booking of AIR Tickets through DTS portal by the Officers. Officers are advised to ensure submission of the corresponding claim for the Air Tickets booked through DTS along with tickets and Boarding Passes. Claims for DTS tickets, if not submitted within prescribed time limit, advance generated due to DTS will be recovered as per existing provisions. b) If the DTS tickets are cancelled, claim for reimbursement of cancellation charges along with sanction under TR 44b is required to be submitted to this office on priority to link the same. (3) w.e.f. 01.08.2020, advance for DA portion on Temporary Duty can also be obtained from DTS portal in addition to booking of Air/Train tickets from DTS. (4) Please ensure that Part-II order notifying casualties like DEPUTE/ SECONDMENT/DISMISSAL are published in time to avoid closing of IRLA with Debit Balance. (6) Officers who are willing to opt for new IT Regime may kindly use the utility available on PCDA(O) Website. HEADLINES (Please visit our website https://pcdaopune.gov.in for details.) * Based on feedback from Officers, we have increased the word limit and time limit for Grievance Module. All officers are requested to kindly use Grievance Module available on the website of PCDA(O) for prompt redressal of grievances. * Pay Slips, DSOP Fund Annual Statements and Form-16 are now available on OASIS App on ADN as well as on ARMAAN Mobile App. * Processing of all dues of retiring officers is now being completed well ahead of their date of retirement and the status intimated to them through D.O. letters alongwith a copy of their PPOs. * D.O. letters are being sent to newly commissioned officers, containing details about opening of their accounts in PCDA(O). If you see change in your CDA A/c Number .... CDA A/C No.is alloted to all officers in the format NN/NNN/NNNNNNA (N stands for Number, A stands for Alphabet.) The first five digits at the begining of this number i.e. NN/NNN are subject to CHANGE when our internal task distribution is changed in Ledger Wing.You need not worry about such change. The last six digits along with check alpha i.e. NNNNNNA is the number which will REMAIN FIXED THROUGHOUT THE SERVICE of an officer. PLEASE QUOTE CORRECT CDA ACCOUNT NUMBER IN ALL CORRESPONDENCE TO AVOID DELAY IN RESPONSE. Note: This is a system generated document. Page - 2 / 402/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / INCOME TAX DETAILS 1. Pay & Allce upto 28/02/2023 2. Taxable Income upto 28/02/2023 Excluding HRA 2895445 2874245 3. Estimated future taxable pay (Curr month salary x remaining months) 0 4. H.R.A / H.R.R. (Taxable Amount) 0 5. Income from other Source/House Property 6. Total taxable pay (Sl.No. 2+3+4+5) 2874245 7. Other taxable income (Ent.Allce,etc.) * 8. Deductions Under Chapter VI-A Savings Declared Savings Cleared Actual Amount a) 80C 150000 0 0 197864 b) 80D c) 80DD d) 80E e) 80DDB f) 80U g) 80G(G1+G2) 0 0 0 0 h) Neg. Inc from House Property *Valid upto Nov 2022 Max permissible exemption from IT under Chapter VI-A Standard Deduction 50000 9. Net Taxable Income ((Sl.No. 6 + Sl.No. 7) - (Sl.No. 8)) 10. Total Income Tax (Tax on Sl.No. 9) 11. Income Tax Deducted 614774 12. Educ.Cess Deducted 24591 13. Saving Thru IRLA upto 02/2023 150000 2674245 614774 197864 14. Est.Savings for 2022-2023 197864 15. Personal Savings Declared 16. Personal Savings Cleared / DSOP FUND FOR THE CURRENT YEAR UPTO 31/01/2023 OPENING BALANCE 540908 SUBSCRIPTION 79680 REFUND 0 MISC ADJ 0 WITHDRAWAL 0 CLOSING BALANCE 620588 TYPE HBA MCA PCA / LOANS & ADVANCES UPTO 31/01/2023 TOTAL AMOUNT REFUNDED CLOSING BALANCE 0 0 0 0 0 0 0 0 0 * INDICATES RECOVERY OF INTEREST Note: This is a system generated document. Page - 3 / 402/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in DETAILS OF ARREARS / RECOVERY POSTED IN IRLA FROM DATE TO DATE TOTAL AARS TAX ARRS TOTAL REC TAX-REC ARR RATE REC RATE MESSAGE 01/09/2022 01/11/2022 01/01/2023 31/10/2022 31/12/2022 31/01/2023 50000 50000 25000 50000 50000 25000 0 0 0 0 0 0 25000 25000 25000 0 Cr. PARA-SC 0 Cr. PARA-SC 0 Cr. PARA-SC TOTAL ARREARS / RECOVERIES Arrears : 125000 Taxable Arrears : 125000 Recovery : 0 Tax' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Looking for pattern 'Educ.*Cess' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'Educ Cess L Fee Fur 8184 10000 89444 4001 748 326 Cr PARA-SC Dt. 01/09/2022 to 31/01/2023 Amt : 125000 RL//3/ P-0 Dt: 05/02/2021 Bldg : 159/2.Ne Dr L fee Dt : 01/02/2023 to 28/02/2023 748 Dr. fur Dt : 01/02/2023 to 28/02/2023 326 Part II Orders adjusted in this month Pt II Order No : 0287/2022 Dated : 23/12/2022 Pt II Order No : 0289/2022 Dated : 23/12/2022 REMITTANCE 251887 Total Credit 364590 Total Debit 364590 PLEASE SEE NEXT PAGE FOR IMPORTANT ALERTS. Note: This is a system generated document. Page - 1 / 402/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in * IMPORTANT ALERT * (1)  All Units / Formations are advised to ensure submission of soft copies of Part-II Orders published through HRMS. The .xml file should be uploaded on OASIS. Units not having access to ADN connectivity can send .xml files in CD to AG/MP 5&6. Hard copies may please be sent as per existing orders. (2)  a) Advances starting with DAK ID 'FB' are advances generate for booking of AIR Tickets through DTS portal by the Officers. Officers are advised to ensure submission of the corresponding claim for the Air Tickets booked through DTS along with tickets and Boarding Passes. Claims for DTS tickets, if not submitted within prescribed time limit, advance generated due to DTS will be recovered as per existing provisions. b) If the DTS tickets are cancelled, claim for reimbursement of cancellation charges along with sanction under TR 44b is required to be submitted to this office on priority to link the same. (3) w.e.f. 01.08.2020, advance for DA portion on Temporary Duty can also be obtained from DTS portal in addition to booking of Air/Train tickets from DTS. (4) Please ensure that Part-II order notifying casualties like DEPUTE/ SECONDMENT/DISMISSAL are published in time to avoid closing of IRLA with Debit Balance. (6) Officers who are willing to opt for new IT Regime may kindly use the utility available on PCDA(O) Website. HEADLINES (Please visit our website https://pcdaopune.gov.in for details.) * Based on feedback from Officers, we have increased the word limit and time limit for Grievance Module. All officers are requested to kindly use Grievance Module available on the website of PCDA(O) for prompt redressal of grievances. * Pay Slips, DSOP Fund Annual Statements and Form-16 are now available on OASIS App on ADN as well as on ARMAAN Mobile App. * Processing of all dues of retiring officers is now being completed well ahead of their date of retirement and the status intimated to them through D.O. letters alongwith a copy of their PPOs. * D.O. letters are being sent to newly commissioned officers, containing details about opening of their accounts in PCDA(O). If you see change in your CDA A/c Number .... CDA A/C No.is alloted to all officers in the format NN/NNN/NNNNNNA (N stands for Number, A stands for Alphabet.) The first five digits at the begining of this number i.e. NN/NNN are subject to CHANGE when our internal task distribution is changed in Ledger Wing.You need not worry about such change. The last six digits along with check alpha i.e. NNNNNNA is the number which will REMAIN FIXED THROUGHOUT THE SERVICE of an officer. PLEASE QUOTE CORRECT CDA ACCOUNT NUMBER IN ALL CORRESPONDENCE TO AVOID DELAY IN RESPONSE. Note: This is a system generated document. Page - 2 / 402/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / INCOME TAX DETAILS 1. Pay & Allce upto 28/02/2023 2. Taxable Income upto 28/02/2023 Excluding HRA 2895445 2874245 3. Estimated future taxable pay (Curr month salary x remaining months) 0 4. H.R.A / H.R.R. (Taxable Amount) 0 5. Income from other Source/House Property 6. Total taxable pay (Sl.No. 2+3+4+5) 2874245 7. Other taxable income (Ent.Allce,etc.) * 8. Deductions Under Chapter VI-A Savings Declared Savings Cleared Actual Amount a) 80C 150000 0 0 197864 b) 80D c) 80DD d) 80E e) 80DDB f) 80U g) 80G(G1+G2) 0 0 0 0 h) Neg. Inc from House Property *Valid upto Nov 2022 Max permissible exemption from IT under Chapter VI-A Standard Deduction 50000 9. Net Taxable Income ((Sl.No. 6 + Sl.No. 7) - (Sl.No. 8)) 10. Total Income Tax (Tax on Sl.No. 9) 11. Income Tax Deducted 614774 12. Educ.Cess' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Looking for pattern 'L.*Fee' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'l Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in / CREDIT / DEBIT / DETAILS OF TRANSACTIONS DESCRIPTION AMOUNT DESCRIPTION AMOUNT Basic Pay DA MSP Tpt Allc SpCmd Pay A/o Pay & Allce 136400 57722 15500 4968 25000 125000 DSOPF Subn AGIF Incm Tax Educ Cess L Fee Fur 8184 10000 89444 4001 748 326 Cr PARA-SC Dt. 01/09/2022 to 31/01/2023 Amt : 125000 RL//3/ P-0 Dt: 05/02/2021 Bldg : 159/2.Ne Dr L fee Dt : 01/02/2023 to 28/02/2023 748 Dr. fur Dt : 01/02/2023 to 28/02/2023 326 Part II Orders adjusted in this month Pt II Order No : 0287/2022 Dated : 23/12/2022 Pt II Order No : 0289/2022 Dated : 23/12/2022 REMITTANCE 251887 Total Credit 364590 Total Debit 364590 PLEASE SEE NEXT PAGE FOR IMPORTANT ALERTS. Note: This is a system generated document. Page - 1 / 402/2023 STATEMENT OF ACCOUNT FOR 02/2023 CONTACT Tel Nos in PCDA(O), Pune : PRO CIVIL : ((020) 2640- 1111/1333/1353/1356) PRO ARMY : (6512/6528/7756/7761/7762/7763) NAME : SUNIL SURESH PAWAR : 16/110/206718K CDA A/C NO Grievance Portal : https://pcdaopune.gov.in Email : TA/DA Grievance: tada-pcdaopune@nic.in Ledger Grievance: ledger-pcdaopune@nic.in Rank pay related issue: rankpay-pcdaopune@nic.in Other grievances: generalquery-pcdaopune@nic.in * IMPORTANT ALERT * (1)  All Units / Formations are advised to ensure submission of soft copies of Part-II Orders published through HRMS. The .xml file should be uploaded on OASIS. Units not having access to ADN connectivity can send .xml files in CD to AG/MP 5&6. Hard copies may please be sent as per existing orders. (2)  a) Advances starting with DAK ID 'FB' are advances generate for booking of AIR Tickets through DTS portal by the Officers. Officers are advised to ensure submission of the corresponding claim for the Air Tickets booked through DTS along with tickets and Boarding Passes. Claims for DTS tickets, if not submitted within prescribed time limit, advance generated due to DTS will be recovered as per existing provisions. b) If the DTS tickets are cancelled, claim for reimbursement of cancellation charges along with sanction under TR 44b is required to be submitted to this office on priority to link the same. (3) w.e.f. 01.08.2020, advance for DA portion on Temporary Duty can also be obtained from DTS portal in addition to booking of Air/Train tickets from DTS. (4) Please ensure that Part-II order notifying casualties like DEPUTE/ SECONDMENT/DISMISSAL are published in time to avoid closing of IRLA with Debit Balance. (6) Officers who are willing to opt for new IT Regime may kindly use the utility available on PCDA(O) Website. HEADLINES (Please visit our website https://pcdaopune.gov.in for details.) * Based on fee' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Could not find pattern start index
SimplifiedPCDATableParser: Looking for pattern 'Fur' expecting 1 amounts
SimplifiedPCDATableParser: Found pattern 'Fur' in text
SimplifiedPCDATableParser: Total words in line: 1112
SimplifiedPCDATableParser: Found pattern start at word index 92: 'Fur'
SimplifiedPCDATableParser: Searching for amounts starting from word index 93
SimplifiedPCDATableParser: Found amount 8184.0 at index 93
SimplifiedPCDATableParser: Extracted amounts: [8184.0]
SimplifiedPCDATableParser: Mapped to descriptions: [("Fur", 8184.0)]
SimplifiedPCDATableParser: Looking for pattern 'Water' expecting 1 amounts
SimplifiedPCDATableParser: Pattern 'Water' not found in text
SimplifiedPCDATableParser: Debit clusters found: 8 items
SimplifiedPCDATableParser: Cluster analysis extracted 13 items: [("Basic Pay", 136400.0), ("DA", 57722.0), ("MSP", 15500.0), ("Tpt Allc", 4968.0), ("SpCmd Pay", 25000.0), ("DSOPF Subn", 8184.0), ("AGIF", 10000.0), ("Incm Tax", 89444.0), ("Educ Cess", 4001.0), ("L Fee", 748.0), ("Fur", 326.0), ("AGIF", 8184.0), ("Fur", 8184.0)]
SimplifiedPCDATableParser: Tabulated format extraction successful - found 13 pairs
SimplifiedPCDATableParser: Direct earning match for Basic Pay
SimplifiedPCDATableParser: Direct earning match for DA
SimplifiedPCDATableParser: Direct earning match for MSP
SimplifiedPCDATableParser: Direct earning match for Tpt Allc
SimplifiedPCDATableParser: Direct earning match for SpCmd Pay
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
SimplifiedPCDATableParser: Direct deduction match for AGIF
SimplifiedPCDATableParser: Direct deduction match for AGIF
SimplifiedPCDATableParser: Direct deduction match for Fur
SimplifiedPCDATableParser: Direct deduction match for Fur
SimplifiedPCDATableParser: Extracted credit via fallback - SpCmd Pay: 25000.0
SimplifiedPCDATableParser: Extracted credit via fallback - DA: 57722.0
SimplifiedPCDATableParser: Extracted credit via fallback - Basic Pay: 136400.0
SimplifiedPCDATableParser: Extracted credit via fallback - MSP: 15500.0
SimplifiedPCDATableParser: Extracted credit via fallback - Tpt Allc: 4968.0
SimplifiedPCDATableParser: Extracted debit via fallback - Incm Tax: 89444.0
SimplifiedPCDATableParser: Extracted debit via fallback - L Fee: 748.0
SimplifiedPCDATableParser: Extracted debit via fallback - Fur: 8184.0
SimplifiedPCDATableParser: Extracted debit via fallback - AGIF: 8184.0
SimplifiedPCDATableParser: Extracted debit via fallback - Educ Cess: 4001.0
SimplifiedPCDATableParser: Extracted debit via fallback - DSOPF Subn: 8184.0
SimplifiedPCDATableParser: Successfully extracted 11 items via enhanced fallback
SimplifiedPCDATableParser: Successfully extracted from PCDA table structure
MilitaryFinancialDataExtractor: Simplified PCDA parser successful - earnings: 5, deductions: 6
MilitaryFinancialDataExtractor: Final result - earnings: 5, deductions: 6
[MilitaryPayslipProcessor] PCDA extraction successful - earnings: 5, deductions: 6
[MilitaryPayslipProcessor] Added earning: SPCMD PAY: 25000.0
[MilitaryPayslipProcessor] Added earning: BPAY: 136400.0
[MilitaryPayslipProcessor] Added earning: DA: 57722.0
[MilitaryPayslipProcessor] Added earning: MSP: 15500.0
[MilitaryPayslipProcessor] Added earning: TPTA: 4968.0
[MilitaryPayslipProcessor] Added deduction: FUR: 8184.0
[MilitaryPayslipProcessor] Added deduction: L FEE: 748.0
[MilitaryPayslipProcessor] Added deduction: ITAX: 89444.0
[MilitaryPayslipProcessor] Added deduction: EHCESS: 4001.0
[MilitaryPayslipProcessor] Added deduction: AGIF: 8184.0
[MilitaryPayslipProcessor] Added deduction: DSOP: 8184.0
[MilitaryPayslipProcessor] Set total credits (computed): 239590.0
[MilitaryPayslipProcessor] Set total debits (computed): 118745.0
[MilitaryPayslipProcessor] PCDA processing completed in 0.91s
[MilitaryPayslipProcessor] Extracted date: February 2023
[MilitaryPayslipProcessor] Creating military payslip with credits: 239590.0, debits: 118745.0
[PayslipProcessingStep] Completed in 0.9233019351959229 seconds
[ModularPipeline] Total pipeline execution time: 18.549224972724915 seconds
[PDFProcessingHandler] processPDFData completed
[PDFProcessingCoordinator] Successfully parsed payslip
[PayslipDataHandler] PDF saved at: /var/mobile/Containers/Data/Application/748222B2-F953-448C-8F56-A1D6C0BCCC70/Documents/PDFs/7FB07811-18EA-449F-8016-C704DEA95075.pdf
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
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 194122.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 194122.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0
NotificationCoordinator: Handling payslips refresh notification
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 194122.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0
PayslipsViewModel: Loaded 6 payslips and applied sorting with order: dateDescending
DataService: Refreshed fetch returned 6 items
PayslipDataHandler: Loaded 6 payslips
HomeViewModel: Data loading completed successfully
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 194122.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 57722.0, MSP: 15500.0
PayslipData: knownEarnings: 209622.0, miscCredits: 29968.0