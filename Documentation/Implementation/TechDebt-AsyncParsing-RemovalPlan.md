# Technical Debt Removal Plan: Async Parsing Implementation
**Created**: December 26, 2025
**Status**: ✅ **FULLY COMPLETE** - All Phases Done
**Estimated Total Effort**: 20 hours
**Actual Total Effort**: ~6 hours

---

## ✅ Implementation Summary (December 26, 2025)

### Completed Items:

**Phase 1.1 - Real Progress Tracking:**
- ✅ Created `ParsingProgressDelegate.swift` - protocol for real-time progress updates
- ✅ Added delegate support to `VisionLLMPayslipParser` with stage reporting
- ✅ Removed 1 second of artificial `Task.sleep()` delays from parsing flow

**Phase 1.2 - Real PayslipItem in Completion:**
- ✅ Modified `ImageImportProcessor.processCroppedImageLLMOnly()` to return `Result<PayslipItem, ...>`
- ✅ Updated `PayslipParsingProgressService` to use real parsed payslip data
- ✅ Removed placeholder `PayslipItem` creation

**Phase 1.3 - Magic Numbers to Constants:**
- ✅ Created `ValidationThresholds.swift` with all threshold constants
- ✅ Updated `PayslipSanityCheckValidator` to use centralized thresholds
- ✅ Updated `VisionLLMVerificationService` to use centralized thresholds
- ✅ Updated `VisionLLMPayslipParser` to use verification trigger threshold

**Phase 2.2 - Configurable Keywords:**
- ✅ Created `SuspiciousKeywordsConfig.swift` with locale support
- ✅ Updated validator to use configurable keywords

**Phase 2.3 - Tab Navigation Enum:**
- ✅ Created `AppTab.swift` enum with titles, icons, accessibility labels
- ✅ Updated `PayslipScannerView`, `NavRouter`, `NavigationState` to use enum

**Phase 3.1 - Response Caching:**
- ✅ Created `LLMResponseCache.swift` with thread-safe NSCache implementation
- ✅ SHA256 image hashing for cache keys
- ✅ 1-hour TTL with automatic expiration
- ✅ Integrated into `VisionLLMPayslipParser` for cache hits/misses

**Phase 3.2 - Retry Mechanism:**
- ✅ Added retry callback storage to `PayslipParsingProgressService`
- ✅ Added `retry()` method to re-attempt failed parsing
- ✅ Updated `ParsingProgressOverlay` with Retry button for failed states
- ✅ Increased auto-dismiss timeout to 5 seconds for retry opportunity

**Phase 3.3 - Accessibility Support:**
- ✅ Added comprehensive `.accessibilityLabel()` for all progress states
- ✅ Added `.accessibilityValue()` for progress percentage
- ✅ Added `.accessibilityHint()` for action buttons
- ✅ Added `.accessibilityIdentifier()` for UI testing

**Phase 3.4 - Analytics & Logging:**
- ✅ Created `ParsingAnalytics.swift` with structured event logging
- ✅ Integrated analytics into `VisionLLMPayslipParser` for all stages
- ✅ Integrated analytics into `VisionLLMVerificationService`
- ✅ Tracks: parsing started, extraction complete, validation, verification, completion, failures

---

## Phase 1: Critical Fixes (Priority: HIGH)
**Effort**: 8 hours
**Timeline**: Next sprint

### 1.1 Real Progress Tracking
**File**: `PayslipParsingProgressService.swift`
**Problem**: Fake progress states with `Task.sleep()` delays

**Changes Required**:
```swift
// Add progress callback to VisionLLMPayslipParser
protocol ParsingProgressDelegate: AnyObject {
    func didUpdateProgress(_ stage: ParsingStage, percent: Double)
}

// Modify parse() to report real stages:
- Before extraction: .extracting (0%)
- After extraction: .validating (40%)
- Before verification: .verifying (60%)
- After verification: .saving (90%)
- After save: .completed (100%)
```

**Files to Modify**:
- `VisionLLMPayslipParser.swift` - Add delegate calls
- `PayslipParsingProgressService.swift` - Implement delegate
- Remove all `Task.sleep()` artificial delays

