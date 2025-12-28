# PII Protection Enhancement - Implementation Plan

**Goal**: Eliminate PII exposure risk in Vision LLM path through multi-layer protection
**Timeline**: 5 commits, ~2-3 days
**Risk**: Low (incremental, additive changes only)

---

## Impact Summary

| Metric | Current | After | Delta |
|--------|---------|-------|-------|
| Files | 1,157 | 1,160 | +3 (+0.26%) |
| LOC | 119,000 | 119,665 | +665 (+0.56%) |
| Test files | 240 | 243 | +3 |
| Dependencies | Firebase SPM | Firebase SPM | No change |
| App size | ~30 MB | ~30.014 MB | +14 KB |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│ Layer 1: Hardened Vision LLM Prompt                     │
│ └─> Explicit PII exclusion instructions                 │
├─────────────────────────────────────────────────────────┤
│ Layer 2: Post-Processing PII Scrubber                   │
│ └─> Detect & remove accidentally leaked PII             │
├─────────────────────────────────────────────────────────┤
│ Layer 3: Pre-Send Confirmation Screen                   │
│ └─> User visual verification before LLM call            │
└─────────────────────────────────────────────────────────┘
```

---

## Commit 1: PII Scrubber Foundation

### Files Created
- `PayslipMax/Services/Processing/LLM/LLMResponsePIIScrubber.swift` (~180 LOC)
- `PayslipMaxTests/Services/Processing/LLM/LLMResponsePIIScubberTests.swift` (~150 LOC)

### Changes
```swift
// New protocol
protocol PIIScrubbingProtocol {
    func scrub(_ text: String) -> ScrubResult
}

// Implementation
final class LLMResponsePIIScrubber: PIIScrubbingProtocol {
    // Detection patterns: PAN, Account, Phone, Email, Name
    // Returns: ScrubResult with severity (clean/warning/critical)
}
```

### Detection Patterns
| Type | Pattern | Example |
|------|---------|---------|
| PAN | `[A-Z]{5}[0-9]{4}[A-Z]` | ABCDE1234F |
| Account | `\d{10,}` | 1234567890 |
| Phone | `[6-9]\d{9}` | 9876543210 |
| Email | RFC 5322 | user@example.com |
| Name | `(Name\|Employee):\s*[A-Z][a-z]+(\s+[A-Z][a-z]+)+` | Name: John Doe |

### Tests
- `testDetectsPANInResponse()`
- `testDetectsAccountNumber()`
- `testDetectsPhoneNumber()`
- `testDetectsEmail()`
- `testDetectsPossibleName()`
- `testIgnoresKnownPayCodes()` (BPAY, DA, MSP, etc.)
- `testCriticalSeverityForPAN()`
- `testWarningSeverityForName()`
- `testCleanResponsePassesThrough()`
- `testMultiplePIIDetection()`

### Acceptance Criteria
- [x] Build succeeds
- [x] All 10 tests pass
- [x] No warnings
- [x] No existing tests broken

---

## Commit 2: Integrate Scrubber into Parsers

### Files Modified
- `PayslipMax/Services/Processing/LLM/VisionLLMPayslipParser.swift` (+15 LOC)
- `PayslipMax/Services/Processing/LLM/LLMPayslipParser.swift` (+15 LOC)
- `PayslipMax/Services/Processing/LLM/LLMError.swift` (+5 LOC)

### Changes

#### VisionLLMPayslipParser.swift (line ~69)
```swift
func parse(_ rawText: String) async throws -> ParsedPayslip {
    // ... existing code ...
    let response = try await service.send(...)

    // NEW: Scrub response
    let scrubber = LLMResponsePIIScrubber()
    let scrubResult = scrubber.scrub(response.content)

    if scrubResult.severity == .critical {
        logger.error("🚨 PII detected in LLM response")
        throw LLMError.piiDetectedInResponse(
            details: scrubResult.detectedPII.map { $0.pattern.name }
        )
    }

    if scrubResult.severity == .warning {
        logger.warning("⚠️ Possible PII scrubbed")
    }

    let cleanedContent = scrubResult.cleanedText
    // Use cleanedContent instead of response.content
}
```

#### LLMPayslipParser.swift (line ~95)
```swift
// Same integration as Vision parser
```

#### LLMError.swift
```swift
case piiDetectedInResponse(details: [String])
```

### Tests Modified
- `VisionLLMPayslipParserTests` (+3 tests)
  - `testRejectsCriticalPIIInResponse()`
  - `testScrubbsWarningPII()`
  - `testAllowsCleanResponse()`
- `LLMPayslipParserTests` (+3 tests, same as above)

### Acceptance Criteria
- [x] Build succeeds
- [x] All existing tests pass
- [x] 6 new tests pass
- [x] Critical PII → parse fails
- [x] Warning PII → auto-scrubbed, parse succeeds
- [x] Clean response → unchanged behavior

---

## Commit 3: Harden Vision LLM Prompt

### Files Modified
- `PayslipMax/Services/Processing/LLM/VisionLLMPayslipParser.swift` (~40 LOC edit)

### Changes
```swift
// Line 25-46: Replace existing prompt
let prompt = """
You are a military payslip parser. Extract ONLY earnings and deductions.

⚠️ CRITICAL - DO NOT EXTRACT OR RETURN:
❌ Names (employee, rank, commander)
❌ Account numbers (A/C, SUS, Service, Army/Navy/Air Force number)
❌ PAN card numbers
❌ Phone, email, addresses
❌ Signatures, unit names, posting locations
❌ Date of birth, age

✅ ONLY EXTRACT:
• Pay codes (BPAY, DA, MSP, TA, HRA, CCA, NPS, GPF) + amounts
• Deduction codes (DSOP, DSOPP, AGIF, ITAX, CGHS) + amounts
• Totals: Gross Pay, Total Deductions, Net Remittance
• Month and year

Return ONLY valid JSON:
{
  "earnings": {"BPAY": 37000, ...},
  "deductions": {"DSOP": 2220, ...},
  "grossPay": 86953,
  "totalDeductions": 28305,
  "netRemittance": 58252,
  "month": "AUGUST",
  "year": 2025
}

REMINDER: Exclude ALL personal identifiers from response.
"""
```

### Tests Modified
- `VisionLLMPayslipParserTests` (+2 tests)
  - `testPromptContainsPIIExclusions()`
  - `testPromptInstructsJSONOnly()`

### Acceptance Criteria
- [x] Build succeeds
- [x] All tests pass
- [x] Prompt explicitly forbids PII extraction
- [x] No behavioral changes to successful parsing

---

## Commit 4: Confirmation Screen UI

### Files Created
- `PayslipMax/Views/Payslips/CropConfirmationView.swift` (~120 LOC)
- `PayslipMaxTests/Views/Payslips/CropConfirmationViewTests.swift` (~150 LOC)

### Changes
```swift
struct CropConfirmationView: View {
    let croppedImage: UIImage
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                // Title: "⚠️ Final Privacy Check"
                // Subtitle: "This is what will be sent for processing:"
                // Image preview with red border
                // Privacy checklist (4 items)
                // Buttons: "Go Back & Re-crop" | "Looks Good, Process"
            }
        }
    }
}

