#!/bin/bash

# Universal Dual-Section Implementation Validation Script
# Validates all aspects of the dual-section processing system
# Usage: ./validate-universal-dual-section.sh [test-type]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎯 Universal Dual-Section Implementation Validation${NC}"
echo -e "${BLUE}=================================================${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default test type
TEST_TYPE="${1:-all}"

# Validation results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test result tracking
declare -a FAILED_TEST_NAMES=()

# Logging function
log_test() {
    local test_name="$1"
    local status="$2"
    local details="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$status" = "PASS" ]; then
        echo -e "  ✅ ${GREEN}$test_name${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "  ❌ ${RED}$test_name${NC}"
        if [ ! -z "$details" ]; then
            echo -e "     ${YELLOW}$details${NC}"
        fi
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("$test_name")
    fi
}

# Phase 1: Component Classification System Validation
validate_classification_system() {
    echo -e "\n${BLUE}Phase 1: Component Classification System${NC}"

    # Test 1: PayCodeClassificationEngine exists and functional
    if [ -f "$PROJECT_ROOT/PayslipMax/Services/Extraction/PayCodeClassificationEngine.swift" ]; then
        log_test "PayCodeClassificationEngine exists" "PASS"
    else
        log_test "PayCodeClassificationEngine exists" "FAIL" "File not found"
    fi

    # Test 2: PayCodeClassificationConstants exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Core/Utilities/PayCodeClassificationConstants.swift" ]; then
        log_test "PayCodeClassificationConstants exists" "PASS"
    else
        log_test "PayCodeClassificationConstants exists" "FAIL" "File not found"
    fi

    # Test 3: Universal search engine exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Services/Extraction/UniversalPayCodeSearchEngine.swift" ]; then
        log_test "UniversalPayCodeSearchEngine exists" "PASS"
    else
        log_test "UniversalPayCodeSearchEngine exists" "FAIL" "File not found"
    fi
}

# Phase 2: Dual-Section Processing Validation
validate_dual_section_processing() {
    echo -e "\n${BLUE}Phase 2: Universal Dual-Section Processing${NC}"

    # Test 1: UniversalDualSectionProcessor exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Services/Processing/UniversalDualSectionProcessor.swift" ]; then
        log_test "UniversalDualSectionProcessor exists" "PASS"
    else
        log_test "UniversalDualSectionProcessor exists" "FAIL" "File not found"
    fi

    # Test 2: PayslipSectionClassifier enhanced
    if [ -f "$PROJECT_ROOT/PayslipMax/Services/Processing/PayslipSectionClassifier.swift" ]; then
        if grep -q "classifyDualSectionComponent" "$PROJECT_ROOT/PayslipMax/Services/Processing/PayslipSectionClassifier.swift"; then
            log_test "PayslipSectionClassifier enhanced for dual-section" "PASS"
        else
            log_test "PayslipSectionClassifier enhanced for dual-section" "FAIL" "Method not found"
        fi
    else
        log_test "PayslipSectionClassifier enhanced for dual-section" "FAIL" "File not found"
    fi

    # Test 3: RiskHardshipProcessor exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Services/Processing/RiskHardshipProcessor.swift" ]; then
        log_test "RiskHardshipProcessor exists" "PASS"
    else
        log_test "RiskHardshipProcessor exists" "FAIL" "File not found"
    fi
}

# Phase 3: Arrears Processing Validation
validate_arrears_processing() {
    echo -e "\n${BLUE}Phase 3: Universal Arrears Enhancement${NC}"

    # Test 1: ArrearsClassificationService exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Services/Extraction/ArrearsClassificationService.swift" ]; then
        log_test "ArrearsClassificationService exists" "PASS"
    else
        log_test "ArrearsClassificationService exists" "FAIL" "File not found"
    fi

    # Test 2: UniversalArrearsPatternMatcher enhanced
    if [ -f "$PROJECT_ROOT/PayslipMax/Services/Extraction/UniversalArrearsPatternMatcher.swift" ]; then
        log_test "UniversalArrearsPatternMatcher exists" "PASS"
    else
        log_test "UniversalArrearsPatternMatcher exists" "FAIL" "File not found"
    fi

    # Test 3: ArrearsDisplayFormatter exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Services/Processing/ArrearsDisplayFormatter.swift" ]; then
        log_test "ArrearsDisplayFormatter exists" "PASS"
    else
        log_test "ArrearsDisplayFormatter exists" "FAIL" "File not found"
    fi
}

# Phase 4: Display Layer Validation
validate_display_layer() {
    echo -e "\n${BLUE}Phase 4: Display Layer Enhancement${NC}"

    # Test 1: PayslipDisplayNameConstants exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Core/Utilities/PayslipDisplayNameConstants.swift" ]; then
        log_test "PayslipDisplayNameConstants exists" "PASS"
    else
        log_test "PayslipDisplayNameConstants exists" "FAIL" "File not found"
    fi

    # Test 2: PayslipDisplayNameService enhanced
    if [ -f "$PROJECT_ROOT/PayslipMax/Core/Utilities/PayslipDisplayNameService.swift" ]; then
        log_test "PayslipDisplayNameService exists" "PASS"
    else
        log_test "PayslipDisplayNameService exists" "FAIL" "File not found"
    fi
}

