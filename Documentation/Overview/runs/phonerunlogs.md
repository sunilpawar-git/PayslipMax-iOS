🚀 Initializing LiteRT features for enhanced payslip processing...
[LiteRTFeatureFlags] Configuration loaded - LiteRT enabled: true
[LiteRTFeatureFlags] Disabling all LiteRT features
[LiteRTFeatureFlags] Production configuration loaded: Development, Rollout: 0%
[LiteRTFeatureFlags] Enabling Phase 1 features
[LiteRTFeatureFlags] Updated enableSmartFormatDetection: true
[LiteRTFeatureFlags] Updated enableAIParserSelection: true
[LiteRTFeatureFlags] Updated enableFinancialIntelligence: true
[LiteRTFeatureFlags] Updated enableMilitaryCodeRecognition: true
[LiteRTFeatureFlags] Updated enableAdaptiveLearning: true
[LiteRTFeatureFlags] Updated enablePersonalization: true
[LiteRTFeatureFlags] Updated enablePredictiveAnalysis: true
[LiteRTFeatureFlags] Updated enableAnomalyDetection: true
[LiteRTFeatureFlags] Enabling Phase 1 features
[LiteRTFeatureFlags] Configured for Production environment with 100% rollout
✅ LiteRT features enabled successfully!
   📊 LiteRT Enabled: true
   🎯 Phase 1 Complete: true
   📈 Rollout Percentage: 100%
   🌍 Environment: Production
   🔧 Core Features:
      • Table Structure Detection: true
      • PCDA Optimization: true
      • Hybrid Processing: true
   🚀 Advanced Features:
      • Smart Format Detection: true
      • AI Parser Selection: true
      • Financial Intelligence: true
🎯 Expected Results:
   📈 Accuracy: 95%+ on pre-Nov 2023 payslips (vs 15% baseline)
   ⚡ Speed: <500ms inference (vs 2-3s baseline)
   🧠 Memory: 70% reduction with optimized models
   🔋 Battery: 40% reduction with hardware acceleration
