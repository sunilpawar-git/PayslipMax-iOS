# Regression Test Suite: Cache Invalidation Storm Prevention

## Overview

This document describes the regression test suite created to prevent the bug where payslips were not appearing in the Payslips tab after parsing, even though they appeared on the Home screen.

**Bug Report**: Payslips parsed successfully but showed "No Payslips Yet" in Payslips tab
**Root Cause**: Cache invalidation storm from multiple notification handlers
**Fix Date**: December 6, 2025
**Test Files Created**:
- `PayslipMaxTests/Regression/PayslipCacheRegressionTests.swift`
- `PayslipMaxTests/Regression/PayslipNotificationFlowRegressionTests.swift`

---

## Root Cause Analysis

### The Bug

When a payslip was saved:
1. **PayslipDataHandler** called `invalidateCache()` immediately
2. Then sent notifications (`payslipsRefresh` + `payslipsForcedRefresh`)
3. Multiple ViewModels (HomeViewModel, PayslipsViewModel) received notifications
4. Each notification handler tried to load payslips
5. But the cache was already empty (invalidated in step 1)
6. Result: PayslipsViewModel loaded 0 payslips → showed "No Payslips Yet"

### The Fix

**Changed `PayslipDataHandler.swift`**:
- ✅ Removed premature `invalidateCache()` before sending notifications
- ✅ Let notification handlers manage their own cache invalidation

**Changed `PayslipsViewModelSetup.swift`**:
- ✅ Simplified `handlePayslipsRefresh()` to use smart caching
- ✅ Updated `handlePayslipsForcedRefresh()` to invalidate cache within the handler

---

## Test Suite 1: PayslipCacheRegressionTests

**Purpose**: Ensure cache invalidation happens at the correct time in the flow

**Location**: `PayslipMaxTests/Regression/PayslipCacheRegressionTests.swift`

### Tests

#### 1. `testCacheInvalidation_NotCalledBeforeNotifications`
**What it tests**: Cache is populated before notifications are sent
**Why**: Ensures notification handlers can fetch cached data
**Expected**: Cache should be loaded after loading payslips

#### 2. `testMultipleNotificationHandlers_DoNotClearCache`
**What it tests**: Multiple notification handlers don't cause cache storm
**Why**: Simulates multiple ViewModels receiving notifications
**Expected**: All handlers get cached payslips (not empty)

#### 3. `testPayslipSave_NotificationHandlers_GetFreshData`
**What it tests**: After invalidation, handlers get fresh data
**Why**: Ensures cache refresh works correctly
**Expected**: After invalidation, should load fresh data

#### 4. `testCacheValidity_ExpiresAfterDuration`
**What it tests**: Cache expiry mechanism works
**Why**: Ensures cache doesn't serve stale data
**Expected**: Fresh load if cache is valid

#### 5. `testForcedRefresh_InvalidatesCacheAndReloads`
**What it tests**: Forced refresh bypasses cache
**Why**: Ensures forced refresh gets latest data
**Expected**: Should reload from data handler

#### 6. `testEmptyCache_ReturnsEmptyArray`
**What it tests**: Empty cache doesn't cause errors
**Why**: Edge case handling
**Expected**: Returns empty array, marks cache as loaded

#### 7. `testCacheInvalidation_DuringLoad_NoRaceCondition`
**What it tests**: Invalidation during load doesn't crash
**Why**: Concurrency safety
**Expected**: Completes without crash

#### 8. `testAddPayslip_InvalidatesCache`
**What it tests**: Adding payslip invalidates cache
**Why**: Ensures cache stays consistent
**Expected**: Cache should be invalidated

#### 9. `testUpdatePayslip_InvalidatesCache`
**What it tests**: Updating payslip invalidates cache
**Why**: Ensures cache stays consistent
**Expected**: Cache should be invalidated

#### 10. `testRemovePayslip_InvalidatesCache`
**What it tests**: Removing payslip invalidates cache
**Why**: Ensures cache stays consistent
**Expected**: Cache should be invalidated

---

## Test Suite 2: PayslipNotificationFlowRegressionTests

**Purpose**: Ensure notification flow doesn't cause cascading invalidations

**Location**: `PayslipMaxTests/Regression/PayslipNotificationFlowRegressionTests.swift`

### Tests

#### 1. `testForcedRefresh_SendsBothNotifications`
**What it tests**: Forced refresh sends both notification types
**Why**: Ensures PayslipEvents API contract
**Expected**: Both `.payslipsRefresh` and `.payslipsForcedRefresh` sent

#### 2. `testMultipleObservers_ReceiveNotifications`
**What it tests**: Multiple observers all receive notifications
**Why**: Simulates multiple ViewModels
**Expected**: All observers notified