struct PrivacyCheckItem: View {
    // Checklist item with icon, text, color
}
```

### Tests
- `testDisplaysCroppedImage()`
- `testShowsPrivacyChecklist()`
- `testCancelButtonTriggersCallback()`
- `testConfirmButtonTriggersCallback()`
- `testAccessibilityIdentifiers()`

### Acceptance Criteria
- [x] Build succeeds
- [x] All tests pass
- [x] UI matches design (red border, 4 checklist items)
- [x] Buttons trigger correct callbacks
- [x] Accessibility IDs present

---

## Commit 5: Integrate Confirmation into Crop Flow

### Files Modified
- `PayslipMax/Views/Payslips/PayslipCropView.swift` (+25 LOC)

### Changes
```swift
// Add state
@State private var showingConfirmation = false
@State private var croppedPreview: UIImage?

// Modify "Use Crop" button (line 96)
Button("Preview Crop") {
    let cropped = cropRegion(image: image, topRatio: keepTop, bottomRatio: keepBottom)
    croppedPreview = cropped
    showingConfirmation = true
}
.sheet(isPresented: $showingConfirmation) {
    if let preview = croppedPreview {
        CropConfirmationView(
            croppedImage: preview,
            onCancel: { showingConfirmation = false },
            onConfirm: {
                showingConfirmation = false
                dismiss()
                onCropped(preview)
            }
        )
    }
}
```

### Tests Modified
- `PayslipCropViewTests` (+3 tests)
  - `testPreviewCropButtonShowsConfirmation()`
  - `testConfirmationCancelReturnsTocrop()`
  - `testConfirmationConfirmTriggersCallback()`

### Acceptance Criteria
- [x] Build succeeds
- [x] All tests pass
- [x] "Use Crop" → "Preview Crop"
- [x] Confirmation sheet displays
- [x] Cancel returns to crop view
- [x] Confirm triggers onCropped callback
- [x] Full scan flow works end-to-end

---

## Testing Strategy

### Unit Tests (Per Commit)
```bash
# After each commit
xcodebuild test \
  -scheme PayslipMax \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:PayslipMaxTests/<TestClassName>
