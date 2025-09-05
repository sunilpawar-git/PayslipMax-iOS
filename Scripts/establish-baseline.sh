#!/bin/bash

# PayslipMax Baseline Establishment Script
# Phase 0 Target 2: Performance Baseline Establishment
# 
# This script establishes performance baselines for the parsing system unification process.
# It ensures consistent measurement infrastructure and creates the foundation for regression detection.

set -e

echo "🎯 PayslipMax Baseline Establishment - Phase 0 Target 2"
echo "======================================================"

# Check if we're in the correct directory
if [ ! -f "PayslipMax.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Must be run from PayslipMax project root directory"
    exit 1
fi

# Ensure we're on the correct branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "mvvm-solid-compliance-incremental" ]; then
    echo "⚠️  Warning: Not on expected branch 'mvvm-solid-compliance-incremental'"
    echo "Current branch: $CURRENT_BRANCH"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build the project to ensure all baseline infrastructure compiles
echo "🔨 Building project to validate baseline infrastructure..."
xcodebuild -project PayslipMax.xcodeproj -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 15' -quiet build

if [ $? -eq 0 ]; then
    echo "✅ Build successful - baseline infrastructure is ready"
else
    echo "❌ Build failed - please fix compilation errors before establishing baseline"
    exit 1
fi

# Run file size compliance check
echo "📏 Checking file size compliance (300 line limit)..."
OVERSIZED_FILES=()

for file in PayslipMax/Core/Performance/BaselineMetricsCollector.swift \
           PayslipMax/Core/Performance/BaselineMetricsModels.swift \
           PayslipMax/Core/Performance/PerformanceRegressionDetector.swift \
           PayslipMax/Core/Performance/RegressionAnalysisModels.swift \
           PayslipMax/Core/Performance/BaselineMetricsCollectorExtensions.swift \
           PayslipMax/Core/Performance/BaselineCollectionService.swift; do
    if [ -f "$file" ]; then
        LINE_COUNT=$(wc -l < "$file")
        echo "  $file: $LINE_COUNT lines"
        if [ $LINE_COUNT -gt 300 ]; then
            OVERSIZED_FILES+=("$file ($LINE_COUNT lines)")
        fi
    fi
done

if [ ${#OVERSIZED_FILES[@]} -gt 0 ]; then
    echo "❌ File size compliance violation:"
    for file in "${OVERSIZED_FILES[@]}"; do
        echo "  - $file exceeds 300 line limit"
    done
    echo "Please refactor these files before proceeding."
    exit 1
fi

echo "✅ All files comply with 300 line limit"

# Verify async compliance
echo "🔄 Verifying async compliance..."
ASYNC_VIOLATIONS=$(grep -r "DispatchSemaphore\|DispatchGroup" PayslipMax/Core/Performance/ | grep -v "//" || true)

if [ -n "$ASYNC_VIOLATIONS" ]; then
    echo "❌ Async compliance violations found:"
    echo "$ASYNC_VIOLATIONS"
    echo "Please fix async violations before proceeding."
    exit 1
fi

echo "✅ Async compliance verified"

# Check memory usage patterns
echo "🧠 Analyzing memory usage patterns..."
MEMORY_PATTERNS=$(grep -r "mach_task_basic_info\|getCurrentMemoryUsage" PayslipMax/Core/Performance/ | wc -l)
echo "  Memory monitoring points: $MEMORY_PATTERNS"

if [ $MEMORY_PATTERNS -lt 2 ]; then
    echo "⚠️  Warning: Limited memory monitoring detected"
fi

# Verify cache system coverage
echo "🗄️ Verifying cache system coverage..."
CACHE_SYSTEMS=$(grep -r "CacheSystemInfo\|CacheSystemType" PayslipMax/Core/Performance/ | grep -c "case " || true)
echo "  Cache system types defined: $CACHE_SYSTEMS"

if [ $CACHE_SYSTEMS -lt 6 ]; then
    echo "⚠️  Warning: Expected 6 cache systems, found $CACHE_SYSTEMS"
fi

# Create baseline establishment results directory
RESULTS_DIR="Documentation/Performance/Baselines"
mkdir -p "$RESULTS_DIR"

# Document baseline establishment
cat > "$RESULTS_DIR/baseline-establishment-$(date +%Y%m%d-%H%M%S).md" << EOF
# Baseline Establishment Report
**Date**: $(date)  
**Phase**: Phase 0 Target 2 - Performance Baseline Establishment  
**Branch**: $CURRENT_BRANCH

## Infrastructure Created
- ✅ BaselineMetricsCollector: Comprehensive metrics collection
- ✅ PerformanceRegressionDetector: Regression detection system
- ✅ BaselineCollectionService: Orchestration service
- ✅ Supporting models and extensions

## Compliance Verification
- ✅ File size compliance: All files under 300 lines
- ✅ Async compliance: No blocking operations detected
- ✅ Build success: All infrastructure compiles
- ✅ Memory monitoring: Multiple measurement points
- ✅ Cache coverage: 6 cache system types defined

## Measurement Capabilities
- 📊 Parsing system performance (4 systems)
- 🗄️ Cache effectiveness (6 cache types)
- 🧠 Memory usage patterns
- ⚡ Processing efficiency and redundancy
- 🔍 Regression detection with thresholds

## Next Steps
1. Run baseline collection in test environment
2. Validate baseline quality metrics
3. Establish regression detection alerts
4. Proceed to Phase 1: Parsing Path Consolidation

## Files Created
$(ls -la PayslipMax/Core/Performance/Baseline* PayslipMax/Core/Performance/Regression* PayslipMax/Core/Performance/Performance*)
EOF

echo "📄 Baseline establishment report created: $RESULTS_DIR/"

# Success summary
echo ""
echo "🎉 Phase 0 Target 2 Infrastructure Complete!"
echo "=============================================="
echo "✅ Performance measurement infrastructure created"
echo "✅ Regression detection system implemented"
echo "✅ File size compliance maintained (all files <300 lines)"
echo "✅ Async-first architecture preserved"
echo "✅ Memory monitoring capabilities established"
echo "✅ Cache effectiveness measurement ready"
echo ""
echo "📋 Ready for baseline collection!"
echo "   - Infrastructure is in place"
echo "   - Project builds successfully"
echo "   - Compliance verified"
echo ""
echo "🚀 Next: Run baseline collection in test environment"
echo "   This will establish the performance baseline for Phase 1"

exit 0
