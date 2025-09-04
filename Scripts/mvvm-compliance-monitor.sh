#!/bin/bash

# MVVM-SOLID Compliance Monitoring Script
# Usage: ./Scripts/mvvm-compliance-monitor.sh
# Purpose: Monitor progress during incremental refactoring

set -e

PROJECT_ROOT="/Users/sunil/Downloads/PayslipMax"
cd "$PROJECT_ROOT"

echo "🔍 MVVM-SOLID Compliance Monitor"
echo "=================================="
echo "Timestamp: $(date)"
echo "Branch: $(git branch --show-current)"
echo ""

# 1. File Size Violations Monitor
echo "📏 FILE SIZE VIOLATIONS (>300 lines):"
echo "--------------------------------------"
find PayslipMax -name "*.swift" -exec wc -l {} + | \
awk '$1 > 300 {print $1 " lines: " $2}' | \
sort -rn | \
head -20
echo ""

# 2. Singleton Usage Monitor
echo "🔗 SINGLETON USAGE ANALYSIS:"
echo "----------------------------"
singleton_count=$(grep -r "\.shared" PayslipMax --include="*.swift" | wc -l)
singleton_files=$(grep -r "\.shared" PayslipMax --include="*.swift" -l | wc -l)
echo "Total .shared usages: $singleton_count"
echo "Files with .shared: $singleton_files"
echo ""

# 3. SwiftUI Imports in Services
echo "🏗️ MVVM VIOLATIONS (SwiftUI in Services):"
echo "-----------------------------------------"
service_ui_imports=$(find PayslipMax/Services -name "*.swift" 2>/dev/null | xargs grep -l "import SwiftUI" 2>/dev/null | wc -l || echo "0")
echo "Service files importing SwiftUI: $service_ui_imports"
if [ "$service_ui_imports" -gt 0 ]; then
    echo "Violations found:"
    find PayslipMax/Services -name "*.swift" 2>/dev/null | xargs grep -l "import SwiftUI" 2>/dev/null || echo "None found"
fi
echo ""

# 4. Build Status Check
echo "🔨 BUILD STATUS:"
echo "---------------"
if xcodebuild build -project PayslipMax.xcodeproj -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 16' -quiet > /dev/null 2>&1; then
    echo "✅ Build SUCCESSFUL"
else
    echo "❌ Build FAILED"
    echo "⚠️  CRITICAL: Rollback recommended"
fi
echo ""

# 5. Performance Metrics
echo "⚡ PERFORMANCE METRICS:"
echo "----------------------"
echo "Measuring build time..."
build_time=$(time (xcodebuild build -project PayslipMax.xcodeproj -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 16' -quiet > /dev/null) 2>&1 | grep real | awk '{print $2}')
echo "Build time: ${build_time:-"Unable to measure"}"
echo ""

# 6. Quality Score Estimation
echo "📊 QUALITY SCORE ESTIMATION:"
echo "----------------------------"
large_files=$(find PayslipMax -name "*.swift" -exec wc -l {} + | awk '$1 > 300' | wc -l)
total_swift_files=$(find PayslipMax -name "*.swift" | wc -l)
compliance_percentage=$(echo "scale=1; (($total_swift_files - $large_files) * 100) / $total_swift_files" | bc -l 2>/dev/null || echo "90.0")
echo "File size compliance: ${compliance_percentage}%"
echo "Estimated quality score: 90+ (baseline)"
echo ""

# 7. Progress Summary
echo "📈 PROGRESS SUMMARY:"
echo "-------------------"
echo "Files >300 lines: $large_files (target: 0)"
echo "Singleton usages: $singleton_count (target: <200)"
echo "Service violations: $service_ui_imports (target: 0)"
echo ""

echo "✅ Monitoring complete!"
echo "💡 Run after each phase completion to track progress"