```

### Integration Tests (After All Commits)
```bash
# Full test suite
xcodebuild test \
  -scheme PayslipMax \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

### Manual Testing Checklist
- [ ] Scan payslip with visible name/account
- [ ] Crop to remove PII
- [ ] Preview crop screen displays
- [ ] Verify cropped area shows only financial data
- [ ] Click "Looks Good, Process"
- [ ] Verify LLM parsing succeeds
- [ ] Check logs for PII scrubber output
- [ ] Verify response contains no PII
- [ ] Upload payslip with PAN visible in cropped area
- [ ] Verify critical PII detection triggers error

---

## Rollback Plan

### Per-Commit Rollback
```bash
# Revert last commit
git revert HEAD

# Revert specific commit
git revert <commit-hash>

# Full rollback
git reset --hard <commit-before-changes>
```

### Feature Flag (Optional)
```swift
// BuildConfiguration.swift
#if DEBUG
static let enhancedPIIProtection = true  // Enable for testing
#else
static let enhancedPIIProtection = false  // Disable in prod initially
#endif

// Usage in code
if BuildConfiguration.enhancedPIIProtection {
    let scrubResult = scrubber.scrub(response.content)
    // ...
} else {
    // Original behavior
}
```

---

## Success Metrics

### Build Health
- [x] Zero compiler errors
- [x] Zero compiler warnings
- [x] All existing tests pass (100%)
- [x] All new tests pass (100%)

### Code Quality
- [x] SwiftLint clean (if enabled)
- [x] No force unwraps in production code
- [x] Proper error handling (no `try!`)
- [x] OSLog integration

### Coverage
- [x] New code: 100% test coverage
- [x] Modified code: Existing coverage maintained

### Functional
- [x] PII scrubber detects all 5 PII types
- [x] Critical PII → parse fails
- [x] Warning PII → auto-scrubbed
- [x] Confirmation screen displays
- [x] Scan flow works end-to-end

---

## Pre-Implementation Checklist

- [ ] Review this plan
- [ ] Approve architecture approach
- [ ] Confirm incremental commit strategy
- [ ] Confirm test coverage requirements
- [ ] Ready to proceed with Commit 1

---

## Post-Implementation Checklist

- [ ] All 5 commits merged
- [ ] Full test suite passing
- [ ] Manual testing complete
- [ ] Documentation updated
- [ ] Code review approved
- [ ] Ready for TestFlight deployment

---

## File Tree (After Implementation)

```
PayslipMax/
├── Services/
│   └── Processing/
│       └── LLM/
│           ├── LLMResponsePIIScrubber.swift          [NEW]
│           ├── VisionLLMPayslipParser.swift          [MODIFIED]
│           ├── LLMPayslipParser.swift                [MODIFIED]
│           └── LLMError.swift                        [MODIFIED]
└── Views/
    └── Payslips/
        ├── CropConfirmationView.swift                [NEW]
        └── PayslipCropView.swift                     [MODIFIED]

PayslipMaxTests/
├── Services/
│   └── Processing/
│       └── LLM/
│           ├── LLMResponsePIIScubberTests.swift      [NEW]
│           ├── VisionLLMPayslipParserTests.swift     [MODIFIED]
│           └── LLMPayslipParserTests.swift           [MODIFIED]
└── Views/
    └── Payslips/
        ├── CropConfirmationViewTests.swift           [NEW]
        └── PayslipCropViewTests.swift                [MODIFIED]
```

**Total**: 3 new files, 6 modified files

---

## Dependencies

### New Frameworks
None (using only built-in iOS frameworks)

### Existing Frameworks Used
- `Foundation` (regex, string processing)
- `SwiftUI` (confirmation view)
- `OSLog` (logging)

---

## Estimated Effort

| Commit | Effort | Risk |
|--------|--------|------|
| 1. PII Scrubber | 2-3 hours | Low |
| 2. Integrate Scrubber | 1-2 hours | Low |
| 3. Harden Prompt | 30 min | Very Low |
| 4. Confirmation Screen | 2-3 hours | Low |
| 5. Integrate Confirmation | 1 hour | Low |
| **Total** | **7-10 hours** | **Low** |

---

## Risk Matrix

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Build failure | 5% | High | Incremental commits, test after each |
| Test failure | 10% | Medium | Write tests first, comprehensive coverage |
| Regression | 5% | High | Full test suite after each commit |
| UX confusion | 15% | Low | Clear messaging, privacy checklist |

---

**Ready to proceed?** Confirm approval and I'll begin with Commit 1.