#### 3. `testNotificationHandlers_NoInfiniteLoop`
**What it tests**: Handlers don't trigger cascading notifications
**Why**: Prevents notification storm
**Expected**: Exactly expected number of calls

#### 4. `testNotificationOrdering_RefreshBeforeForcedRefresh`
**What it tests**: Notification order is correct
**Why**: Ensures predictable behavior
**Expected**: Refresh arrives before forced refresh

#### 5. `testCacheInvalidation_NotBeforeNotifications` ⭐ **CRITICAL**
**What it tests**: Cache is NOT invalidated before notifications
**Why**: This was the root cause of the bug
**Expected**: Cache valid when notification arrives

#### 6. `testNotificationHandlers_InvalidateCacheAfterReceiving`
**What it tests**: Handlers invalidate cache after receiving notification
**Why**: Ensures proper invalidation timing
**Expected**: Cache invalidated by handler

#### 7. `testNotificationPerformance_MultipleObservers`
**What it tests**: Performance with multiple observers
**Why**: Ensures scalability
**Expected**: All observers notified quickly

#### 8. `testNoNotificationStorm`
**What it tests**: No cascading notifications
**Why**: Prevents exponential notification growth
**Expected**: Exactly one notification received

---

## Running the Tests

### Run All Regression Tests
```bash
xcodebuild test -project PayslipMax.xcodeproj -scheme PayslipMax \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PayslipMaxTests/PayslipCacheRegressionTests \
  -only-testing:PayslipMaxTests/PayslipNotificationFlowRegressionTests
```

### Run Cache Tests Only
```bash
xcodebuild test -project PayslipMax.xcodeproj -scheme PayslipMax \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PayslipMaxTests/PayslipCacheRegressionTests
```

### Run Notification Flow Tests Only
```bash
xcodebuild test -project PayslipMax.xcodeproj -scheme PayslipMax \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:PayslipMaxTests/PayslipNotificationFlowRegressionTests
```

---

## Test Coverage

### What is Covered

✅ Cache invalidation timing
✅ Multiple notification handlers
✅ Cache expiry mechanism
✅ Forced refresh flow
✅ Notification ordering
✅ Race condition safety
✅ Empty cache handling
✅ Add/Update/Remove operations
✅ Notification storm prevention
✅ Performance with multiple observers

### What is NOT Covered

❌ Actual database operations (uses mocks)
❌ UI integration (covered by UI tests)
❌ Network conditions
❌ Memory pressure scenarios

---

## Mock Updates

To support these tests, `MockPayslipDataHandler` was updated:

**Added Properties**:
```swift
var loadCallCount = 0           // Track load attempts
var payslipsToReturn: [PayslipItem] = []  // Configurable return data
```

**Updated Methods**:
```swift
override func loadRecentPayslips() async throws -> [PayslipItem] {
    loadCallCount += 1
    return payslipsToReturn.isEmpty ? mockRecentPayslips : payslipsToReturn
}
```

---

## CI/CD Integration

These tests are automatically run in CI:
- ✅ On pull requests to `main` and `development`
- ✅ Before releases
- ✅ Part of nightly test runs

**Failure Policy**: Any failure in these regression tests blocks merge.

---

## Maintenance

### When to Update These Tests

1. **When modifying cache logic**
   - Update `PayslipCacheRegressionTests`
   - Add new test cases for new cache behaviors

2. **When changing notification flow**
   - Update `PayslipNotificationFlowRegressionTests`
   - Verify notification ordering remains correct

3. **When adding new ViewModels**
   - Add tests for new notification observers
   - Verify no cache storms with new components

### Common Pitfalls

⚠️ **Don't remove `testCacheInvalidation_NotBeforeNotifications`**
This is the critical test that prevents the original bug

⚠️ **Don't modify notification timing without updating tests**
Tests assume specific notification order

⚠️ **Keep mock data consistent with real data**
Use `TestDataGenerator.samplePayslipItem()` for consistency

---

## Future Improvements

### Potential Enhancements

1. **Add stress tests**
   - Test with 100+ notification handlers
   - Test with rapid-fire notifications

2. **Add memory leak tests**
   - Verify notification observers are properly cleaned up
   - Test for retain cycles in cache manager

3. **Add integration tests**
   - Test full flow from save to display
   - Test with real Core Data stack

4. **Add performance benchmarks**
   - Set baseline for notification delivery time
   - Alert on performance regressions

---

## Related Documentation

- **Bug Fix**: See git commit history for detailed changes
- **Cache Manager**: `PayslipMax/Core/Services/PayslipCacheManager.swift`
- **Notification Handler**: `PayslipMax/Features/Payslips/ViewModels/PayslipsViewModelSetup.swift`
- **Data Handler**: `PayslipMax/Features/Home/Handlers/PayslipDataHandler.swift`

---

**Document Version**: 1.0
**Last Updated**: December 6, 2025
**Author**: PayslipMax Development Team
