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
DataPersistenceService: Saving uploads to /var/mobile/Containers/Data/Application/B66EC707-760C-49C2-BD08-4099DD2D3BB7/Documents/WebUploads/uploads.json
DataPersistenceService: Successfully saved 0 uploads
UploadManagementService: Checking for pending uploads from server
DeviceRegistrationService: Attempting to register device
DeviceRegistrationService: Retrieved device token from secure storage
✅ Async security coordinator initialized successfully
✅ Async security services configured successfully
boringssl_context_handle_fatal_alert(2313) [C1.1.1.1:2][0x14e2be000] read alert, level: fatal, description: internal error
boringssl_session_handshake_incomplete(244) [C1.1.1.1:2][0x14e2be000] SSL library error
boringssl_session_handshake_error_print(47) [C1.1.1.1:2][0x14e2be000] Error: 5617517888:error:10000438:SSL routines:OPENSSL_internal:TLSV1_ALERT_INTERNAL_ERROR:/Library/Caches/com.apple.xbs/Sources/boringssl/ssl/tls_record.cc:579:SSL alert number 80
nw_protocol_boringssl_handshake_negotiate_proceed(788) [C1.1.1.1:2][0x14e2be000] handshake failed at state 12288: not completed
nw_endpoint_flow_failed_with_error [C1.1.1.1 84.32.84.32:443 in_progress channel-flow (satisfied (Path is satisfied), viable, interface: en0[802.11], ipv4, dns, uses wifi)] already failing, returning
nw_endpoint_flow_failed_with_error [C1.1.1.1 84.32.84.32:443 cancelled channel-flow ((null))] already failing, returning
Connection 1: received failure notification
Connection 1: failed to connect 3:-9838, reason -1
Connection 1: encountered error(3:-9838)
Task <5991D5A5-199E-4026-B434-FCE1A3374DB6>.<1> HTTP load failed, 0/0 bytes (error code: -1200 [3:-9838])
Task <5991D5A5-199E-4026-B434-FCE1A3374DB6>.<1> finished with error [-1200] Error Domain=NSURLErrorDomain Code=-1200 "An SSL error has occurred and a secure connection to the server cannot be made." UserInfo={NSErrorFailingURLStringKey=https://payslipmax.com/api/uploads/pending, NSLocalizedRecoverySuggestion=Would you like to connect to the server anyway?, _kCFStreamErrorDomainKey=3, _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <5991D5A5-199E-4026-B434-FCE1A3374DB6>.<1>, _NSURLErrorRelatedURLSessionTaskErrorKey=(
    "LocalDataTask <5991D5A5-199E-4026-B434-FCE1A3374DB6>.<1>"
), NSLocalizedDescription=An SSL error has occurred and a secure connection to the server cannot be made., NSErrorFailingURLKey=https://payslipmax.com/api/uploads/pending, NSUnderlyingError=0x14ed40690 {Error Domain=kCFErrorDomainCFNetwork Code=-1200 "(null)" UserInfo={_kCFStreamPropertySSLClientCertificateState=0, _kCFNetworkCFStreamSSLErrorOriginalValue=-9838, _kCFStreamErrorDomainKey=3, _kCFStreamErrorCodeKey=-9838, _NSURLErrorNWPathKey=satisfied (Path is satisfied), viable, interface: en0[802.11], ipv4, dns, uses wifi}}, _kCFStreamErrorCodeKey=-9838}
UploadManagementService: Failed to get device token or check for pending uploads: Error Domain=NSURLErrorDomain Code=-1200 "An SSL error has occurred and a secure connection to the server cannot be made." UserInfo={NSErrorFailingURLStringKey=https://payslipmax.com/api/uploads/pending, NSLocalizedRecoverySuggestion=Would you like to connect to the server anyway?, _kCFStreamErrorDomainKey=3, _NSURLErrorFailingURLSessionTaskErrorKey=LocalDataTask <5991D5A5-199E-4026-B434-FCE1A3374DB6>.<1>, _NSURLErrorRelatedURLSessionTaskErrorKey=(
    "LocalDataTask <5991D5A5-199E-4026-B434-FCE1A3374DB6>.<1>"
), NSLocalizedDescription=An SSL error has occurred and a secure connection to the server cannot be made., NSErrorFailingURLKey=https://payslipmax.com/api/uploads/pending, NSUnderlyingError=0x14ed40690 {Error Domain=kCFErrorDomainCFNetwork Code=-1200 "(null)" UserInfo={_kCFStreamPropertySSLClientCertificateState=0, _kCFNetworkCFStreamSSLErrorOriginalValue=-9838, _kCFStreamErrorDomainKey=3, _kCFStreamErrorCodeKey=-9838, _NSURLErrorNWPathKey=satisfied (Path is satisfied), viable, interface: en0[802.11], ipv4, dns, uses wifi}}, _kCFStreamErrorCodeKey=-9838}
[PayslipParserRegistry] Registered new parser: VisionPayslipParser
[PayslipParserRegistry] Registered new parser: PageAwareParser
[PayslipParserRegistry] Registered new parser: PCDAPayslipParser
[LiteRTModelManager] LiteRTModelManager initialized
[LiteRTModelManager] Failed to load model metadata: Error Domain=NSCocoaErrorDomain Code=260 "The file “model_metadata.json” couldn’t be opened because there is no such file." UserInfo={NSFilePath=/private/var/containers/Bundle/Application/5BA63D34-B580-4F6C-AC01-6FF232F349F3/PayslipMax.app/Models/model_metadata.json, NSURL=file:///private/var/containers/Bundle/Application/5BA63D34-B580-4F6C-AC01-6FF232F349F3/PayslipMax.app/Models/model_metadata.json, NSUnderlyingError=0x14ed426a0 {Error Domain=NSPOSIXErrorDomain Code=2 "No such file or directory"}}
[LiteRTModelManager] Default model metadata created
[LiteRTService] Initializing LiteRT service
DataService: Refreshed fetch returned 5 items
PayslipDataHandler: Loaded 5 payslips
ℹ️ [INFO] [PDFManager] PDF directory is writable - PDFManager.swift:57 in checkAndCreatePDFDirectory()
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
HomeViewModel: Data loading completed successfully
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