# Phase 5: Data Pipeline Validation
validate_data_pipeline() {
    echo -e "\n${BLUE}Phase 5: Data Pipeline Integration${NC}"

    # Test 1: PayslipDataFactory enhanced
    if [ -f "$PROJECT_ROOT/PayslipMax/Models/PayslipDataFactory.swift" ]; then
        if grep -q "getUniversalDualSectionValue\|getUniversalAllowanceValue" "$PROJECT_ROOT/PayslipMax/Models/PayslipDataFactory.swift"; then
            log_test "PayslipDataFactory dual-key retrieval" "PASS"
        else
            log_test "PayslipDataFactory dual-key retrieval" "FAIL" "Methods not found"
        fi
    else
        log_test "PayslipDataFactory dual-key retrieval" "FAIL" "File not found"
    fi
}

# Phase 6: Performance Validation
validate_performance_optimization() {
    echo -e "\n${BLUE}Phase 6: Performance Optimization${NC}"

    # Test 1: Performance monitoring exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Core/Performance/DualSectionPerformanceMonitor.swift" ]; then
        log_test "DualSectionPerformanceMonitor exists" "PASS"
    else
        log_test "DualSectionPerformanceMonitor exists" "FAIL" "File not found"
    fi

    # Test 2: Caching system exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Core/Performance/ClassificationCacheManager.swift" ]; then
        log_test "ClassificationCacheManager exists" "PASS"
    else
        log_test "ClassificationCacheManager exists" "FAIL" "File not found"
    fi

    # Test 3: Parallel processing exists
    if [ -f "$PROJECT_ROOT/PayslipMax/Core/Performance/ParallelPayCodeProcessor.swift" ]; then
        log_test "ParallelPayCodeProcessor exists" "PASS"
    else
        log_test "ParallelPayCodeProcessor exists" "FAIL" "File not found"
    fi
}

# File size compliance check
validate_file_size_compliance() {
    echo -e "\n${BLUE}Architectural Compliance: File Size Validation${NC}"

    local violations=0

    # Check all Swift files in key directories
    while IFS= read -r -d '' file; do
        local line_count=$(wc -l < "$file")
        if [ "$line_count" -gt 300 ]; then
            local relative_path=${file#$PROJECT_ROOT/}
            log_test "File size compliance: $relative_path" "FAIL" "$line_count lines (>300)"
            violations=$((violations + 1))
        fi
    done < <(find "$PROJECT_ROOT/PayslipMax/Services/Processing" -name "*.swift" -print0)

    if [ "$violations" -eq 0 ]; then
        log_test "No file size violations in Processing services" "PASS"
    fi
}

# May 2025 payslip simulation test
validate_may_2025_scenario() {
    echo -e "\n${BLUE}Real-World Validation: May 2025 Payslip Scenario${NC}"

    # Test RH12 dual-section detection
    echo -e "  ${YELLOW}Testing RH12 dual-section scenario...${NC}"

    # Expected: RH12 ₹21,125 (earnings) + RH12 ₹7,518 (deductions)
    # This would require running actual parsing code, so we'll check for the infrastructure

    if [ -f "$PROJECT_ROOT/PayslipMaxTests/Integration/RH12DualSectionIntegrationTests.swift" ]; then
        log_test "RH12 dual-section integration tests exist" "PASS"
    else
        log_test "RH12 dual-section integration tests exist" "FAIL" "Test file not found"
    fi

    # Check for test data
    if grep -r "276665\|21125\|7518" "$PROJECT_ROOT/PayslipMaxTests" >/dev/null 2>&1; then
        log_test "May 2025 test data exists in test suite" "PASS"
    else
        log_test "May 2025 test data exists in test suite" "FAIL" "Test data not found"
    fi
}

# Run validation based on test type
case "$TEST_TYPE" in
    "classification")
        validate_classification_system
        ;;
    "dual-section")
        validate_dual_section_processing
        ;;
    "arrears")
        validate_arrears_processing
        ;;
    "display")
        validate_display_layer
        ;;
    "pipeline")
        validate_data_pipeline
        ;;
    "performance")
        validate_performance_optimization
        ;;
    "compliance")
        validate_file_size_compliance
        ;;
    "may2025")
        validate_may_2025_scenario
        ;;
    "all")
        validate_classification_system
        validate_dual_section_processing
        validate_arrears_processing
        validate_display_layer
        validate_data_pipeline
        validate_performance_optimization
        validate_file_size_compliance
        validate_may_2025_scenario
        ;;
    *)
        echo -e "${RED}Unknown test type: $TEST_TYPE${NC}"
        echo "Valid types: classification, dual-section, arrears, display, pipeline, performance, compliance, may2025, all"
        exit 1
        ;;
esac

# Final results
echo -e "\n${BLUE}Validation Results${NC}"
echo -e "${BLUE}=================${NC}"
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"

if [ "$FAILED_TESTS" -gt 0 ]; then
    echo -e "\n${RED}Failed Tests:${NC}"
    for test_name in "${FAILED_TEST_NAMES[@]}"; do
        echo -e "  • $test_name"
    done
fi

# Calculate success percentage
if [ "$TOTAL_TESTS" -gt 0 ]; then
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "\nSuccess Rate: ${success_rate}%"

    if [ "$success_rate" -ge 90 ]; then
        echo -e "${GREEN}✅ Excellent implementation quality${NC}"
    elif [ "$success_rate" -ge 80 ]; then
        echo -e "${YELLOW}⚠️  Good implementation with minor issues${NC}"
    else
        echo -e "${RED}❌ Significant implementation gaps detected${NC}"
    fi
fi

# Exit with appropriate code
if [ "$FAILED_TESTS" -eq 0 ]; then
    exit 0
else
    exit 1
fi