**Testing**: Verify progress matches actual parsing stages

---

### 1.2 Real PayslipItem in Completion State
**File**: `PayslipParsingProgressService.swift:163`
**Problem**: Using placeholder with zeros

**Changes Required**:
```swift
// Modify ImageImportProcessor to return PayslipItem
func processCroppedImageLLMOnly(_ image: UIImage) async -> Result<PayslipItem, ImageImportError>

// Update progress service to store result
case .success(let payslip):
    state = .completed(payslip)  // Real data
```

**Files to Modify**:
- `ImageImportProcessor.swift` - Change return type
- `PayslipParsingProgressService.swift` - Store real result
- Remove `PayslipItem.placeholder()` extension

**Testing**: Verify completion shows real parsed data

---

### 1.3 Extract Magic Numbers to Constants
**Files**: `PayslipSanityCheckValidator.swift`, `VisionLLMPayslipParser.swift`

**Changes Required**:
```swift
// Create ValidationThresholds.swift
struct ValidationThresholds {
    static let minorErrorPercent: Double = 0.01
    static let majorErrorPercent: Double = 0.05
    static let minorConfidencePenalty: Double = 0.05
    static let majorConfidencePenalty: Double = 0.3
    static let criticalPenalty: Double = 0.4
    static let minimumKeepRatio: Double = 0.15
}

// Replace all hardcoded values
```

**Files to Create**: `ValidationThresholds.swift`
**Files to Modify**: All validators using magic numbers

**Testing**: Verify behavior unchanged after refactor

---

## Phase 2: Medium Priority Fixes
**Effort**: 6 hours
**Timeline**: Within 2 sprints

### 2.1 Fix Misleading "Averaging" Log Message ✅ COMPLETE
**File**: `VisionLLMVerificationService.swift:65-74`
**Problem**: Log says "averaging results" but actually returns second pass

**Resolution**: Second pass is intentionally for verification (ensuring 100% accuracy), not averaging.
- ✅ Updated log to say "using second pass with reduced confidence"
- ✅ Added agreement percentage to all log messages for better debugging
- ✅ Clarified "reverting to first pass" when agreement is very low

**Rationale**: The second pass is a fresh verification attempt, not meant to be averaged with potentially incorrect first pass data.

---

### 2.2 Configurable Suspicious Keywords
**Files**: `PayslipSanityCheckValidator.swift`, `VisionLLMPayslipParser.swift`

**Changes Required**:
```swift
// Create SuspiciousKeywordsConfig.swift
struct SuspiciousKeywordsConfig {
    static let keywords = [
        "total", "balance", "released", "refund",
        "recovery", "previous", "carried", "forward",
        "advance", "credit balance"
    ]

    // Support for future localization
    static func keywords(for locale: Locale) -> [String] {
        // Return localized keywords
    }
}
```

**Files to Create**: `SuspiciousKeywordsConfig.swift`
**Files to Modify**: All files using hardcoded keywords

---

### 2.3 Tab Index Enum
**File**: `PayslipScannerView.swift:131`

**Changes Required**:
```swift
// Create AppTab.swift
enum AppTab: Int, CaseIterable {
    case home = 0
    case payslips = 1
    case insights = 2
    case settings = 3

    var title: String { ... }
    var icon: String { ... }
}

// Use everywhere
TabTransitionCoordinator.shared.selectedTab = AppTab.payslips.rawValue
```

**Files to Create**: `AppTab.swift`
**Files to Modify**: `MainTabView.swift`, `PayslipScannerView.swift`

---

## Phase 3: Nice-to-Have Improvements
**Effort**: 6 hours
**Timeline**: Future sprints

### 3.1 Response Caching
**File**: `VisionLLMPayslipParser.swift`

**Changes Required**:
```swift
private let cache = NSCache<NSString, CachedParseResult>()

struct CachedParseResult {
    let response: LLMPayslipResponse
    let confidence: Double
    let timestamp: Date
}

func parse(image: UIImage) async throws -> PayslipItem {
    let imageHash = image.sha256Hash()

    if let cached = cache.object(forKey: imageHash as NSString),
       Date().timeIntervalSince(cached.timestamp) < 3600 { // 1 hour cache
        return mapToPayslipItem(cached.response, confidence: cached.confidence)
    }

    // Proceed with parsing...
}
```

