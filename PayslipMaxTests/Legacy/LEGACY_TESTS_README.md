# Legacy Complex Parsing Tests

## Overview
This folder contains tests for the **complex 243-code parsing system** that was used in PayslipMax prior to the simplified parsing implementation (canary2 branch).

## Why These Tests Were Archived
As of October 2025, PayslipMax shifted from a comprehensive 243-code parsing strategy to a **simplified, value-driven approach** that focuses on:
- 10 essential financial fields (BPAY, DA, MSP, Other Earnings, Gross Pay, DSOP, AGIF, Income Tax, Other Deductions, Total Deductions, Net Remittance)
- User-editable miscellaneous categories
- Simple confidence scoring
- Faster parsing with ~60% less code

The complex parsing system required:
- Grade-specific extraction patterns
- Spatial relationship analysis
- Merged cell detection
- Multi-stage processing pipelines
- Extensive pay code classification (243 codes)

This resulted in:
- High maintenance overhead
- Complex test suites (260+ tests)
- Slower parsing performance
- Difficult debugging

## What These Tests Cover
These 27 test files (~260-310 tests) validate:

1. **Text Extraction**: GradeAgnosticExtractionTests, PDFExtractionStrategyTests
2. **Spatial Analysis**: SpatialRelationshipCalculatorTests, MergedCellDetectorTests
3. **Cell Processing**: MultiLineCellMergerTests
4. **Pay Code Classification**: PayCodeClassificationEngineTests, PayCodeClassificationDualSectionTests
5. **Military-Specific Logic**: MilitaryAbbreviationsServiceTests, AbbreviationLoaderTests
6. **Risk & Hardship Processing**: RiskHardshipProcessorTests, EnhancedRH12DetectorTests
7. **Dual Section Handling**: RH12DualSectionIntegrationTests, PayslipDataDualSectionTests
8. **Data Serialization**: PayslipDTOConversionTests, PayslipDataSerializationTests
9. **Display Services**: PayslipDisplayNameServiceTests
10. **Integration Tests**: ArrearsClassificationIntegrationTests, CoreModuleCoverageTests

## Test Target Status
⚠️ **These tests are EXCLUDED from the PayslipMaxTests target** to:
- Reduce test execution time (711 tests → ~450 tests)
- Focus on simplified parsing validation
- Maintain faster CI/CD pipeline
- Reduce maintenance burden

## How to Re-Enable These Tests
If you need to revert to the complex parsing system:

### Option 1: Switch to canary1 Branch
```bash
git checkout canary1
# All these tests are active and passing on canary1
```

### Option 2: Re-Enable in Current Branch
1. Open `PayslipMax.xcodeproj` in Xcode
2. Select all files in `PayslipMaxTests/Legacy/`
3. In File Inspector, check "Target Membership" → PayslipMaxTests
4. Rebuild and run tests

### Option 3: Manual Project File Edit
```bash
# Add Legacy test files back to PBXSourcesBuildPhase in project.pbxproj
# (Advanced users only - can break project structure)
```

## Related Documentation
- **Simplified Parsing Plan**: `Documentation/SimplifiedParsing_Implementation_Summary.md`
- **Legacy Processing Services**: `PayslipMax/Services/Processing/Legacy/LEGACY_README.md`
- **Architecture Overview**: `Documentation/Overview/PROJECT_OVERVIEW.md`

## Timeline
- **Complex System**: canary1 branch (pre-October 2025)
- **Simplified System**: canary2 branch (October 2025+)
- **Tests Archived**: October 13, 2025

## Notes
- These tests are preserved for reference and potential future use
- The underlying complex parsing services are also archived in `PayslipMax/Services/Processing/Legacy/`
- All tests passed on canary1 before archiving
- Test data factories and helpers are preserved alongside the tests

---
*Last Updated: October 13, 2025*

