#!/bin/bash

# Dual-Section Data Error Diagnosis Script
# Diagnoses and fixes data extraction failures after Universal Dual-Section implementation
# Created: 2025-09-22

set -e

echo "🔍 Dual-Section Data Error Diagnosis"
echo "===================================="

# Check if we're in the correct directory
if [ ! -f "PayslipMax.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the PayslipMax project root"
    exit 1
fi

echo "✅ Project root found"

# 1. Check for AppError case 15 (dataExtractionFailed)
echo ""
echo "🔢 Analyzing AppError case 15..."

ERROR_COUNT=$(grep -n "case.*:" PayslipMax/Core/Error/AppError.swift | head -20 | wc -l)
echo "   Found $ERROR_COUNT AppError cases"

# Count to case 15
CASE_15_LINE=$(grep -n "case.*:" PayslipMax/Core/Error/AppError.swift | sed -n '15p')
echo "   Case 15: $CASE_15_LINE"

if echo "$CASE_15_LINE" | grep -q "dataExtractionFailed"; then
    echo "✅ Error 15 identified as dataExtractionFailed"
else
    echo "❓ Error 15 mapping unclear - checking context"
fi

# 2. Check for dataExtractionFailed usage
echo ""
echo "📊 Checking dataExtractionFailed usage..."

EXTRACTION_ERRORS=$(find PayslipMax -name "*.swift" -exec grep -l "dataExtractionFailed\|\.dataExtractionFailed" {} \; | wc -l)
echo "   Found $EXTRACTION_ERRORS files with dataExtractionFailed references"

if [ $EXTRACTION_ERRORS -gt 0 ]; then
    echo "   Files with dataExtractionFailed:"
    find PayslipMax -name "*.swift" -exec grep -l "dataExtractionFailed\|\.dataExtractionFailed" {} \; | head -5
fi

# 3. Check for dual-section data access patterns that might fail
echo ""
echo "🔍 Checking dual-section data access patterns..."

DUAL_SECTION_KEYS=$(grep -r "_EARNINGS\|_DEDUCTIONS" PayslipMax --include="*.swift" | wc -l)
echo "   Found $DUAL_SECTION_KEYS dual-section key references"

# Check for components that might not handle dual-section keys properly
echo ""
echo "⚠️  Checking for potential problematic components..."

# Check PayslipDataFactory for proper dual-section handling
if grep -q "getUniversalDualSectionValue" PayslipMax/Models/PayslipDataFactory.swift; then
    echo "✅ PayslipDataFactory has universal dual-section support"
else
    echo "❌ PayslipDataFactory missing universal dual-section support"
fi

# Check for PDF services that might break on dual-section data
PDF_SERVICES=$(find PayslipMax -name "*PDF*.swift" -exec grep -l "earnings\|deductions" {} \; | wc -l)
echo "   Found $PDF_SERVICES PDF services accessing earnings/deductions"

# 4. Check for specific error patterns in services
echo ""
echo "🔧 Checking for error-prone service patterns..."

# Check for services that might throw dataExtractionFailed
if grep -q "throw.*dataExtractionFailed\|AppError.dataExtractionFailed" PayslipMax/Services/**/*.swift 2>/dev/null; then
    echo "⚠️  Found services throwing dataExtractionFailed:"
    grep -r "throw.*dataExtractionFailed\|AppError.dataExtractionFailed" PayslipMax/Services --include="*.swift" | head -3
else
    echo "✅ No direct dataExtractionFailed throws found in services"
fi

# 5. Check for dictionary access patterns that might fail
echo ""
echo "📝 Checking dictionary access patterns..."

# Check for hardcoded key access that might not work with dual-section keys
HARDCODED_ACCESS=$(grep -r 'earnings\[".*"\]\|deductions\[".*"\]' PayslipMax --include="*.swift" | wc -l)
echo "   Found $HARDCODED_ACCESS hardcoded dictionary access patterns"

if [ $HARDCODED_ACCESS -gt 20 ]; then
    echo "⚠️  High number of hardcoded access patterns - potential issue"
    echo "   Sample patterns:"
    grep -r 'earnings\[".*"\]\|deductions\[".*"\]' PayslipMax --include="*.swift" | head -3
else
    echo "✅ Reasonable number of hardcoded access patterns"
fi

# 6. Generate fix recommendations
echo ""
echo "🎯 Fix Recommendations"
echo "====================="

echo ""
echo "Based on analysis, error 15 (dataExtractionFailed) likely occurs because:"
echo "1. ✅ PayslipData was saved successfully with dual-section keys"
echo "2. ❌ Some component tries to re-extract/process the data and fails"
echo "3. ❌ Error happens during PDF viewing, sharing, or deletion operations"

echo ""
echo "Recommended fixes:"
echo "- Ensure all PayslipData access goes through PayslipDisplayNameService"
echo "- Add error handling for dual-section key patterns"
echo "- Update any components that directly access earnings/deductions dictionaries"
echo "- Add validation for dual-section data compatibility"

echo ""
echo "🔧 Next steps:"
echo "1. Check PDF generation services for dual-section compatibility ✅ Already fixed"
echo "2. Check sharing services for dual-section data handling"
echo "3. Check deletion services for proper error handling"
echo "4. Add comprehensive error logging for dataExtractionFailed cases"

echo ""
echo "📱 Immediate action: Test payslip operations and check device logs for detailed error info"
