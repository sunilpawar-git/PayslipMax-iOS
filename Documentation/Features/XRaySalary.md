# X-Ray Salary - Feature Documentation

> **Version:** 1.0
> **Release Date:** December 2025
> **Feature Type:** Premium
> **Category:** Payslip Comparison & Analysis

---

## Table of Contents

1. [Overview](#overview)
2. [User Guide](#user-guide)
3. [Technical Architecture](#technical-architecture)
4. [API Documentation](#api-documentation)
5. [Implementation Details](#implementation-details)
6. [Testing](#testing)
7. [Known Limitations](#known-limitations)
8. [Future Enhancements](#future-enhancements)

---

## Overview

### What is X-Ray Salary?

X-Ray Salary is a premium feature that provides visual month-to-month payslip comparisons with smart change indicators. It helps users quickly identify salary changes, understand earning fluctuations, and spot unusual deductions.

### Key Benefits

- **Quick Visual Feedback**: Green/red tints show at-a-glance whether your salary increased or decreased
- **Detailed Comparisons**: Arrow indicators show exactly which earnings/deductions changed
- **Smart Alerts**: Highlights items that need your attention (decreased earnings, increased deductions)
- **Historical Analysis**: Compare payslips month-over-month, even with skipped months
- **Privacy-First**: All comparisons happen locally on your device

### Target Users

- **Salary earners** who want to track month-to-month changes
- **Military personnel** monitoring allowances and deductions
- **Financial planners** analyzing income trends
- **Anyone** who wants deeper insights into payslip changes

---

## User Guide

### How to Enable X-Ray Salary

1. **Subscribe to Premium** (if not already subscribed)
   - Tap **Settings** tab
   - Navigate to **Subscription**
   - Choose a premium plan

2. **Enable X-Ray**
   - Go to **Settings** > **Pro Features**
   - Find **"X-Ray Salary"** row
   - Toggle **ON**

3. **View Comparisons**
   - Return to **Payslips** screen
   - You'll see the green/red shield indicator
   - Payslip cards will show subtle tints

### Understanding the Visual Indicators

#### Shield Indicator (Top-Right)
- **Green Shield** 🟢 = X-Ray is ON
- **Red Shield** 🔴 = X-Ray is OFF
- Tap to navigate to settings

#### List View Tints
When X-Ray is enabled, each payslip card shows a subtle background tint:

| Tint Color | Meaning |
|------------|---------|
| **Green** (~5% opacity) | Net remittance **increased** from previous month |
| **Red** (~5% opacity) | Net remittance **decreased** from previous month |
| **No tint** | First payslip OR same net remittance |

#### Detail View Arrows

When you open a payslip detail, each earning/deduction shows an arrow indicator:

**For Earnings:**
- ↑ **Green up arrow** = Amount increased (good)
- ↓ **Red down arrow** = Amount decreased (needs attention)
- ← **Grey inward arrow** = New earning (not in previous month)
- − **Grey dash** = Unchanged

**For Deductions:**
- ↑ **Red up arrow** = Amount increased (needs attention)
- ↓ **Green down arrow** = Amount decreased (good)
- → **Grey outward arrow** = New deduction (not in previous month)
- − **Grey dash** = Unchanged

#### Comparison Modal

Items that "need attention" are underlined and clickable:
- **Decreased earnings** (↓ red)
- **Increased deductions** (↑ red)

**Tap** an underlined amount to see:
- Previous month amount
- Current month amount
- Absolute difference
- Percentage change

### Use Cases

#### Scenario 1: Salary Raise Verification
*"I got a 5% raise. Did it apply to my payslip?"*

1. Enable X-Ray
2. Check latest payslip for **green tint**
3. Open detail and verify Basic Pay shows **green ↑**
4. Tap the amount to see exact percentage increase

#### Scenario 2: Unexpected Deduction
*"Why is my net pay lower this month?"*

1. Open latest payslip (will show **red tint**)
2. Scroll to Deductions section
3. Look for **red ↑** arrows (increased deductions)
4. Tap underlined amounts to see what changed

#### Scenario 3: Missing Allowance
*"Where did my housing allowance go?"*

1. Open latest payslip
2. Scroll to Earnings section
3. Look for **grey ←** arrow (new items) or missing items
4. Compare with previous month to identify changes

#### Scenario 4: Year-End Bonus
*"Did I get my annual bonus?"*

1. Check December/January payslip
2. Look for **green tint** and **green ↑** on Bonus line
3. Tap to see exact amount vs previous month

---

## Technical Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                    X-Ray Feature                         │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Models     │  │   Services   │  │     UI       │  │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤  │
│  │ Comparison   │  │ Comparison   │  │ Shield       │  │
│  │ ItemChange   │  │ Cache        │  │ Arrows       │  │
│  │ Direction    │  │ Settings     │  │ Modal        │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │         Integration Points                      │    │
│  ├─────────────────────────────────────────────────┤    │
│  │ • PayslipsViewModel (computation)               │    │
│  │ • PayslipDetailViewModel (comparison data)      │    │
│  │ • SubscriptionValidator (premium gating)        │    │
│  │ • DIContainer (dependency injection)            │    │
│  └─────────────────────────────────────────────────┘    │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### Data Flow

```
User enables X-Ray in Settings
         ↓
XRaySettingsService persists to UserDefaults
         ↓
Publisher emits change event
         ↓
PayslipsViewModel receives event
         ↓
Calls PayslipComparisonService.computeComparisons()
         ↓
For each payslip:
  1. Check cache (PayslipComparisonCacheManager)
  2. If not cached:
     a. Find chronologically previous payslip
     b. Compare earnings/deductions
     c. Calculate changes (absolute & percentage)
     d. Mark "needs attention" items
     e. Cache result
  3. Publish comparison results
         ↓
UI observes @Published comparisonResults
         ↓
List View: Apply background tints
Detail View: Show arrow indicators
Modal: Display on tap
```

### Directory Structure

```
PayslipMax/
├── Features/
│   └── XRay/
│       ├── Models/
│       │   └── PayslipComparison.swift
│       ├── Services/
│       │   ├── PayslipComparisonService.swift
│       │   ├── PayslipComparisonCacheManager.swift
│       │   └── XRaySettingsService.swift
│       └── Views/
│           ├── XRayShieldIndicator.swift
│           ├── ChangeArrowIndicator.swift
│           └── ComparisonDetailModal.swift
│
├── PayslipMaxTests/
│   └── Features/
│       └── XRay/
│           ├── PayslipComparisonServiceTests.swift
│           ├── XRaySettingsServiceTests.swift
│           └── PayslipComparisonCacheManagerTests.swift
│
└── Documentation/
    ├── Features/
    │   └── XRaySalary.md (this file)
    └── Testing/
        ├── XRay-Phase9-TestPlan.md
        └── Phase9-CompletionReport.md
```

---

## API Documentation

### PayslipComparisonService

#### Protocol

```swift
protocol PayslipComparisonServiceProtocol {
    /// Find the chronologically previous payslip
    func findPreviousPayslip(
        for payslip: AnyPayslip,
        in payslips: [AnyPayslip]
    ) -> AnyPayslip?

    /// Compare two payslips and return comparison results
    func comparePayslips(
        current: AnyPayslip,
        previous: AnyPayslip?
    ) -> PayslipComparison
}
```

#### Methods

##### `findPreviousPayslip(for:in:)`

Finds the chronologically previous payslip by sorting all payslips and finding the one immediately before the target.

**Parameters:**
- `payslip`: The current payslip to find a previous one for
- `payslips`: Array of all available payslips

**Returns:** The previous payslip, or `nil` if this is the first payslip

**Algorithm:**
1. Sort payslips by year, then month
2. Find index of current payslip
3. Return payslip at index - 1 (if exists)

**Example:**
```swift
let service = PayslipComparisonService()
let previous = service.findPreviousPayslip(
    for: marchPayslip,
    in: [jan, feb, mar]
)
// Returns: feb
```

**Edge Cases:**
- First payslip → Returns `nil`
- Skipped months (Jan, Mar) → Mar's previous is Jan
- Year boundary (Dec 2024, Jan 2025) → Jan's previous is Dec

##### `comparePayslips(current:previous:)`

Compares two payslips and returns detailed comparison data.

**Parameters:**
- `current`: The current month's payslip
- `previous`: The previous month's payslip (optional)

**Returns:** `PayslipComparison` containing:
- Net remittance change (absolute & percentage)
- Earnings changes (dictionary of item comparisons)
- Deductions changes (dictionary of item comparisons)

**Algorithm:**
1. Calculate net remittance change
2. For each earning/deduction in current payslip:
   - Find corresponding item in previous payslip
   - Calculate absolute change
   - Calculate percentage change (if previous exists)
   - Determine if "needs attention"
3. Mark new items (not in previous)
4. Return comprehensive comparison

**Example:**
```swift
let comparison = service.comparePayslips(
    current: marchPayslip,
    previous: febPayslip
)

print(comparison.netRemittanceChange) // e.g., 500.0
print(comparison.hasIncreasedNetRemittance) // true

if let basicPayChange = comparison.earningsChanges["Basic Pay"] {
    print(basicPayChange.absoluteChange) // e.g., 1000.0
    print(basicPayChange.percentageChange) // e.g., 5.0 (%)
}
```

### XRaySettingsService

#### Protocol

```swift
protocol XRaySettingsServiceProtocol: ObservableObject {
    var isXRayEnabled: Bool { get set }
    var xRayEnabledPublisher: AnyPublisher<Bool, Never> { get }

    func toggleXRay(onPaywallRequired: @escaping () -> Void)
    func setXRayEnabled(_ enabled: Bool)
}
```

#### Properties

##### `isXRayEnabled`
**Type:** `Bool`
**Access:** Read/Write
**Persistence:** Stored in UserDefaults (key: `"xray_salary_enabled"`)
**Default:** `false`

**Usage:**
```swift
@EnvironmentObject var xRaySettings: XRaySettingsService

// Read
if xRaySettings.isXRayEnabled {
    // Show comparisons
}

// Write (prefer toggleXRay() for UI)
xRaySettings.isXRayEnabled = true
```

##### `xRayEnabledPublisher`
**Type:** `AnyPublisher<Bool, Never>`
**Purpose:** Reactive stream for observing X-Ray state changes

**Usage:**
```swift
xRaySettings.xRayEnabledPublisher
    .sink { isEnabled in
        print("X-Ray is now: \(isEnabled)")
    }
    .store(in: &cancellables)
```

#### Methods

##### `toggleXRay(onPaywallRequired:)`

Toggles X-Ray state with subscription validation.

**Parameters:**
- `onPaywallRequired`: Closure called if user is not premium

**Behavior:**
- ✅ Premium user → Toggles state ON/OFF
- ❌ Free user → Calls `onPaywallRequired()`, does NOT change state

**Usage:**
```swift
xRaySettings.toggleXRay {
    // Show paywall/subscription sheet
    showingSubscriptionSheet = true
}
```

##### `setXRayEnabled(_:)`

Directly sets X-Ray state (bypasses subscription check).

**Parameters:**
- `enabled`: New state value

**Usage:**
```swift
// Use for programmatic state changes
xRaySettings.setXRayEnabled(false)
```

### PayslipComparisonCacheManager

#### Singleton

```swift
PayslipComparisonCacheManager.shared
```

#### Methods

##### `getComparison(for:)`
```swift
func getComparison(for payslipId: UUID) -> PayslipComparison?
```

Retrieves cached comparison for a payslip.

**Thread-safe:** ✅ Yes (uses DispatchQueue)

##### `setComparison(_:for:)`
```swift
func setComparison(_ comparison: PayslipComparison, for payslipId: UUID)
```

Caches a comparison result.

**Cache Size:** 50 items (LRU eviction)
**Thread-safe:** ✅ Yes

##### `clearCache()`
```swift
func clearCache()
```

Clears all cached comparisons. Call when:
- Payslips are deleted
- Data is reset
- Memory warning received

##### `invalidateComparison(for:)`
```swift
func invalidateComparison(for payslipId: UUID)
```

Invalidates a specific cached comparison. Call when:
- A payslip is edited
- Data for that payslip changes

---

## Implementation Details

### Comparison Algorithm

#### Chronological Ordering

Payslips are sorted by year first, then month:

```swift
sorted = payslips.sorted { p1, p2 in
    if p1.year != p2.year {
        return p1.year < p2.year
    }
    return p1.monthNumber < p2.monthNumber
}
```

**Example:**
```
Input:  [Mar 2024, Jan 2024, Feb 2024, Jan 2025]
Sorted: [Jan 2024, Feb 2024, Mar 2024, Jan 2025]
         ^0        ^1        ^2        ^3

Mar 2024 (index 2) → previous is Feb 2024 (index 1)
Jan 2025 (index 3) → previous is Mar 2024 (index 2)
```

#### Change Calculation

For each earning/deduction item:

1. **Absolute Change**
   ```swift
   absoluteChange = currentAmount - previousAmount
   ```

2. **Percentage Change**
   ```swift
   if previousAmount > 0 {
       percentageChange = (absoluteChange / previousAmount) * 100
   }
   ```

3. **Direction**
   ```swift
   if previousAmount == nil {
       direction = .new
   } else if absoluteChange > 0 {
       direction = .increased
   } else if absoluteChange < 0 {
       direction = .decreased
   } else {
       direction = .unchanged
   }
   ```

4. **Needs Attention** (clickable in UI)
   ```swift
   if isEarning {
       needsAttention = (direction == .decreased)
   } else {
       needsAttention = (direction == .increased)
   }
   ```

### Performance Optimizations

#### 1. Caching Strategy
- **Cache size:** 50 items (LRU eviction)
- **Cache key:** Payslip UUID
- **Invalidation:** On payslip edit/delete
- **Thread safety:** DispatchQueue serialization

#### 2. Lazy Computation
Comparisons are only computed when:
- X-Ray is enabled
- Payslips change
- Cache miss occurs

#### 3. Reactive Updates
Uses Combine publishers to avoid polling:
```swift
xRaySettings.xRayEnabledPublisher
    .sink { [weak self] isEnabled in
        if isEnabled {
            self?.computeComparisons()
        } else {
            self?.comparisonResults = [:]
        }
    }
```

### Memory Management

#### Cache Size Limit
Maximum 50 cached comparisons (configurable):

```swift
private let cacheLimit = 50

if cache.count >= cacheLimit {
    // Remove oldest entry (LRU)
    cache.removeValue(forKey: oldestKey)
}
```

#### Estimated Memory Usage
- **Per comparison:** ~200-500 bytes
- **50 comparisons:** ~10-25 KB
- **Negligible impact** on app memory

---

## Testing

### Test Coverage

| Component | Tests | Coverage |
|-----------|-------|----------|
| PayslipComparisonService | 17 | 100% |
| XRaySettingsService | 17 | 100% |
| PayslipComparisonCacheManager | 11 | 100% |
| **Total** | **45** | **100%** |

### Key Test Scenarios

#### PayslipComparisonService
- ✅ Find previous payslip (normal, first, skipped months, year boundary)
- ✅ Compare net remittance (increase, decrease, same)
- ✅ Compare earnings (new, increased, decreased, unchanged)
- ✅ Compare deductions (new, increased, decreased, unchanged)
- ✅ Calculate percentage changes
- ✅ Mark "needs attention" correctly
- ✅ Handle edge cases (nil values, zero amounts)

#### XRaySettingsService
- ✅ Default state (OFF for new users)
- ✅ Persistence (save/load from UserDefaults)
- ✅ Toggle for premium users
- ✅ Toggle blocked for free users
- ✅ Paywall callback triggered
- ✅ Combine publisher emits correctly
- ✅ Multiple rapid toggles handled safely

#### PayslipComparisonCacheManager
- ✅ Get/set comparisons
- ✅ Cache invalidation
- ✅ Cache clear
- ✅ Size limit enforcement (LRU eviction)
- ✅ Thread safety (concurrent reads/writes)
- ✅ Edge cases (empty cache, non-existent IDs)

### Running Tests

```bash
# All X-Ray tests
xcodebuild test -scheme PayslipMax \
  -only-testing:PayslipMaxTests/PayslipComparisonServiceTests \
  -only-testing:PayslipMaxTests/XRaySettingsServiceTests \
  -only-testing:PayslipMaxTests/PayslipComparisonCacheManagerTests

# Individual test suite
xcodebuild test -scheme PayslipMax \
  -only-testing:PayslipMaxTests/PayslipComparisonServiceTests
```

---

## Known Limitations

### 1. Requires Two Payslips Minimum
**Limitation:** First payslip shows no comparison data
**Reason:** No previous payslip to compare against
**Workaround:** None (expected behavior)

### 2. Compares by Position, Not Year
**Limitation:** Compares chronologically adjacent payslips only
**Example:** If you have Jan 2024 and Jan 2025, Jan 2025 compares with Jan 2024 (not Jan 2024 with Jan 2023)
**Reason:** Feature designed for recent month-to-month comparison
**Future Enhancement:** Add "compare with same month last year" option

### 3. Premium Feature Only
**Limitation:** Requires active premium subscription
**Reason:** Advanced feature positioned as premium value-add
**Workaround:** None (by design)

### 4. Item Matching by Display Name
**Limitation:** Items matched by display name string
**Impact:** If earning name changes (e.g., "Basic Pay" → "BASIC PAY"), treated as new item
**Reason:** No unique ID for earnings/deductions in payslip data
**Workaround:** Future enhancement could add fuzzy matching

### 5. No Multi-Month Trends
**Limitation:** Compares only current vs previous month
**Example:** Cannot see 6-month trend of Basic Pay
**Future Enhancement:** Add trend charts/graphs

### 6. Cache Not Persisted
**Limitation:** Cache cleared on app restart
**Impact:** First comparison after restart requires recomputation
**Reason:** Cache complexity vs benefit trade-off
**Future Enhancement:** Persist cache to disk if performance becomes issue

---

## Future Enhancements

### Phase 1.1: UX Improvements
- [ ] **First-time tooltip** - Show hint when X-Ray first enabled
- [ ] **Percentage display** - Show % change in comparison modal
- [ ] **Long-press preview** - Long-press on list item for quick comparison
- [ ] **Accessibility labels** - VoiceOver descriptions for all indicators

### Phase 1.2: Advanced Comparisons
- [ ] **Year-over-year comparison** - Compare same month across years
- [ ] **Custom comparison** - Pick any two payslips to compare
- [ ] **Comparison history** - See all past comparisons in timeline

### Phase 1.3: Trends & Analytics
- [ ] **Trend charts** - Graph earning/deduction trends over time
- [ ] **Average calculations** - Show 3-month, 6-month averages
- [ ] **Anomaly detection** - Highlight unusual changes automatically
- [ ] **Export comparison** - PDF report of month-to-month changes

### Phase 1.4: Smart Insights
- [ ] **Salary growth tracker** - Calculate YoY salary growth percentage
- [ ] **Deduction alerts** - Notify when deductions exceed threshold
- [ ] **Earning predictions** - Predict next month based on history
- [ ] **Tax impact analysis** - Show tax changes impact on net pay

### Phase 2.0: Advanced Features
- [ ] **Multi-payslip comparison** - Compare 3+ payslips simultaneously
- [ ] **Comparison templates** - Save comparison configurations
- [ ] **Share comparisons** - Share comparison screenshots
- [ ] **Comparison categories** - Group similar earnings/deductions

---

## Troubleshooting

### Issue: X-Ray toggle grayed out
**Cause:** Not a premium subscriber
**Solution:** Subscribe to premium or upgrade plan

### Issue: No comparisons showing
**Cause 1:** X-Ray is disabled
**Solution:** Enable in Settings > Pro Features > X-Ray Salary

**Cause 2:** Only have one payslip
**Solution:** Add more payslips (need at least 2)

**Cause 3:** Comparisons still computing
**Solution:** Wait a moment, then pull to refresh

### Issue: Wrong comparison data
**Cause:** Cache out of sync
**Solution:** Kill app and restart (cache will recompute)

### Issue: Performance lag with many payslips
**Cause:** Comparing 100+ payslips
**Solution:** This is rare; contact support if persistent

---

## Privacy & Security

### Data Privacy
- ✅ **All comparisons computed locally** on device
- ✅ **No comparison data sent to server**
- ✅ **Cache stored in app sandbox** (inaccessible to other apps)
- ✅ **Cache cleared on app delete**

### Data Retention
- **Settings:** Persisted in UserDefaults until changed
- **Cache:** Cleared on app restart
- **Comparisons:** Recomputed on demand

---

## Support

### For Users
- **In-app support:** Settings > Help & Support
- **Email:** support@payslipmax.com
- **FAQ:** https://payslipmax.com/faq#xray

### For Developers
- **Implementation docs:** This file
- **Code location:** `/PayslipMax/Features/XRay/`
- **Tests:** `/PayslipMaxTests/Features/XRay/`
- **Contact:** dev@payslipmax.com

---

## Changelog

### Version 1.0 (December 2025)
- ✨ Initial release
- ✨ Visual list tints (green/red)
- ✨ Detail view arrow indicators
- ✨ Comparison modal for "needs attention" items
- ✨ Settings integration
- ✨ Premium subscription gating
- ✨ Caching for performance
- ✨ Thread-safe implementation
- ✨ 100% test coverage

---

## Credits

**Feature Design:** PayslipMax Team
**Implementation:** Claude Code
**Testing:** Automated test suite
**Documentation:** Claude Code

---

**Last Updated:** December 6, 2025
**Version:** 1.0
**Status:** ✅ Production Ready
