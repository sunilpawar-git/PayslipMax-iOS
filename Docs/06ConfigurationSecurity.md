# Implementation Plan: Configuration & Security Improvements

Comprehensive plan to address configuration defaults, security, and technical debt identified during LLM integration debugging.

---

## Execution Guidelines

> [!IMPORTANT]
> **Strict Quality Standards**: Each phase MUST meet all criteria before proceeding to the next phase.

### Phase Completion Criteria

**Build Verification** (MANDATORY):
- ✅ `xcodebuild clean build -scheme PayslipMax` succeeds with **ZERO** errors
- ✅ **ZERO** build warnings introduced (existing warnings acceptable)
- ✅ Pre-commit hooks pass (line limits, MVVM compliance, async checks)

**Testing Requirements** (MANDATORY):
- ✅ ALL existing unit tests pass (`xcodebuild test`)
- ✅ NEW unit tests added for new functionality (100% coverage of new code)
- ✅ Integration tests pass (if applicable)
- ✅ No flaky tests introduced

**Architecture Compliance** (MANDATORY):
- ✅ **MVVM**: Views don't contain business logic, ViewModels testable
- ✅ **SOLID**: Single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion
- ✅ **DI**: All dependencies injected via protocols, no direct instantiation
- ✅ **Async**: All I/O operations use async/await, no blocking calls on main thread

**Code Quality** (MANDATORY):
- ✅ **Zero Tech Debt**: No TODOs, FIXMEs, or temporary solutions
- ✅ **Logging**: All significant actions logged with os.Logger
- ✅ **Error Handling**: All error paths handled gracefully
- ✅ **Documentation**: Public APIs documented with doc comments

**Security** (MANDATORY):
- ✅ No sensitive data in UserDefaults (use Keychain for secrets)
- ✅ No hardcoded credentials in code
- ✅ API keys not exposed in app binary
- ✅ PII redacted before logging

**Apple Guidelines** (MANDATORY):
- ✅ Human Interface Guidelines followed
- ✅ App Store Review Guidelines compliance
- ✅ Accessibility: VoiceOver support, Dynamic Type
- ✅ Privacy: Info.plist descriptions for permissions

### Phase Workflow

**For Each Phase**:
1. 📝 Create implementation task.md checklist
2. 🔨 Implement changes incrementally
3. 🧪 Write unit tests FIRST (TDD where applicable)
4. ✅ Verify build succeeds
5. ✅ Run all tests
6. 📊 Check code coverage (new code >80%)
7. 🔍 Security review
8. 📚 Update documentation
9. ✅ Verify all quality criteria above
10. 💾 Commit with descriptive message
11. 🚀 Push to GitHub
12. ⏭️ Proceed to next phase ONLY if all criteria met

---

## User Review Required

> [!IMPORTANT]
> **Phase 3 (Backend Proxy)** requires significant backend development and infrastructure decisions. Review the approach before proceeding.

> [!WARNING]
> **API Key Security**: Current hardcoded API key in the app is a security risk for production. Phase 3 must be completed before public release.

---

## Phase 1: Quick Fixes & Cleanup (Immediate)

**Goal**: Remove errors from console logs and fix immediate issues
**Duration**: ~1-2 hours
**Priority**: HIGH