ℹ️ Performance tracking system initialized. Use the hammer icon in navigation bar to toggle performance warnings.
FeatureContainer: Creating WebUploadCoordinator with base URL: https://payslipmax.com/api
DeepLinkCoordinator initialized
DataPersistenceService: Successfully loaded 0 uploads
DataPersistenceService: Saving uploads to /var/mobile/Containers/Data/Application/4875E153-890B-4147-9EBF-E9DDDAFA7835/Documents/WebUploads/uploads.json
DataPersistenceService: Successfully saved 0 uploads
UploadManagementService: Checking for pending uploads from server
DeviceRegistrationService: Attempting to register device
DeviceRegistrationService: Retrieved device token from secure storage
✅ Async security coordinator initialized successfully
✅ Async security services configured successfully
boringssl_context_handle_fatal_alert(2313) [C1.1.1.1:2][0x12e2e6200] read alert, level: fatal, description: internal error
boringssl_session_handshake_incomplete(244) [C1.1.1.1:2][0x12e2e6200] SSL library error
boringssl_session_handshake_error_print(47) [C1.1.1.1:2][0x12e2e6200] Error: 5080655488:error:10000438:SSL routines:OPENSSL_internal:TLSV1_ALERT_INTERNAL_ERROR:/Library/Caches/com.apple.xbs/Sources/boringssl/ssl/tls_record.cc:579:SSL alert number 80
nw_protocol_boringssl_handshake_negotiate_proceed(788) [C1.1.1.1:2][0x12e2e6200] handshake failed at state 12288: not completed
nw_endpoint_flow_failed_with_error [C1.1.1.1 84.32.84.32:443 in_progress channel-flow (satisfied (Path is satisfied), viable, interface: pdp_ip0[lte], ipv4, ipv6, dns, expensive, uses cell)] already failing, returning
nw_endpoint_flow_failed_with_error [C1.1.1.1 84.32.84.32:443 cancelled channel-flow ((null))] already failing, returning
Connection 1: received failure notification
Connection 1: failed to connect 3:-9838, reason -1
Connection 1: encountered error(3:-9838)
Task <0772985F-0520-47EE-BC44-639463FBC944>.<1> HTTP load failed, 0/0 bytes (error code: -1200 [3:-9838])
Task <0772985F-0520-47EE-BC44-639463FBC944>.<1> finished with error [-1200] Error Domain=NSURLErrorDomain Code=-1200 "An SSL error has occurred and a secure connection to the server cannot be made." UserInfo={NSErrorFailingURLStringKey=https://payslipmax.com/api/uploads/pending, NSLocalizedRecoverySuggestion=Would you like to connect to the server anyway?, _kCFStreamErrorDomainKey=3, _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <0772985F-0520-47EE-BC44-639463FBC944>.<1>, _NSURLErrorRelatedURLSessionTaskErrorKey=(
    "LocalDataTask <0772985F-0520-47EE-BC44-639463FBC944>.<1>"
), NSLocalizedDescription=An SSL error has occurred and a secure connection to the server cannot be made., NSErrorFailingURLKey=https://payslipmax.com/api/uploads/pending, NSUnderlyingError=0x12ed56670 {Error Domain=kCFErrorDomainCFNetwork Code=-1200 "(null)" UserInfo={_kCFStreamPropertySSLClientCertificateState=0, _kCFNetworkCFStreamSSLErrorOriginalValue=-9838, _kCFStreamErrorDomainKey=3, _kCFStreamErrorCodeKey=-9838, _NSURLErrorNWPathKey=satisfied (Path is satisfied), viable, interface: pdp_ip0[lte], ipv4, ipv6, dns, expensive, uses cell}}, _kCFStreamErrorCodeKey=-9838}
UploadManagementService: Failed to get device token or check for pending uploads: Error Domain=NSURLErrorDomain Code=-1200 "An SSL error has occurred and a secure connection to the server cannot be made." UserInfo={NSErrorFailingURLStringKey=https://payslipmax.com/api/uploads/pending, NSLocalizedRecoverySuggestion=Would you like to connect to the server anyway?, _kCFStreamErrorDomainKey=3, _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <0772985F-0520-47EE-BC44-639463FBC944>.<1>, _NSURLErrorRelatedURLSessionTaskErrorKey=(
    "LocalDataTask <0772985F-0520-47EE-BC44-639463FBC944>.<1>"
), NSLocalizedDescription=An SSL error has occurred and a secure connection to the server cannot be made., NSErrorFailingURLKey=https://payslipmax.com/api/uploads/pending, NSUnderlyingError=0x12ed56670 {Error Domain=kCFErrorDomainCFNetwork Code=-1200 "(null)" UserInfo={_kCFStreamPropertySSLClientCertificateState=0, _kCFNetworkCFStreamSSLErrorOriginalValue=-9838, _kCFStreamErrorDomainKey=3, _kCFStreamErrorCodeKey=-9838, _NSURLErrorNWPathKey=satisfied (Path is satisfied), viable, interface: pdp_ip0[lte], ipv4, ipv6, dns, expensive, uses cell}}, _kCFStreamErrorCodeKey=-9838}
[ProcessingContainer] Creating AI-enhanced PDF parsing coordinator
[PayslipParserRegistry] Registered new parser: VisionPayslipParser
[PayslipParserRegistry] Registered new parser: PageAwareParser
[PayslipParserRegistry] Registered new parser: PCDAPayslipParser
[TableStructureDetector] Initialized with ML support: true
[EnhancedVisionTextExtractor] Initialized with LiteRT integration: true
[PDFTextExtractionService] Initialized with AI enhancement: true
[LiteRTModelManager] LiteRTModelManager initialized
[LiteRTModelManager] 🔍 Verifying AI model availability...
[LiteRTModelManager] ✅ Model available: table_detection
[LiteRTModelManager] ✅ Model available: text_recognition
[LiteRTModelManager] ✅ Model available: document_classifier
[LiteRTModelManager] ✅ Model available: financial_data_validator
[LiteRTModelManager] ✅ Model available: financial_validator_v2_latest
[LiteRTModelManager] ✅ Model available: financial_data_validator_real
[LiteRTModelManager] ✅ Model available: pp_ocr_v3
[LiteRTModelManager] ✅ Model available: pp_ocr_v3_real
[LiteRTModelManager] ✅ Model available: pp_ocr_v5_latest
[LiteRTModelManager] ✅ Model available: pp_structure_v2
[LiteRTModelManager] ✅ Model available: pp_structure_v2_real
[LiteRTModelManager] ✅ Model available: pp_structure_v3_latest
[LiteRTModelManager] ✅ Model available: layout_lm_v3
[LiteRTModelManager] 📊 Model verification complete: 13/13 models available
[LiteRTModelManager] 🎉 All AI models loaded successfully!
[LiteRTModelManager] Model metadata loaded successfully
[LiteRTService] Initializing LiteRT service
[TableStructureDetector] Initialized with ML support: true
[EnhancedVisionTextExtractor] Initialized with LiteRT integration: true
[PDFTextExtractionService] Initialized with AI enhancement: true
PatternMatchingService: Initialized with 51 patterns, 6 earnings patterns, and 6 deductions patterns
PatternMatchingService: Initialized with 51 patterns, 6 earnings patterns, and 6 deductions patterns
PatternMatchingService: Initialized with 51 patterns, 6 earnings patterns, and 6 deductions patterns
[LiteRTService] Initializing LiteRT service
PatternMatchingService: Initialized with 51 patterns, 6 earnings patterns, and 6 deductions patterns
[LiteRTService] Initializing LiteRT service
PatternMatchingService: Initialized with 51 patterns, 6 earnings patterns, and 6 deductions patterns
[TableStructureDetector] Initialized with ML support: true
[TableStructureDetector] Initialized with ML support: true
[EnhancedVisionTextExtractor] Initialized with LiteRT integration: true
[EnhancedPDFExtractionCoordinator] Initialized with LiteRT processing: true
[AIEnhancedParsingCoordinator] Initialized with AI-enhanced PDF processing
[TableStructureDetector] Initialized with ML support: true
[EnhancedVisionTextExtractor] Initialized with LiteRT integration: true
[PDFTextExtractionService] Initialized with AI enhancement: true
[LiteRTService] Initializing LiteRT service
[TableStructureDetector] Initialized with ML support: true
[EnhancedVisionTextExtractor] Initialized with LiteRT integration: true
[PDFTextExtractionService] Initialized with AI enhancement: true
[TableStructureDetector] Initialized with ML support: true
[EnhancedVisionTextExtractor] Initialized with LiteRT integration: true
[PDFTextExtractionService] Initialized with AI enhancement: true
[TableStructureDetector] Initialized with ML support: true
[EnhancedVisionTextExtractor] Initialized with LiteRT integration: true
[PDFTextExtractionService] Initialized with AI enhancement: true
[LiteRTService] Starting service initialization
[LiteRTService] Using TensorFlow Lite for real ML model inference
[LiteRTService] Loading core models
[LiteRTService] Setting up hardware acceleration
[LiteRTService] Hardware acceleration configured with Metal
[LiteRTService] Using original model (may be EdgeTPU-incompatible)
Created TensorFlow Lite XNNPACK delegate for CPU.
INFO: Created TensorFlow Lite XNNPACK delegate for CPU.
Initialized TensorFlow Lite runtime.
INFO: Initialized TensorFlow Lite runtime.
TensorFlow Lite Error: Encountered unresolved custom op: edgetpu-custom-op.
See instructions: https://www.tensorflow.org/lite/guide/ops_custom 
TensorFlow Lite Error: Node number 0 (edgetpu-custom-op) failed to prepare.
[LiteRTService] Failed to load table detection model (likely EdgeTPU incompatibility): Failed to allocate memory for input tensors.
[LiteRTService] Attempting enhanced heuristic fallback for table detection
[LiteRTService] ✅ Enhanced heuristic table detection enabled
[LiteRTService] Using original model (may be EdgeTPU-incompatible)
TensorFlow Lite Error: Encountered unresolved custom op: edgetpu-custom-op.
See instructions: https://www.tensorflow.org/lite/guide/ops_custom 
TensorFlow Lite Error: Node number 0 (edgetpu-custom-op) failed to prepare.
[LiteRTService] Failed to load text recognition model (likely EdgeTPU incompatibility): Failed to allocate memory for input tensors.
[LiteRTService] Attempting enhanced Vision framework fallback for text recognition
[LiteRTService] ✅ Enhanced Vision-based text recognition enabled
TensorFlow Lite Error: Encountered unresolved custom op: edgetpu-custom-op.
See instructions: https://www.tensorflow.org/lite/guide/ops_custom 
TensorFlow Lite Error: Node number 0 (edgetpu-custom-op) failed to prepare.
[LiteRTService] Failed to load document classifier model: Failed to allocate memory for input tensors.
[LiteRTService] Initialization failed: modelLoadingFailed(Failed to allocate memory for input tensors.)
[EnhancedPDFExtractionCoordinator] LiteRT initialization failed: modelLoadingFailed(PayslipMax.LiteRTError.modelLoadingFailed(Failed to allocate memory for input tensors.))
DataService: Refreshed fetch returned 5 items
PayslipDataHandler: Loaded 5 payslips
ℹ️ [INFO] [PDFManager] PDF directory is writable - PDFManager.swift:57 in checkAndCreatePDFDirectory()
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
HomeViewModel: Data loading completed successfully
NotificationCoordinator: Handling payslips refresh notification
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipsViewModel: Loaded 5 payslips and applied sorting with order: dateDescending
DataService: Refreshed fetch returned 5 items
PayslipDataHandler: Loaded 5 payslips
HomeViewModel: Data loading completed successfully
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0
PayslipData: Found RH12 value: 0.0
PayslipData: Basic Pay: 136400.0, DA: 63798.0, MSP: 15500.0
PayslipData: knownEarnings: 215698.0, miscCredits: 0.0