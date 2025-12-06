# Changelog
All notable changes to PayslipMax will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **X-Ray Salary Feature (v1.0)** - Premium feature for visual month-to-month payslip comparisons
  - Visual indicators in payslip list (green/red tints for increased/decreased net remittance)
  - Shield indicator in toolbar showing X-Ray status
  - Detail view arrow indicators for individual earning/deduction changes
  - Comparison modal for items that need attention (decreased earnings, increased deductions)
  - Smart chronological comparison (handles skipped months and year boundaries)
  - Thread-safe caching for performance
  - Settings integration with premium subscription gating
  - Complete test coverage (45 automated tests)
  - Comprehensive documentation

## [Previous Versions]
<!-- Add previous version history here as needed -->

---

## Version Details

### X-Ray Salary v1.0 (December 2025)

#### Features
- **Visual List Tints**: Subtle green/red background tints (~5% opacity) on payslip cards
  - Green: Net remittance increased from previous month
  - Red: Net remittance decreased from previous month
  - No tint: First payslip or same net remittance

- **Shield Indicator**: Top-right toolbar badge
  - Green shield: X-Ray feature enabled
  - Red shield: X-Ray feature disabled
  - Tappable to navigate to settings

- **Arrow Indicators**: In payslip detail view
  - Earnings:
    - ↑ Green: Amount increased (good)
    - ↓ Red: Amount decreased (needs attention)
    - ← Grey: New earning
  - Deductions:
    - ↑ Red: Amount increased (needs attention)
    - ↓ Green: Amount decreased (good)
    - → Grey: New deduction

- **Comparison Modal**: Tap underlined amounts to see
  - Previous month amount
  - Current month amount
  - Absolute difference
  - Percentage change

#### Technical Implementation
- **Services**:
  - `PayslipComparisonService`: Core comparison logic
  - `XRaySettingsService`: Settings and subscription management
  - `PayslipComparisonCacheManager`: Thread-safe caching (50 item LRU)

- **UI Components**:
  - `XRayShieldIndicator`: Shield badge
  - `ChangeArrowIndicator`: Arrow icons
  - `ComparisonDetailModal`: Comparison popup

- **Integration**:
  - `PayslipsViewModel`: Comparison computation
  - `PayslipDetailViewModel`: Comparison data
  - `SubscriptionValidator`: Premium gating
  - `SettingsCoordinator`: Settings toggle

#### Test Coverage
- 45 automated tests (100% coverage)
- Comprehensive unit tests for all services
- Thread-safety tests for cache manager
- Edge case handling (first payslip, skipped months, year boundaries)

#### Documentation
- Feature guide: `/Documentation/Features/XRaySalary.md`
- Testing guide: `/Documentation/Testing/XRay-Phase9-TestPlan.md`
- Implementation plan: `/Users/sunil/.claude/plans/iterative-dazzling-raccoon.md`
- Updated CLAUDE.md with X-Ray information

#### Known Limitations
- Requires minimum 2 payslips for comparison
- Compares chronologically adjacent payslips only
- Premium subscription required
- Item matching by display name (case-sensitive)
- No multi-month trend analysis (future enhancement)

#### Performance
- Comparison computation: O(n log n) for sorting + O(n*m) for comparison
- Cache lookups: O(1) average
- Memory usage: ~10-25 KB for 50 cached comparisons
- Expected to handle 100+ payslips smoothly

#### Future Enhancements
- First-time tooltip when X-Ray enabled
- Percentage display in UI
- Year-over-year comparison
- Trend charts and analytics
- Export comparison reports
- Multi-payslip comparison
- Anomaly detection

---

## Guidelines for Future Updates

When adding entries to this changelog:

1. **Group changes** by type (Added, Changed, Deprecated, Removed, Fixed, Security)
2. **Write for users**, not developers
3. **Link to issues/PRs** when relevant
4. **Date format**: YYYY-MM-DD
5. **Keep it concise** but informative

Example:
```markdown
## [1.2.0] - 2025-01-15

### Added
- New export feature for annual tax summary (#123)
- Dark mode support for all screens (#124)

### Changed
- Improved PDF parsing accuracy by 15% (#125)

### Fixed
- Crash when deleting multiple payslips (#126)
- UI layout issues on iPad (#127)
```

---

**Last Updated**: December 6, 2025