### 1.1 Disable Web Upload Feature
**Files to modify**:
- [FeatureContainer.swift](file:///Users/sunil/Downloads/PayslipMax/PayslipMax/Core/DI/Containers/FeatureContainer.swift)
- Search for: `WebUploadCoordinator` initialization
- Search for: `payslipmax.com` references

**Changes**:
```swift
// Comment out WebUploadCoordinator initialization
// let webUploadCoordinator = WebUploadCoordinator(baseURL: "https://payslipmax.com/api")

// Disable upload management service
// uploadManagementService.checkForPendingUploads()
```

**Verification**:
```bash
# Clean build
xcodebuild clean build -scheme PayslipMax -destination 'generic/platform=iOS' -quiet

# Run all tests
xcodebuild test -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 15'

# Check for web upload references
grep -r "payslipmax.com" PayslipMax/ || echo "✅ No references found"
grep -r "WebUploadCoordinator" PayslipMax/ | grep -v "//" || echo "✅ Commented out"
```

**Quality Gates**:
- ✅ Build succeeds with ZERO errors
- ✅ No TLS/SSL errors in console logs
- ✅ App launches without backend connectivity errors
- ✅ No new warnings introduced
- ✅ All existing tests pass
- ✅ Web upload feature cleanly disabled (commented, not deleted)
- ✅ Git commit with clear message

### 1.2 Investigate Missing Pay Codes
**Files to check**:
- [military_pay_codes.json](file:///Users/sunil/Downloads/PayslipMax/PayslipMax/Resources/military_pay_codes.json)
- [PayCodePatternGenerator.swift](file:///Users/sunil/Downloads/PayslipMax/PayslipMax/Services/Processing/Patterns/PayCodePatternGenerator.swift)

**Investigation steps**:
1. Count pay codes in JSON: Expected 267, currently 243
2. Identify missing 24 codes (21 from warning + 3 manual codes)
3. Determine if missing codes are:
   - Intentionally excluded (legacy/deprecated)
   - Need to be added to JSON
   - Calculation error in expected count

**Verification**:
```bash
# Count pay codes in JSON
jq 'length' PayslipMax/Resources/military_pay_codes.json

# Search for expected count in code
grep -r "267" PayslipMax/Services/Processing/

# Run validation
xcodebuild clean build -scheme PayslipMax 2>&1 | grep "SEARCH SYSTEM"
```

**Quality Gates**:
- ✅ Investigation documented in Docs/06ConfigurationSecurity.md
- ✅ Root cause identified and explained
- ✅ Either: Warning fixed OR documented as expected
- ✅ Build succeeds
- ✅ All tests pass
- ✅ Git commit with investigation results

---

## Phase 2: Development Infrastructure (Configuration & Logging)

**Goal**: Improve developer experience and prevent future configuration bugs
**Duration**: ~2-3 hours
**Priority**: MEDIUM

### 2.1 Implement Build Configuration Defaults

**Files to create/modify**:
- **[NEW]** `PayslipMax/Config/BuildConfiguration.swift`
- [LLMRateLimitConfiguration.swift](file:///Users/sunil/Downloads/PayslipMax/PayslipMax/Services/Processing/LLM/LLMRateLimitConfiguration.swift)
- [LLMSettingsService.swift](file:///Users/sunil/Downloads/PayslipMax/PayslipMax/Services/Processing/LLM/LLMSettingsService.swift)

**Implementation**:

#### Create BuildConfiguration.swift
```swift
import Foundation

enum BuildConfiguration {
    #if DEBUG
    static let isDebug = true
    static let llmEnabledByDefault = true
    static let rateLimitEnabled = false
    static let maxCallsPerYear = 999999
    static let logLevel: LogLevel = .verbose
    #else
    static let isDebug = false
    static let llmEnabledByDefault = false  // Require user opt-in
    static let rateLimitEnabled = true
    static let maxCallsPerYear = 50
    static let logLevel: LogLevel = .info
    #endif

    enum LogLevel {
        case verbose, info, warning, error
    }
}
```

#### Update LLMRateLimitConfiguration.swift
```swift
static let `default` = LLMRateLimitConfiguration(
    maxCallsPerHour: 5,
    maxCallsPerYear: BuildConfiguration.maxCallsPerYear,
    minDelaySeconds: BuildConfiguration.isDebug ? 0 : 10,
    isEnabled: BuildConfiguration.rateLimitEnabled
)
```

#### Update LLMSettingsService.swift
```swift
var isLLMEnabled: Bool {
    get {
        if userDefaults.object(forKey: Keys.isLLMEnabled) == nil {
            return BuildConfiguration.llmEnabledByDefault
        }
        return userDefaults.bool(forKey: Keys.isLLMEnabled)
    }
    set { userDefaults.set(newValue, forKey: Keys.isLLMEnabled) }
}
```

**Verification**:
```bash
# Build Debug configuration
xcodebuild clean build -scheme PayslipMax -configuration Debug -destination 'generic/platform=iOS'

# Build Release configuration
xcodebuild clean build -scheme PayslipMax -configuration Release -destination 'generic/platform=iOS'

# Run unit tests for BuildConfiguration
xcodebuild test -scheme PayslipMax -only-testing:PayslipMaxTests/BuildConfigurationTests

# Verify no hardcoded values in wrong places
grep -r "maxCallsPerYear = 999999" PayslipMax/ | grep -v BuildConfiguration || echo "✅ Only in BuildConfiguration"
```

**Quality Gates**:
- ✅ **Build**: Debug AND Release configurations both succeed
- ✅ **Tests**: New unit tests for BuildConfiguration (100% coverage)
- ✅ **Architecture**: BuildConfiguration is dependency-free enum (SOLID)
- ✅ **Debug mode**: LLM enabled by default, rate limits disabled, verbose logging
- ✅ **Release mode**: LLM disabled by default, rate limits enabled, minimal logging
- ✅ **DI**: LLMRateLimitConfiguration uses BuildConfiguration via dependency injection
- ✅ **Zero Tech Debt**: No TODOs or temporary solutions
- ✅ **Documentation**: BuildConfiguration has doc comments explaining each value
- ✅ **Git commit**: "feat: Add build configuration defaults for Debug/Release"

---

### 2.2 Add First-Run Initialization

**Files to create/modify**:
- **[NEW]** `PayslipMax/Core/Initialization/FirstRunService.swift`
- [PayslipMaxApp.swift](file:///Users/sunil/Downloads/PayslipMax/PayslipMax/PayslipMaxApp.swift)

**Implementation**:

#### Create FirstRunService.swift
```swift
final class FirstRunService {
    private let userDefaults: UserDefaults
    private let logger = os.Logger(subsystem: "com.payslipmax", category: "FirstRun")

    private enum Keys {
        static let hasLaunchedBefore = "app_has_launched_before"
        static let appVersion = "app_version_on_first_launch"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func performFirstRunSetupIfNeeded() {
        guard !hasLaunchedBefore else {
            logger.info("Not first launch, skipping initialization")
            return
        }

        logger.info("🚀 First launch detected - initializing defaults")

        // Set configuration defaults
        initializeLLMDefaults()
        initializeFeatureFlagDefaults()
        initializeAnalyticsDefaults()

        // Mark as launched
        userDefaults.set(true, forKey: Keys.hasLaunchedBefore)
        userDefaults.set(appVersion, forKey: Keys.appVersion)

        logger.info("✅ First run initialization complete")
    }

    private var hasLaunchedBefore: Bool {
        userDefaults.bool(forKey: Keys.hasLaunchedBefore)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func initializeLLMDefaults() {
        let llmService = DIContainer.shared.makeLLMSettingsService()
        // First launch uses build configuration defaults
        llmService.isLLMEnabled = BuildConfiguration.llmEnabledByDefault
    }

    private func initializeFeatureFlagDefaults() {
        // Set any feature flag defaults for first launch
    }

    private func initializeAnalyticsDefaults() {
        // Set analytics preferences
    }
}
```

#### Update PayslipMaxApp.swift
```swift
init() {
    // ... existing code ...

    // Perform first-run setup
    let firstRunService = FirstRunService()
    firstRunService.performFirstRunSetupIfNeeded()
}
```

**Verification**:
```bash
# Run unit tests for FirstRunService
xcodebuild test -scheme PayslipMax -only-testing:PayslipMaxTests/FirstRunServiceTests

# Integration test: Fresh install
# 1. Delete app from simulator
# 2. Install and launch
# 3. Check logs for "🚀 First launch detected"
# 4. Verify LLM defaults set correctly

# Integration test: Second launch
# 1. Relaunch app
# 2. Check logs for "Not first launch, skipping initialization"
```

**Quality Gates**:
- ✅ **Build**: Succeeds with ZERO errors
- ✅ **Tests**: Unit tests for FirstRunService (TDD approach)
  - Test: First launch triggers initialization
  - Test: Second launch skips initialization
  - Test: Version is stored correctly
  - Test: Defaults are set correctly
- ✅ **Architecture**:
  - Protocol-based (FirstRunServiceProtocol for DI)
  - Dependencies injected (UserDefaults injectable for testing)
  - Single Responsibility (only handles first-run setup)
- ✅ **Async**: Uses synchronous UserDefaults (appropriate for this use case)
- ✅ **Logging**: All actions logged with os.Logger
- ✅ **Integration**: PayslipMaxApp.init() calls FirstRunService
- ✅ **Zero Tech Debt**: Clean implementation, no TODOs
- ✅ **Git commit**: "feat: Add first-run initialization service"

---

### 2.3 Add Startup Configuration Logging

**Files to modify**:
- [PayslipMaxApp.swift](file:///Users/sunil/Downloads/PayslipMax/PayslipMax/PayslipMaxApp.swift)
- **[NEW]** `PayslipMax/Core/Diagnostics/StartupDiagnostics.swift`

**Implementation**:

#### Create StartupDiagnostics.swift
```swift
final class StartupDiagnostics {
    private let logger = os.Logger(subsystem: "com.payslipmax", category: "Startup")

    func logConfiguration() {
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.info("🚀 PayslipMax Startup Configuration")
        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        logBuildInfo()
        logLLMConfiguration()
        logFeatureFlags()
        logStorageInfo()

        logger.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    private func logBuildInfo() {
        let isDebug = BuildConfiguration.isDebug
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        logger.info("📱 Build: \(isDebug ? "DEBUG" : "RELEASE") v\(version) (\(build))")
    }

    private func logLLMConfiguration() {
        let llmService = DIContainer.shared.makeLLMSettingsService()
        let rateLimiter = LLMRateLimiter()

        logger.info("🤖 LLM Configuration:")
        logger.info("  • Enabled: \(llmService.isLLMEnabled)")
        logger.info("  • Provider: \(llmService.selectedProvider.rawValue)")
        logger.info("  • Backup Mode: \(llmService.useAsBackupOnly)")
        logger.info("  • Rate Limiting: \(rateLimiter.getCurrentConfiguration().isEnabled)")
        logger.info("  • Yearly Limit: \(rateLimiter.getCurrentConfiguration().maxCallsPerYear)")
    }

    private func logFeatureFlags() {
        logger.info("🚩 Feature Flags: All hardcoded to enabled (dev mode)")
    }

    private func logStorageInfo() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        logger.info("💾 Storage: \(documentsPath?.path ?? "Unknown")")
    }
}
```

#### Update PayslipMaxApp.swift
```swift
init() {
    // ... existing first-run setup ...

    // Log startup configuration (Debug builds only for performance)
    #if DEBUG
    StartupDiagnostics().logConfiguration()
    #endif
}
```

**Verification**:
```bash
# Test Debug build logging
xcodebuild clean build -scheme PayslipMax -configuration Debug
# Launch app and check console for startup logs

# Test Release build logging
xcodebuild clean build -scheme PayslipMax -configuration Release
# Verify startup logs are minimal/absent

# Run unit tests
xcodebuild test -scheme PayslipMax -only-testing:PayslipMaxTests/StartupDiagnosticsTests
```

**Quality Gates**:
- ✅ **Build**: Both Debug and Release succeed
- ✅ **Tests**: Unit tests for StartupDiagnostics
  - Mock dependencies for testing
  - Verify correct information logged
  - Test Debug vs Release behavior
- ✅ **Architecture**:
  - Protocol-based for testability
  - Dependencies injected (DIContainer)
  - Follows Single Responsibility
- ✅ **Performance**: Startup time impact <50ms (measured)
- ✅ **Logging**: Uses os.Logger consistently
- ✅ **Security**: No sensitive data in logs (API keys redacted)
- ✅ **Debug only**: #if DEBUG guard prevents Release logging
- ✅ **Git commit**: "feat: Add startup configuration diagnostics"

---

### 2.4 UI Visibility Checklist

**Files to create**:
- **[NEW]** `.agent/checklists/feature-checklist.md`

**Content**:
```markdown
# Feature Shipping Checklist

Before marking a feature as complete:

## Configuration
- [ ] Feature has sensible defaults for Debug builds
- [ ] Feature has sensible defaults for Release builds
- [ ] First-run initialization sets defaults correctly
- [ ] Settings persist across app restarts

## User Interface
- [ ] Feature has UI access point (if user-facing)
- [ ] Settings screen includes feature controls
- [ ] Feature is documented in Help/Support
- [ ] Debug/production modes are visually distinct (if applicable)

## Testing
- [ ] Unit tests cover configuration logic
- [ ] UI tests verify settings accessibility
- [ ] Tested on fresh install
- [ ] Tested after app update

## Logging & Diagnostics
- [ ] Startup configuration is logged (Debug builds)
- [ ] Feature state changes are logged
- [ ] Error paths are logged with context

## Security & Privacy
- [ ] No sensitive data in UserDefaults
- [ ] API keys not hardcoded (if applicable)
- [ ] Privacy policy updated (if needed)
```

**Verification**:
- ✅ Checklist exists in `.agent/checklists/`
- ✅ Team reviews checklist before shipping features

---

## Phase 3: Production Security (Backend Proxy)

**Goal**: Secure API key and enable production-ready LLM usage
**Duration**: 1-2 weeks (backend + client implementation)
**Priority**: CRITICAL for production release

> [!WARNING]
> **Blocking for production release**. Must be completed before publishing app.

### 3.1 Backend API Design

**Tech Stack Decision**:
- Option A: Node.js/Express (lightweight, fast iteration)
- Option B: Python/FastAPI (if existing Python infrastructure)
- Option C: Firebase Cloud Functions (serverless, no infra management)

**Recommended**: Firebase Cloud Functions (easiest for MVP)

**API Endpoints**:

#### POST /api/llm/parse
**Request**:
```json
{
  "text": "redacted payslip text...",
  "userId": "user-uuid",
  "deviceId": "device-uuid"
}
```

**Response**:
```json
{
  "success": true,
  "result": {
    "earnings": [...],
    "deductions": [...],
    "metadata": {...}
  },
  "tokensUsed": 2205,
  "confidence": 0.95
}
```

**Security**:
- Authenticate requests via App Attest or device token
- Rate limit per user (e.g., 5 calls/hour, 50/year)
- Log all requests for abuse monitoring
- Validate request size (<100KB)

---

### 3.2 Backend Implementation (Firebase Functions)

**Files to create** (in new `/backend` directory):

#### backend/functions/index.js
```javascript
const functions = require('firebase-functions');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const admin = require('firebase-admin');

admin.initializeApp();

const genAI = new GoogleGenerativeAI(functions.config().gemini.key);

exports.parseLLM = functions.https.onCall(async (data, context) => {
  // Authenticate
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;

  // Rate limiting
  const userDoc = await admin.firestore().collection('usage').doc(userId).get();
  const usage = userDoc.data() || { count: 0, month: new Date().getMonth() };

  if (usage.count >= 50) {
    throw new functions.https.HttpsError('resource-exhausted', 'Monthly limit reached');
  }

  // Call Gemini
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  const result = await model.generateContent(data.prompt);

  // Update usage
  await admin.firestore().collection('usage').doc(userId).set({
    count: usage.count + 1,
    month: new Date().getMonth(),
    lastUsed: admin.firestore.FieldValue.serverTimestamp()
  });

  return {
    success: true,
    result: result.response.text(),
    tokensUsed: result.response.usageMetadata.totalTokenCount
  };
});
```

#### backend/functions/package.json
```json
{
  "dependencies": {
    "firebase-functions": "^4.0.0",
    "firebase-admin": "^11.0.0",
    "@google/generative-ai": "^0.1.0"
  }
}
```

**Deployment**:
```bash
cd backend/functions
npm install
firebase deploy --only functions
```

**Verification**:
```bash
# Backend deployment
cd backend/functions
npm install
npm test  # Run backend unit tests
firebase deploy --only functions

# Test from Firebase console
# Call parseLLM with test data
# Verify response structure

# Test rate limiting
# Make 51 requests in succession
# Verify 51st request fails with "resource-exhausted"
```

**Quality Gates**:
- ✅ **Backend Tests**: Node.js unit tests pass (100% coverage)
- ✅ **Deployment**: Firebase function deploys without errors
- ✅ **Authentication**: Unauthenticated requests rejected
- ✅ **Rate Limiting**: Enforced correctly (50/month per user)
- ✅ **Error Handling**: All errors return proper HttpsError types
- ✅ **Security**:
  - API key stored in Firebase config (not in code)
  - User ID validated
  - Request size limits enforced
- ✅ **Monitoring**: Firebase console shows function metrics
- ✅ **Documentation**: Backend README.md with setup instructions
- ✅ **Git commit**: "feat: Add Firebase Cloud Function for LLM proxy"

---

### 3.3 iOS Client Implementation

**Files to modify**:
- **[NEW]** `PayslipMax/Services/Processing/LLM/Backend/LLMBackendService.swift`
- [LLMPayslipParser.swift](file:///Users/sunil/Downloads/PayslipMax/PayslipMax/Services/Processing/LLM/LLMPayslipParser.swift)
- [APIKeys.swift](file:///Users/sunil/Downloads/PayslipMax/PayslipMax/Config/APIKeys.swift)

**Implementation**:

#### Create LLMBackendService.swift
```swift
protocol LLMBackendServiceProtocol {
    func parsePayslip(text: String) async throws -> LLMParseResponse
}

final class LLMBackendService: LLMBackendServiceProtocol {
    private let logger = os.Logger(subsystem: "com.payslipmax.llm", category: "Backend")

    func parsePayslip(text: String) async throws -> LLMParseResponse {
        // Call Firebase Cloud Function
        let functions = Functions.functions()
        let callable = functions.httpsCallable("parseLLM")

        let data = ["prompt": text]
        let result = try await callable.call(data)

        guard let response = result.data as? [String: Any] else {
            throw LLMError.invalidResponse
        }

        return try parseLLMResponse(response)
    }
}
```

#### Update LLMPayslipParser.swift
```swift
// Add backend mode
private func callLLM(prompt: String) async throws -> String {
    if BuildConfiguration.useBackendProxy {
        // Use backend proxy (production)
        let backendService = LLMBackendService()
        let response = try await backendService.parsePayslip(text: prompt)
        return response.result
    } else {
        // Direct API call (development only)
        return try await geminiService.generateText(prompt: prompt)
    }
}
```

#### Update BuildConfiguration.swift
```swift
#if DEBUG
static let useBackendProxy = false  // Direct API for development
#else
static let useBackendProxy = true   // Backend proxy for production
#endif
```

**Verification**:
```bash
# iOS client tests
xcodebuild test -scheme PayslipMax -only-testing:PayslipMaxTests/LLMBackendServiceTests

# Integration test: Debug mode
# 1. Build in Debug
# 2. Upload payslip
# 3. Verify logs show "Using direct Gemini API"

# Integration test: Release mode
# 1. Build in Release
# 2. Upload payslip
# 3. Verify logs show "Using backend proxy"

# Test error handling
# 1. Disable network
# 2. Upload payslip
# 3. Verify graceful fallback to regex
```

**Quality Gates**:
- ✅ **Build**: Debug and Release both succeed
- ✅ **Tests**: Comprehensive unit tests
  - LLMBackendService tests (mocked Firebase)
  - LLMPayslipParser tests (backend mode)
  - Error handling tests
  - Network failure tests
- ✅ **Architecture**:
  - LLMBackendServiceProtocol for DI
  - Async/await for all network calls
  - Error types properly defined
- ✅ **Security**:
  - No API key in iOS app binary (verified with `strings`)
  - PII redacted before backend send
  - Firebase auth tokens handled securely
- ✅ **UX**: Loading states, error messages
- ✅ **Performance**: Backend latency <3 seconds
- ✅ **Accessibility**: Error messages accessible
- ✅ **Zero Tech Debt**: Clean implementation
- ✅ **Git commit**: "feat: Add backend proxy support for LLM"

---

## Phase 4: Quality & Verification

**Goal**: Ensure all changes are production-ready
**Duration**: 1-2 hours
**Priority**: HIGH

### 4.1 Testing Checklist

**Unit Tests**:
- [ ] BuildConfiguration returns correct values for Debug/Release
- [ ] FirstRunService initializes defaults correctly
- [ ] LLMBackendService handles errors gracefully
- [ ] Rate limiting works via backend

**Integration Tests**:
- [ ] Fresh install sets correct defaults
- [ ] App update preserves user settings
- [ ] LLM parsing works via backend proxy
- [ ] Offline mode falls back to regex

**UI Tests**:
- [ ] LLM Settings visible in Settings → Developer Tools
- [ ] Can toggle LLM on/off (reflects in backend calls)
- [ ] Error messages shown for rate limit exceeded

### 4.2 Performance Verification

**Metrics to check**:
- App launch time: <2 seconds
- Backend latency: <3 seconds for LLM parse
- Memory usage: Stable after configuration logging

### 4.3 Security Audit

**Checklist**:
- [ ] No API keys in app binary (use `strings PayslipMax | grep AIza`)
- [ ] Backend authenticates all requests
- [ ] Rate limiting cannot be bypassed
- [ ] PII properly redacted before backend send

---

## Verification Plan

### Automated Tests
```bash
# Run all unit tests
xcodebuild test -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 15'

# Check for hardcoded API keys
strings PayslipMax.app/PayslipMax | grep -E "(AIza|sk-)"
```

### Manual Verification

**Debug Build**:
1. Fresh install on simulator
2. Verify startup logs show configuration
3. Upload payslip → should use direct API
4. Check LLM Settings accessible

**Release Build**:
1. Archive and export
2. Install .ipa on TestFlight
3. Verify startup logs minimal
4. Upload payslip → should use backend proxy
5. Verify rate limiting enforced

---

## Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Phase 1: Quick Fixes | 1-2 hours | None |
| Phase 2: Dev Infrastructure | 2-3 hours | Phase 1 complete |
| Phase 3: Backend Proxy | 1-2 weeks | Backend deployed, Firebase setup |
| Phase 4: Quality | 1-2 hours | All phases complete |

**Total**: ~2-3 weeks (including backend development)

**Priority for immediate work**:
1. ✅ Phase 1.1 (Disable web upload) - **Do today**
2. ✅ Phase 1.2 (Investigate pay codes) - **Do this week**
3. Phase 2 (Dev infrastructure) - **Do this week**
4. Phase 3 (Backend proxy) - **Before production release**
