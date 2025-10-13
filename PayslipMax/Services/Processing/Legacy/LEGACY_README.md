# Legacy Complex Parsing System

## Overview

This directory contains the archived complex 243-code parsing system that was replaced by the simplified essential-only extraction approach in October 2025.

**Replacement**: `SimplifiedPayslipParser` (10 essential patterns)  
**Branch**: Implementation on `canary2`, original on `canary1`

## Why It Was Archived

The complex parsing system, while comprehensive, had several challenges:

1. **Complexity**: 200+ extraction patterns, spatial analysis, relationship calculations
2. **Maintainability**: Distributed across multiple files, difficult to debug
3. **Performance**: Slower due to spatial intelligence overhead
4. **User Value**: Parsed 243 codes but users only needed ~10 essential fields
5. **Edge Cases**: New military pay codes required code changes

## What Was Replaced

### Core Components (Archived for Reference)
- `UnifiedDefensePayslipProcessor.swift` - Main complex processor
- `UniversalPayCodeSearchEngine.swift` - 243-code universal search
- `SpatialAnalyzer.swift` - Spatial intelligence for column detection
- Pattern files for all 243 military pay codes
- Dual-section processors (RH12, etc.)
- Grade-agnostic extraction systems

### Replacement System
- **SimplifiedPayslipParser.swift** (~220 lines)
  - 10 essential regex patterns
  - Direct text extraction
  - No spatial analysis
  - Calculated derived fields

### Benefits of Simplified Approach
- **87% code reduction** (1,735 vs ~13,000+ lines)
- **10x faster** processing
- **User-centric**: Focus on actual value (net earnings, deductions, investment returns)
- **Extensible**: User can edit "Other Earnings/Deductions" breakdowns
- **Future-proof**: New codes automatically roll into "Other" category

## Files in This Directory

Currently empty - files will be moved here if needed for reference.

To actually move files here, run:
```bash
# Move complex processors (optional, can be deferred)
git mv PayslipMax/Services/UnifiedDefensePayslipProcessor.swift PayslipMax/Services/Processing/Legacy/
git mv PayslipMax/Services/Extraction/UniversalPayCodeSearchEngine.swift PayslipMax/Services/Processing/Legacy/
git mv PayslipMax/Services/Extraction/SpatialAnalyzer.swift PayslipMax/Services/Processing/Legacy/
```

## Rollback Instructions

If you need to revert to the complex parsing system:

```bash
# Switch to canary1 branch (607 passing tests with complex system)
git checkout canary1

# Or cherry-pick specific files from canary1
git checkout canary1 -- PayslipMax/Services/UnifiedDefensePayslipProcessor.swift
```

## Historical Context

**Created**: Pre-October 2025  
**Archived**: October 13, 2025  
**Reason**: Simplified parsing strategy implementation  
**Preserved In**: `canary1` branch (full working state)

## See Also

- `Documentation/SimplifiedParsing_Implementation_Summary.md` - Full implementation details
- `PayslipMax/Services/Parsing/SimplifiedPayslipParser.swift` - Replacement parser
- `PayslipMaxTests/Legacy/` - Archived complex parsing tests