**Testing**: Verify cache hits/misses, expiration

---

### 3.2 Retry Mechanism
**File**: `PayslipParsingProgressService.swift`

**Changes Required**:
```swift
case .failure(let error):
    state = .failed(error.localizedDescription)

    // Store retry callback
    retryCallback = { [weak self] in
        await self?.performParsing(image: image, processor: processor)
    }

// Update ParsingProgressOverlay to show Retry button
```

**Files to Modify**:
- `PayslipParsingProgressService.swift`
- `ParsingProgressOverlay.swift`

---

### 3.3 Accessibility Support
**File**: `ParsingProgressOverlay.swift`

**Changes Required**:
```swift
.accessibilityLabel(state.progressMessage)
.accessibilityValue("\(Int(state.progressPercent * 100)) percent complete")
.accessibilityHint("Payslip is being analyzed")

// Add accessibility identifiers for testing
.accessibilityIdentifier("parsing_progress_overlay")
```

---

### 3.4 Analytics & Logging
**Files**: All parsing-related files

**Changes Required**:
```swift
// Create AnalyticsEvent.swift
enum ParsingEvent: AnalyticsEvent {
    case parsingStarted
    case extractionComplete(duration: TimeInterval)
    case validationComplete(issues: Int)
    case verificationTriggered(confidence: Double)
    case verificationComplete(agreement: Double)
    case parsingComplete(confidence: Double, duration: TimeInterval)
    case parsingFailed(error: String)
}

// Add logging throughout
Analytics.log(.parsingStarted)
Analytics.log(.verificationTriggered(confidence: 0.85))
```

**Files to Create**: `ParsingAnalytics.swift`
**Testing**: Verify events logged correctly

---

## Implementation Order

### Sprint 1 (Week 1-2) ✅ COMPLETE
- [x] 1.1 Real Progress Tracking
- [x] 1.2 Real PayslipItem in Completion
- [x] 1.3 Extract Magic Numbers

**Deliverable**: Honest, real-time progress tracking ✅

### Sprint 2 (Week 3-4) ✅ COMPLETE
- [x] 2.1 Fix Misleading Log Message (no averaging needed - second pass is verification)
- [x] 2.2 Configurable Keywords
- [x] 2.3 Tab Index Enum

**Deliverable**: Better verification, maintainable config ✅

### Sprint 3+ (Future) ✅ COMPLETE
- [x] 3.1 Response Caching
- [x] 3.2 Retry Mechanism
- [x] 3.3 Accessibility
- [x] 3.4 Analytics

**Deliverable**: Polish, observability, performance ✅

---

## Success Criteria

### Phase 1 Complete: ✅ ACHIEVED
- ✅ Progress states match actual parsing stages
- ✅ No artificial delays in parsing flow
- ✅ Completion shows real parsed data
- ✅ All magic numbers in constants

### Phase 2 Complete: ✅ FULLY ACHIEVED
- ✅ Verification log messages corrected (no averaging - second pass is verification)
- ✅ Keywords configurable via config file
- ✅ Tab indices use enum

### Phase 3 Complete: ✅ FULLY ACHIEVED
- ✅ Cache reduces redundant API calls (SHA256 hashing, 1-hour TTL)
- ✅ Users can retry failed parses (Retry button in error state)
- ✅ VoiceOver users can track progress (comprehensive accessibility labels)
- ✅ Analytics track parsing metrics (structured event logging)

---

## Risk Mitigation

### Breaking Changes:
- **Risk**: Modifying `ImageImportProcessor` breaks callers
- **Mitigation**: Add new method, deprecate old one gradually

### Performance Impact:
- **Risk**: Real progress tracking adds overhead
- **Mitigation**: Use lightweight delegate calls, async updates

### Cache Memory:
- **Risk**: Cache grows unbounded
- **Mitigation**: Set `NSCache` count/cost limits, auto-eviction

---

## Notes

- All changes should maintain backward compatibility where possible
- Each phase should be independently deployable
- Add tests for each phase before considering complete
- Monitor production metrics after each phase deployment
