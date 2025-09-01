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
DataPersistenceService: Saving uploads to /var/mobile/Containers/Data/Application/F6786A50-79F4-4A90-B344-199EAF58B7A3/Documents/WebUploads/uploads.json
DataPersistenceService: Successfully saved 0 uploads
UploadManagementService: Checking for pending uploads from server
DeviceRegistrationService: Attempting to register device
DeviceRegistrationService: Retrieved device token from secure storage
✅ Async security coordinator initialized successfully
✅ Async security services configured successfully
boringssl_context_handle_fatal_alert(2313) [C1.1.1.1:2][0x138265e00] read alert, level: fatal, description: internal error
boringssl_session_handshake_incomplete(244) [C1.1.1.1:2][0x138265e00] SSL library error
boringssl_session_handshake_error_print(47) [C1.1.1.1:2][0x138265e00] Error: 5248346176:error:10000438:SSL routines:OPENSSL_internal:TLSV1_ALERT_INTERNAL_ERROR:/Library/Caches/com.apple.xbs/Sources/boringssl/ssl/tls_record.cc:579:SSL alert number 80
nw_protocol_boringssl_handshake_negotiate_proceed(788) [C1.1.1.1:2][0x138265e00] handshake failed at state 12288: not completed
nw_endpoint_flow_failed_with_error [C1.1.1.1 84.32.84.32:443 in_progress channel-flow (satisfied (Path is satisfied), viable, interface: en0[802.11], ipv4, dns, uses wifi)] already failing, returning
nw_endpoint_flow_failed_with_error [C1.1.1.1 84.32.84.32:443 cancelled channel-flow ((null))] already failing, returning
Connection 1: received failure notification
Connection 1: failed to connect 3:-9838, reason -1
Connection 1: encountered error(3:-9838)
Task <DB12D257-285A-4BAB-AA31-A2346BE20C71>.<1> HTTP load failed, 0/0 bytes (error code: -1200 [3:-9838])
Task <DB12D257-285A-4BAB-AA31-A2346BE20C71>.<1> finished with error [-1200] Error Domain=NSURLErrorDomain Code=-1200 "An SSL error has occurred and a secure connection to the server cannot be made." UserInfo={NSErrorFailingURLStringKey=https://payslipmax.com/api/uploads/pending, NSLocalizedRecoverySuggestion=Would you like to connect to the server anyway?, _kCFStreamErrorDomainKey=3, _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <DB12D257-285A-4BAB-AA31-A2346BE20C71>.<1>, _NSURLErrorRelatedURLSessionTaskErrorKey=(
    "LocalDataTask <DB12D257-285A-4BAB-AA31-A2346BE20C71>.<1>"
), NSLocalizedDescription=An SSL error has occurred and a secure connection to the server cannot be made., NSErrorFailingURLKey=https://payslipmax.com/api/uploads/pending, NSUnderlyingError=0x138d00f60 {Error Domain=kCFErrorDomainCFNetwork Code=-1200 "(null)" UserInfo={_kCFStreamPropertySSLClientCertificateState=0, _kCFNetworkCFStreamSSLErrorOriginalValue=-9838, _kCFStreamErrorDomainKey=3, _kCFStreamErrorCodeKey=-9838, _NSURLErrorNWPathKey=satisfied (Path is satisfied), viable, interface: en0[802.11], ipv4, dns, uses wifi}}, _kCFStreamErrorCodeKey=-9838}
UploadManagementService: Failed to get device token or check for pending uploads: Error Domain=NSURLErrorDomain Code=-1200 "An SSL error has occurred and a secure connection to the server cannot be made." UserInfo={NSErrorFailingURLStringKey=https://payslipmax.com/api/uploads/pending, NSLocalizedRecoverySuggestion=Would you like to connect to the server anyway?, _kCFStreamErrorDomainKey=3, _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <DB12D257-285A-4BAB-AA31-A2346BE20C71>.<1>, _NSURLErrorRelatedURLSessionTaskErrorKey=(
    "LocalDataTask <DB12D257-285A-4BAB-AA31-A2346BE20C71>.<1>"
), NSLocalizedDescription=An SSL error has occurred and a secure connection to the server cannot be made., NSErrorFailingURLKey=https://payslipmax.com/api/uploads/pending, NSUnderlyingError=0x138d00f60 {Error Domain=kCFErrorDomainCFNetwork Code=-1200 "(null)" UserInfo={_kCFStreamPropertySSLClientCertificateState=0, _kCFNetworkCFStreamSSLErrorOriginalValue=-9838, _kCFStreamErrorDomainKey=3, _kCFStreamErrorCodeKey=-9838, _NSURLErrorNWPathKey=satisfied (Path is satisfied), viable, interface: en0[802.11], ipv4, dns, uses wifi}}, _kCFStreamErrorCodeKey=-9838}
[PayslipParserRegistry] Registered new parser: VisionPayslipParser
[PayslipParserRegistry] Registered new parser: PageAwareParser
[PayslipParserRegistry] Registered new parser: PCDAPayslipParser
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
DataService: Refreshed fetch returned 0 items
PayslipDataHandler: Loaded 0 payslips
HomeViewModel: Data loading completed successfully