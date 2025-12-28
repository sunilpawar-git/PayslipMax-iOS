#!/bin/bash

# PayslipMax Pre-Commit Enforcement Script
# Prevents technical debt introduction through automated checks
# Based on achieved 94+/100 architecture quality score

set -e

echo "🔍 PayslipMax Quality Gate Enforcement..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track violations
VIOLATIONS=0

echo "📏 Checking file size compliance (300-line rule)..."
while IFS= read -r -d '' file; do
    lines=$(wc -l < "$file")
    filename=$(basename "$file")

    # Skip test files for now (lower priority during roadmap execution)
    if [[ "$file" == *"Test"* || "$file" == *"Mock"* ]]; then
        continue
    fi

    # Exempt known legacy large files (Tech Debt to be addressed later)
    if [[ "$filename" == "EmergencyRollbackProtocol.swift" || \
          "$filename" == "DIContainer.swift" || \
          "$filename" == "FinancialCalculationUtility.swift" || \
          "$filename" == "AppError.swift" || \
          "$filename" == "UserAnalyticsService.swift" || \
          "$filename" == "PayslipDetailPDFHandler.swift" || \
          "$filename" == "ComponentClassificationRules.swift" || \
          "$filename" == "PayslipSectionClassifier.swift" || \
          "$filename" == "EnhancedProcessingPipelineIntegrator.swift" || \
          "$filename" == "SimplifiedPayslipParser.swift" ]]; then
        continue
    fi

    if [ "$lines" -gt 300 ]; then
        echo -e "${RED}❌ VIOLATION: $filename has $lines lines (>300)${NC}"
        echo -e "${RED}🔧 Run './Scripts/component-extraction-helper.sh $file' to fix${NC}"
        VIOLATIONS=$((VIOLATIONS + 1))

        # Log violation for tracking
        echo "$(date): FILE_SIZE - $file - $lines lines" >> .architecture-violations.log
    elif [ "$lines" -gt 280 ]; then
        echo -e "${YELLOW}⚠️  WARNING: $filename has $lines lines (approaching limit)${NC}"
        echo -e "${YELLOW}💡 Start planning component extraction at 280+ lines${NC}"
    fi
done < <(find PayslipMax -name "*.swift" -print0 2>/dev/null || true)

echo "🏗️ Checking MVVM compliance..."
SWIFTUI_IN_SERVICES=$(find PayslipMax/Services -name "*.swift" -exec grep -l "import SwiftUI" {} \; 2>/dev/null | grep -v UIAppearanceService.swift || true)
if [ -n "$SWIFTUI_IN_SERVICES" ]; then
    echo -e "${RED}❌ MVVM VIOLATION: SwiftUI imported in services:${NC}"
    echo "$SWIFTUI_IN_SERVICES"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

echo "⚡ Checking async-first compliance..."
# Only count actual code usage, not comments or documentation
DISPATCH_SEMAPHORE=$(grep -r "DispatchSemaphore" PayslipMax/ --include="*.swift" 2>/dev/null | grep -v "//.*DispatchSemaphore" | grep -v "///.*DispatchSemaphore" | grep -v "/\*.*DispatchSemaphore.*\*/" || true)
if [ -n "$DISPATCH_SEMAPHORE" ]; then
    echo -e "${RED}❌ ASYNC VIOLATION: DispatchSemaphore usage found:${NC}"
    echo "$DISPATCH_SEMAPHORE"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

echo "🧪 Verifying build integrity..."
# Use iPhone 17 Pro (project standard) or fallback to any available iPhone simulator
if ! xcodebuild -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' build -quiet >/dev/null 2>&1; then
    # Fallback: try any iPhone simulator
    if ! xcodebuild -scheme PayslipMax -destination 'generic/platform=iOS Simulator' build -quiet >/dev/null 2>&1; then
        echo -e "${RED}❌ BUILD FAILURE: Project does not compile${NC}"
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
fi

# Final verdict
if [ $VIOLATIONS -eq 0 ]; then
    echo -e "${GREEN}✅ All quality gates passed! Commit approved.${NC}"
    exit 0
else
    echo -e "${RED}❌ Quality gate failures detected ($VIOLATIONS violations)${NC}"
    echo -e "${RED}Please fix violations before committing.${NC}"
    exit 1
fi
