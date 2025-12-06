# PayslipMax - Development Guide for Claude

> **Last Updated**: December 2, 2025
> **Project**: PayslipMax iOS Application
> **Purpose**: Comprehensive guide for Claude Code development and architecture understanding

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [API Key Architecture](#api-key-architecture)
3. [Security Protocols](#security-protocols)
4. [Build Configurations](#build-configurations)
5. [Development Workflow](#development-workflow)
6. [Testing Strategy](#testing-strategy)
7. [Common Tasks](#common-tasks)

---

## Project Overview

**PayslipMax** is an iOS application for parsing military payslips using:
- **Regex-based parsing** (Universal Payslip Processor)
- **LLM-based parsing** (Gemini AI as fallback)
- **Hybrid processing** (Regex first, LLM fallback on low confidence)

### Key Technologies
- **Language**: Swift 6.0+ (iOS 18.1+)
- **Architecture**: MVVM + SwiftUI
- **Dependency Injection**: Protocol-based DI
- **Async**: Swift Concurrency (async/await)
- **Backend**: Firebase Cloud Functions (Node.js)
- **LLM**: Google Gemini API

### Premium Features
- **X-Ray Salary** (v1.0 - December 2025)
  - Visual month-to-month payslip comparisons
  - Smart change indicators (green/red tints, arrows)
  - "Needs attention" highlights for decreased earnings/increased deductions
  - Comparison modal for detailed change analysis
  - Thread-safe caching for performance
  - 100% test coverage
  - **Documentation**: `/Documentation/Features/XRaySalary.md`

---

## API Key Architecture

### Overview

PayslipMax uses **two distinct approaches** for API key management based on build configuration:

| Environment | Build Config | API Key Location | API Calls | Rate Limiting | Authentication |
|-------------|--------------|------------------|-----------|---------------|----------------|
| **Development** | DEBUG | Xcode Scheme (user-specific) | Direct to Gemini API | Disabled (unlimited) | Not required |
| **Production** | RELEASE | Firebase Secrets (backend only) | Via Firebase Cloud Function | Enabled (5/hr, 50/yr) | Google Sign-In required |

### Development Environment (DEBUG)

#### Key Storage
- **Location**: Xcode scheme environment variable
- **File**: `xcuserdata/<username>/xcschemes/PayslipMax.xcscheme`
- **Git Status**: ❌ **Not tracked** (in `.gitignore`)

#### Setup Instructions
1. Open `PayslipMax.xcworkspace` in Xcode
2. Click scheme dropdown → **Edit Scheme...**
3. Select **Run** → **Arguments** tab
4. Under **Environment Variables**, add:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: `AIzaSy...` (your development key)
   - ✅ Check "Active"
5. ❌ **Uncheck "Shared"** (critical for security)
6. Click **Close**

#### Code Integration
```swift
// Config/APIKeys.swift (gitignored)
struct APIKeys {
    static let geminiAPIKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "YOUR_GEMINI_API_KEY_HERE"

    static var isGeminiConfigured: Bool {
        return !geminiAPIKey.isEmpty &&
               geminiAPIKey != "YOUR_GEMINI_API_KEY_HERE" &&
               geminiAPIKey.hasPrefix("AIza")
    }
}
```

#### Architecture Flow
```
User uploads payslip
  ↓
Regex parsing (Universal Processor)
  ↓
Quality check failed? (Totals mismatch)
  ↓
YES → LLM fallback triggered
  ↓
Check BuildConfiguration.useBackendProxy
  ↓
FALSE (DEBUG) → Direct Gemini API call
  ↓
GeminiLLMService.send(request)
  ↓
HTTPS POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key={APIKeys.geminiAPIKey}
  ↓
Parse response → Return to user
```

### Production Environment (RELEASE)

#### Key Storage
- **Location**: Firebase Secrets (backend infrastructure)
- **Access**: Firebase Cloud Function only
- **Git Status**: ❌ **Never in git** (server-side only)

#### Setup Instructions
```bash
# Backend deployment (one-time setup)
cd backend/functions
npm install

# Set Firebase secret (stored securely in GCP)
firebase functions:config:set gemini.key="YOUR_PRODUCTION_GEMINI_API_KEY"

# Deploy backend
firebase deploy --only functions

# Verify secret is set
firebase functions:config:get gemini
```

#### Code Integration - iOS
```swift
// PayslipMax/Services/Processing/LLM/Backend/LLMBackendService.swift
final class LLMBackendService: LLMBackendServiceProtocol {
    private lazy var functions = Functions.functions()

    func parsePayslip(text: String) async throws -> String {
        // Authenticate user
        guard Auth.auth().currentUser != nil else {
            throw LLMError.authenticationRequired
        }

        // Call Cloud Function (no API key in iOS app)
        let callable = functions.httpsCallable("parseLLM")
        let result = try await callable.call(["prompt": text])

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool,
              success,
              let resultText = data["result"] as? String else {
            throw LLMError.invalidResponse
        }

        return resultText
    }
}
```

#### Code Integration - Backend
```javascript
// backend/functions/index.js
const functions = require('firebase-functions');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const admin = require('firebase-admin');

admin.initializeApp();

// Lazy initialization - API key from Firebase Secrets
let genAI = null;

const getGenAI = () => {
    if (!genAI) {
        const apiKey = process.env.GEMINI_API_KEY; // From Firebase Secrets
        if (!apiKey) {
            throw new Error('GEMINI_API_KEY environment variable not set');
        }
        genAI = new GoogleGenerativeAI(apiKey);
    }
    return genAI;
};

exports.parseLLM = functions.https.onCall(async (data, context) => {
    // 1. Authenticate
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid;

    // 2. Rate limiting
    const db = admin.firestore();
    const usageRef = db.collection('llm_usage').doc(userId);
    const usageDoc = await usageRef.get();

    let usage = usageDoc.exists ? usageDoc.data() : {
        yearlyCount: 0, hourlyCount: 0, monthlyCount: 0, totalCount: 0
    };

    // Check limits (production only - skip in emulator)
    if (!process.env.FUNCTIONS_EMULATOR) {
        if (usage.yearlyCount >= 50) {
            throw new functions.https.HttpsError('resource-exhausted', 'Yearly limit of 50 LLM calls reached');
        }
        if (usage.hourlyCount >= 5) {
            throw new functions.https.HttpsError('resource-exhausted', 'Hourly limit of 5 LLM calls reached');
        }
    }

    // 3. Call Gemini API (backend has the key)
    const model = getGenAI().getGenerativeModel({
        model: 'gemini-2.0-flash-exp',
        generationConfig: {
            temperature: 0.0,
            maxOutputTokens: 1000
        }
    });

    const result = await model.generateContent(data.prompt);
    const response = result.response;
    const text = response.text();
    const tokensUsed = response.usageMetadata?.totalTokenCount || 0;

    // 4. Update usage tracking
    await usageRef.set({
        yearlyCount: usage.yearlyCount + 1,
        hourlyCount: usage.hourlyCount + 1,
        monthlyCount: usage.monthlyCount + 1,
        totalCount: (usage.totalCount || 0) + 1,
        lastUsed: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    // 5. Return response
    return {
        success: true,
        result: text,
        tokensUsed: tokensUsed,
        remainingCalls: {
            hourly: Math.max(0, 5 - (usage.hourlyCount + 1)),
            yearly: Math.max(0, 50 - (usage.yearlyCount + 1))
        }
    };
});
```

#### Architecture Flow
```
User uploads payslip
  ↓
Regex parsing (Universal Processor)
  ↓
Quality check failed? (Totals mismatch)
  ↓
YES → LLM fallback triggered
  ↓
Check BuildConfiguration.useBackendProxy
  ↓
TRUE (RELEASE) → Backend proxy call
  ↓
LLMBackendService.parsePayslip(text)
  ↓
Check Firebase Authentication (Google Sign-In required)
  ↓
HTTPS POST to Firebase Cloud Function (parseLLM)
  ↓
Firebase authenticates user (context.auth.uid)
  ↓
Check rate limits in Firestore (llm_usage/{userId})
  ↓
Call Gemini API with secret from Firebase config
  ↓
Update usage tracking in Firestore
  ↓
Return response to iOS app
  ↓
Parse and display to user
```

### Build Configuration Decision Point

```swift
// PayslipMax/Core/Configuration/BuildConfiguration.swift
enum BuildConfiguration {
    #if DEBUG
    static let isDebug = true
    static let useBackendProxy = false        // Direct API
    static let llmEnabledByDefault = true     // Enabled for testing
    static let rateLimitEnabled = false       // Unlimited
    static let maxCallsPerYear = 999999
    static let logLevel: LogLevel = .verbose

    #else  // RELEASE
    static let isDebug = false
    static let useBackendProxy = true         // Backend proxy
    static let llmEnabledByDefault = false    // Requires opt-in
    static let rateLimitEnabled = true        // Enforce limits
    static let maxCallsPerYear = 50           // Strict limit
    static let logLevel: LogLevel = .info
    #endif
}
```

### Key Decision in LLMPayslipParser

```swift
// PayslipMax/Services/Processing/LLM/LLMPayslipParser.swift
private func callLLM(prompt: String) async throws -> String {
    if BuildConfiguration.useBackendProxy {
        // PRODUCTION: Use secure backend proxy
        let backendService = LLMBackendService()
        return try await backendService.parsePayslip(text: prompt)
    } else {
        // DEVELOPMENT: Direct API call
        let request = LLMRequest(
            prompt: prompt,
            systemPrompt: Self.systemPrompt,
            jsonMode: true
        )
        let response = try await service.send(request)
        return response.content
    }
}
```

---

## Security Protocols

### 1. .gitignore Protection

**Purpose**: Prevent sensitive files from being tracked by git

**Critical Entries**:
```gitignore
# API Keys and Secrets - NEVER COMMIT
Config/
Config/APIKeys.swift
APIKeys.swift
GoogleService-Info.plist
google-services.json
*-firebase-adminsdk-*.json

# Xcode user-specific schemes
xcuserdata/
*.xcuserstate
*.xcworkspace/xcuserdata/
*.xcodeproj/xcuserdata/

# Environment variables
.env
.env.local
.env.*.local

# Generic credentials patterns
*secret*
*credential*
*apikey*
*api_key*
*.key
*.pem
credentials.json
secrets.json
```

**Verification**:
```bash
# Verify APIKeys.swift is gitignored
git check-ignore -v Config/APIKeys.swift
# Output: .gitignore:96:Config/	Config/APIKeys.swift

# Verify no API keys in git history
git log --all --full-history --source --pretty=format: --name-only --diff-filter=A | grep -i "APIKeys.swift\|GEMINI_API_KEY\|AIza"
# Output: (empty - no keys in history)
```

### 2. Pre-commit Hook (Secret Detection)

**Purpose**: Automatically prevent accidental commits of API keys

**Location**: `.git/hooks/pre-commit`

**Features**:
- Detects Google API keys (`AIzaSy[A-Za-z0-9_-]{33}`)
- Detects AWS keys (`AKIA[0-9A-Z]{16}`)
- Detects private keys (`-----BEGIN`)
- Detects hardcoded passwords
- Checks GoogleService-Info.plist
- **Blocks commit** if secrets detected

**Test the Hook**:
```bash
# Should pass
echo "normal code" > test.swift
git add test.swift
git commit -m "test"

# Should block
echo "AIzaSyTestKey123456789012345678901234" > test.swift
git add test.swift
git commit -m "test"
# Output: ❌ SECURITY ALERT: Potential secret detected
```

### 3. Code Review Checklist

Before committing any code:

- [ ] No API keys in code (use `grep -r "AIza" PayslipMax/`)
- [ ] No secrets in UserDefaults (use Keychain for sensitive data)
- [ ] Config/APIKeys.swift is gitignored
- [ ] Xcode scheme is **not shared** for environment variables
- [ ] Pre-commit hook is executable (`chmod +x .git/hooks/pre-commit`)
- [ ] Backend secrets are in Firebase config (not in code)

### 4. Key Rotation Protocol

If an API key is accidentally exposed:

1. **Immediate Actions**:
   ```bash
   # Revoke the exposed key immediately
   # Go to https://console.cloud.google.com/apis/credentials
   # Delete the compromised key

   # Create a new key
   # Update local development environment
   export GEMINI_API_KEY="new_key_here"

   # Update Xcode scheme (Edit Scheme → Arguments → Environment Variables)

   # Update Firebase secret (production)
   firebase functions:config:set gemini.key="new_production_key"
   firebase deploy --only functions
   ```

2. **Git History Cleanup** (if key was committed):
   ```bash
   # Use BFG Repo Cleaner or git filter-branch
   # WARNING: This rewrites history - coordinate with team

   bfg --replace-text passwords.txt  # List of keys to remove
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   git push --force
   ```

3. **Post-Incident**:
   - Document the incident
   - Review security protocols
   - Update team training

---

## Build Configurations

### Debug Configuration

**Purpose**: Development and testing

**Characteristics**:
- LLM enabled by default
- Direct Gemini API calls
- No rate limiting
- Verbose logging
- Backend proxy disabled
- Fast iteration

**Use Cases**:
- Local development
- Unit testing
- Integration testing
- Simulator testing
- Quick iterations

### Release Configuration

**Purpose**: Production deployment

**Characteristics**:
- LLM disabled by default (user opt-in)
- Backend proxy required
- Rate limiting enforced (5/hr, 50/yr)
- Minimal logging
- Backend proxy enabled
- Security hardened

**Use Cases**:
- App Store builds
- TestFlight beta
- Production releases

### Switching Configurations

```bash
# Build for Debug
xcodebuild clean build -scheme PayslipMax -configuration Debug

# Build for Release
xcodebuild clean build -scheme PayslipMax -configuration Release

# Archive for App Store
xcodebuild archive -scheme PayslipMax -configuration Release -archivePath build/PayslipMax.xcarchive
```

---

## Development Workflow

### Initial Setup

1. **Clone Repository**:
   ```bash
   git clone <repository-url>
   cd PayslipMax
   ```

2. **Install Dependencies**:
   Dependencies are managed via Swift Package Manager (SPM). Xcode will automatically resolve Firebase packages when you open the project. No manual installation steps needed.

   ```bash
   # Backend (optional for development)
   cd backend/functions
   npm install
   cd ../..
   ```

3. **Configure API Key**:
   - Copy template: `cp Config/APIKeys.template.swift Config/APIKeys.swift`
   - Get Gemini API key: https://makersuite.google.com/app/apikey
   - Option A: Edit `Config/APIKeys.swift` directly (gitignored)
   - Option B: Set Xcode scheme environment variable (recommended)

4. **Open Project**:
   ```bash
   open PayslipMax.xcodeproj
   ```

5. **Verify Setup**:
   - Build: `Cmd + B`
   - Run: `Cmd + R`
   - Check logs for: `🔑 LLM Provider: gemini` and `✅ API Key configured`

### Daily Workflow

1. **Start Development**:
   ```bash
   git checkout development
   git pull origin development
   ```

2. **Create Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**:
   - Edit code in Xcode
   - Run tests: `Cmd + U`
   - Check logs for errors

4. **Test Locally**:
   - Build: `Cmd + B`
   - Run on simulator: `Cmd + R`
   - Test payslip parsing with real PDFs

5. **Commit Changes**:
   ```bash
   git add .
   git commit -m "feat: Add feature description"
   # Pre-commit hook will run automatically
   ```

6. **Push and Create PR**:
   ```bash
   git push origin feature/your-feature-name
   # Create pull request on GitHub
   ```

### Testing Checklist

Before committing:

- [ ] All unit tests pass (`Cmd + U`)
- [ ] No build warnings introduced
- [ ] Code follows MVVM architecture
- [ ] Async/await used for I/O operations
- [ ] No secrets in code (pre-commit hook verifies)
- [ ] Logging added for significant actions
- [ ] Error handling is comprehensive
- [ ] Documentation updated (if needed)

---

## Testing Strategy

### Unit Tests

**Location**: `PayslipMaxTests/`

**Coverage Goals**:
- Core logic: 90%+
- Services: 85%+
- ViewModels: 80%+

**Key Test Suites**:
```swift
// LLM Service Tests
LLMPayslipParserTests
GeminiLLMServiceTests
LLMBackendServiceTests
LLMSettingsServiceTests

// Build Configuration Tests
BuildConfigurationTests
FirstRunServiceTests

// Payslip Parsing Tests
UniversalPayslipProcessorTests
PayslipValidationServiceTests
```

**Running Tests**:
```bash
# All tests
xcodebuild test -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 15'

# Specific test suite
xcodebuild test -scheme PayslipMax -only-testing:PayslipMaxTests/LLMPayslipParserTests

# Coverage report
xcodebuild test -scheme PayslipMax -enableCodeCoverage YES -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Integration Tests

**Manual Testing**:
1. Fresh install testing
2. Payslip parsing (various formats)
3. LLM fallback scenarios
4. Rate limiting verification
5. Offline mode testing

**Automated Integration**:
- Firebase Test Lab (future)
- UI Tests with XCTest
- Performance tests

---

## Common Tasks

### Task 1: Add a New API Key Provider

1. Update `LLMProvider` enum:
   ```swift
   public enum LLMProvider: String, Codable, CaseIterable {
       case gemini
       case openai  // NEW
       case mock
   }
   ```

2. Add to `APIKeys.swift`:
   ```swift
   static let openAIAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
   static var isOpenAIConfigured: Bool { !openAIAPIKey.isEmpty }
   ```

3. Implement service:
   ```swift
   final class OpenAILLMService: LLMServiceProtocol {
       // Implementation
   }
   ```

4. Update factory:
   ```swift
   // LLMPayslipParserFactory.swift
   case .openai:
       service = OpenAILLMService(configuration: config)
   ```

### Task 2: Debug LLM Parsing Issues

1. Enable verbose logging:
   - Ensure Debug build is running
   - Check console for `[LLMPayslipParser]` logs

2. Verify API key:
   ```swift
   print("Gemini configured: \(APIKeys.isGeminiConfigured)")
   print("Using backend proxy: \(BuildConfiguration.useBackendProxy)")
   ```

3. Test quality check:
   - Upload payslip with known values
   - Check if totals match
   - Verify LLM fallback triggers

4. Inspect LLM response:
   - Add breakpoint in `LLMPayslipParser.parse()`
   - Step through response parsing
   - Check JSON structure

### Task 3: Update Backend Proxy

1. Edit Cloud Function:
   ```bash
   cd backend/functions
   nano index.js
   ```

2. Test locally:
   ```bash
   # Start emulator
   firebase emulators:start --only functions

   # Test with curl
   curl -X POST http://localhost:5001/payslipmax/us-central1/parseLLM \
        -H "Content-Type: application/json" \
        -d '{"data": {"prompt": "test"}}'
   ```

3. Deploy:
   ```bash
   firebase deploy --only functions
   ```

4. Verify iOS app:
   - Build Release configuration
   - Test payslip parsing
   - Check Firebase console for function logs

### Task 4: Rotate API Keys

**Development Key**:
1. Get new key from Google AI Studio
2. Update Xcode scheme (Edit Scheme → Arguments → Environment Variables)
3. Test locally

**Production Key**:
1. Get new key from Google Cloud Console
2. Update Firebase secret:
   ```bash
   firebase functions:config:set gemini.key="new_key"
   firebase deploy --only functions
   ```
3. Verify in Firebase console

### Task 5: Add New Feature Flag

1. Update `BuildConfiguration.swift`:
   ```swift
   #if DEBUG
   static let newFeatureEnabled = true
   #else
   static let newFeatureEnabled = false
   #endif
   ```

2. Use in code:
   ```swift
   if BuildConfiguration.newFeatureEnabled {
       // Feature implementation
   }
   ```

3. Add to startup diagnostics:
   ```swift
   // StartupDiagnostics.swift
   logger.info("  • New Feature: \(BuildConfiguration.newFeatureEnabled)")
   ```

---

## Dependency Management

### Swift Package Manager (SPM)

**Overview**: PayslipMax uses Swift Package Manager for dependency management. All Firebase packages are automatically resolved by Xcode.

**Dependencies**: firebase-ios-sdk v12.x
- `FirebaseAuth` - User authentication and anonymous sign-in
- `FirebaseFunctions` - Cloud Functions integration (LLM backend proxy)
- `FirebaseFirestore` - Database for LLM usage tracking

**Package Repository**: https://github.com/firebase/firebase-ios-sdk

**Automatic Resolution**: When you open `PayslipMax.xcodeproj`, Xcode automatically:
1. Downloads the Firebase SPM package
2. Resolves all transitive dependencies
3. Compiles binary frameworks
4. Integrates into the build system

**Update Dependencies**:

```bash
# Via Xcode UI (Recommended)
# File → Package Dependencies → Update to Latest Package Versions

# Via command line
xcodebuild -resolvePackageDependencies -project PayslipMax.xcodeproj
```

**Dependency Lock File**: `PayslipMax.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- Tracks pinned versions of all packages
- Committed to git for consistent builds across team
- Update by using Xcode's package dependency manager

**Clear Package Cache** (if you encounter resolution issues):

```bash
# Via Xcode UI
# File → Package Dependencies → Reset Package Caches

# Via command line
rm -rf ~/Library/Caches/org.swift.swiftpm/
rm -rf ~/Library/org.swift.swiftpm/
```

**Verify Package Resolution**:

```bash
# Check Package.resolved file
cat PayslipMax.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved | grep -A5 firebase

# Build project to verify
xcodebuild build -project PayslipMax.xcodeproj -scheme PayslipMax
```

---

## Quick Reference

### Important File Locations

```
PayslipMax/
├── Config/
│   ├── APIKeys.swift                    # API keys (gitignored)
│   └── APIKeys.template.swift           # Template for developers
├── PayslipMax/
│   ├── Core/
│   │   └── Configuration/
│   │       └── BuildConfiguration.swift # Debug/Release config
│   └── Services/
│       └── Processing/
│           └── LLM/
│               ├── LLMPayslipParser.swift        # Main parser
│               ├── GeminiLLMService.swift        # Direct API
│               ├── LLMSettingsService.swift      # Configuration
│               └── Backend/
│                   └── LLMBackendService.swift   # Backend proxy
├── backend/
│   └── functions/
│       └── index.js                     # Firebase Cloud Function
└── .git/
    └── hooks/
        └── pre-commit                   # Secret detection
```

### Environment Variables

| Variable | Purpose | Where to Set |
|----------|---------|--------------|
| `GEMINI_API_KEY` | Development API key | Xcode Scheme (Arguments → Environment Variables) |
| `FIREBASE_EMULATOR_HOST` | Local backend testing | Same as above |

### Build Configurations at a Glance

| Feature | DEBUG | RELEASE |
|---------|-------|---------|
| LLM Enabled by Default | ✅ Yes | ❌ No (opt-in) |
| Backend Proxy | ❌ Disabled | ✅ Enabled |
| Rate Limiting | ❌ Disabled | ✅ Enabled (5/hr, 50/yr) |
| Logging Level | Verbose | Info only |
| API Key Location | Xcode Scheme | Firebase Secrets |
| Authentication Required | ❌ No | ✅ Yes (Google Sign-In) |

### Useful Commands

```bash
# Build and test
xcodebuild clean build test -scheme PayslipMax

# Check for API keys
grep -r "AIza" PayslipMax/ --exclude-dir=Pods

# Verify gitignore
git check-ignore -v Config/APIKeys.swift

# Deploy backend
cd backend/functions && firebase deploy --only functions

# View Firebase logs
firebase functions:log --only parseLLM

# Test pre-commit hook
.git/hooks/pre-commit
```

---

## Troubleshooting

### Issue: "LLM enabled but no API key found"

**Cause**: Environment variable not set or Xcode scheme not configured

**Solution**:
1. Verify API key in Xcode: Edit Scheme → Run → Arguments → Environment Variables
2. Ensure "Active" is checked
3. Ensure "Shared" is **unchecked**
4. Clean and rebuild: `Cmd + Shift + K` then `Cmd + B`

### Issue: "Backend proxy failed"

**Cause**: Firebase not deployed or authentication failed

**Solution**:
1. Check Release configuration: `BuildConfiguration.useBackendProxy == true`
2. Verify Firebase deployment: `firebase functions:list`
3. Check user authentication: Must be signed in with Google
4. View function logs: `firebase functions:log --only parseLLM`

### Issue: "Rate limit exceeded"

**Cause**: Too many LLM calls in production

**Solution**:
1. Check Firestore: `llm_usage/{userId}` collection
2. Reset if needed (admin only):
   ```bash
   firebase firestore:delete "llm_usage/{userId}"
   ```
3. For development: Use Debug build (no rate limits)

---

## Security Best Practices

1. **Never commit API keys** - Use environment variables or Firebase Secrets
2. **Always use .gitignore** - Ensure sensitive files are excluded
3. **Enable pre-commit hooks** - Automatic secret detection
4. **Rotate keys regularly** - Especially if exposed or suspected compromise
5. **Use backend proxy in production** - Never ship API keys in app binary
6. **Audit git history** - Regularly check for accidentally committed secrets
7. **Least privilege principle** - Use separate keys for dev/prod
8. **Monitor usage** - Track API calls in Firebase to detect abuse

---

## Resources

- **Gemini API Docs**: https://ai.google.dev/docs
- **Firebase Functions**: https://firebase.google.com/docs/functions
- **Xcode Schemes**: https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project
- **Git Hooks**: https://git-scm.com/docs/githooks
- **Security Best Practices**: https://owasp.org/www-project-mobile-security/

---

## Contact & Support

For questions or issues:
1. Check existing documentation in `Documentation/` folder
2. Review CLAUDE.md (this file)
3. Consult project maintainers

---

**End of CLAUDE.md**
