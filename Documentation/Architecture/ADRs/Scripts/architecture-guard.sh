#!/bin/bash

# PayslipMax Architecture Guard - Real-time Monitoring
# Maintains 94+/100 architecture quality through continuous validation
# Prevents regression of achieved MVVM-SOLID compliance

echo "🛡️ PayslipMax Architecture Guard Active"

# Configuration
MAX_FILE_SIZE=300
WARNING_THRESHOLD=280
SINGLETON_THRESHOLD=270

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to check file size compliance
check_file_sizes() {
    echo -e "${BLUE}📏 Monitoring file size compliance...${NC}"
    local violations=0
    
    while IFS= read -r -d '' file; do
        lines=$(wc -l < "$file")
        filename=$(basename "$file")
        
        if [ "$lines" -gt $MAX_FILE_SIZE ]; then
            echo -e "${RED}🚨 CRITICAL: $filename has $lines lines (EXCEEDS 300)${NC}"
            echo "   Action Required: Extract components immediately"
            violations=$((violations + 1))
        elif [ "$lines" -gt $WARNING_THRESHOLD ]; then
            echo -e "${YELLOW}⚠️  WARNING: $filename has $lines lines (approaching limit)${NC}"
            echo "   Recommendation: Plan component extraction"
        fi
    done < <(find PayslipMax -name "*.swift" -print0)
    
    return $violations
}

# Function to monitor MVVM compliance
check_mvvm_compliance() {
    echo -e "${BLUE}🏗️ Monitoring MVVM architecture compliance...${NC}"
    local violations=0
    
    # Check for SwiftUI imports in Services
    local swiftui_services=$(find PayslipMax/Services -name "*.swift" -exec grep -l "import SwiftUI" {} \; 2>/dev/null | grep -v UIAppearanceService.swift || true)
    
    if [ -n "$swiftui_services" ]; then
        echo -e "${RED}🚨 MVVM VIOLATION: Unauthorized SwiftUI imports in services:${NC}"
        echo "$swiftui_services" | while read -r file; do
            echo "   - $(basename "$file")"
        done
        violations=$((violations + 1))
    fi
    
    # Check for View-Service direct coupling
    local direct_service_calls=$(grep -r "DIContainer\.shared\." PayslipMax/Views/ --include="*.swift" 2>/dev/null || true)
    if [ -n "$direct_service_calls" ]; then
        echo -e "${YELLOW}⚠️  POTENTIAL VIOLATION: Direct DI container access in Views:${NC}"
        echo "$direct_service_calls"
    fi
    
    return $violations
}

# Function to monitor async compliance
check_async_compliance() {
    echo -e "${BLUE}⚡ Monitoring async-first compliance...${NC}"
    local violations=0
    
    # Check for DispatchSemaphore usage
    local semaphore_usage=$(grep -r "DispatchSemaphore" PayslipMax/ --include="*.swift" 2>/dev/null || true)
    if [ -n "$semaphore_usage" ]; then
        echo -e "${RED}🚨 ASYNC VIOLATION: DispatchSemaphore usage detected:${NC}"
        echo "$semaphore_usage" | head -5  # Show first 5 occurrences
        violations=$((violations + 1))
    fi
    
    # Check for blocking I/O operations
    local blocking_io=$(grep -r "\.wait()" PayslipMax/ --include="*.swift" 2>/dev/null || true)
    if [ -n "$blocking_io" ]; then
        echo -e "${YELLOW}⚠️  WARNING: Potentially blocking operations:${NC}"
        echo "$blocking_io" | head -3
    fi
    
    return $violations
}

# Function to monitor singleton usage
check_singleton_usage() {
    echo -e "${BLUE}🔗 Monitoring singleton usage...${NC}"
    
    local singleton_count=$(grep -r "\.shared" PayslipMax/ --include="*.swift" 2>/dev/null | wc -l)
    
    if [ "$singleton_count" -gt $SINGLETON_THRESHOLD ]; then
        echo -e "${YELLOW}⚠️  WARNING: High singleton usage ($singleton_count usages)${NC}"
        echo "   Target: <$SINGLETON_THRESHOLD for optimal SOLID compliance"
    else
        echo -e "${GREEN}✅ Singleton usage within acceptable range ($singleton_count usages)${NC}"
    fi
}

# Function to check memory efficiency patterns
check_memory_patterns() {
    echo -e "${BLUE}🧠 Monitoring memory efficiency patterns...${NC}"
    
    # Check for large file handling patterns
    local large_file_handlers=$(grep -r "LargePDFStreamingProcessor\|EnhancedMemoryManager" PayslipMax/ --include="*.swift" 2>/dev/null | wc -l)
    
    if [ "$large_file_handlers" -gt 0 ]; then
        echo -e "${GREEN}✅ Memory optimization patterns detected ($large_file_handlers usages)${NC}"
    fi
    
    # Check for potential memory leaks
    local retain_cycles=$(grep -r "strong self" PayslipMax/ --include="*.swift" 2>/dev/null || true)
    if [ -n "$retain_cycles" ]; then
        echo -e "${YELLOW}⚠️  WARNING: Potential retain cycles detected${NC}"
        echo "$retain_cycles" | head -3
    fi
}

# Function to generate architecture health report
generate_health_report() {
    echo -e "${BLUE}📊 Architecture Health Report${NC}"
    echo "=================================="
    
    # File size compliance
    local total_files=$(find PayslipMax -name "*.swift" | wc -l)
    local compliant_files=$(find PayslipMax -name "*.swift" -exec sh -c 'test $(wc -l < "$1") -le 300' _ {} \; -print 2>/dev/null | wc -l)
    local compliance_percentage=$(echo "scale=1; $compliant_files * 100 / $total_files" | bc 2>/dev/null || echo "N/A")
    
    echo "File Size Compliance: $compliance_percentage% ($compliant_files/$total_files)"
    
    # Async usage
    local async_usage=$(grep -r "async\|await" PayslipMax/ --include="*.swift" 2>/dev/null | wc -l)
    echo "Async Operations: $async_usage usages detected"
    
    # Protocol usage
    local protocol_count=$(grep -r "protocol.*{" PayslipMax/ --include="*.swift" 2>/dev/null | wc -l)
    echo "Protocol Abstractions: $protocol_count protocols defined"
    
    # Overall health
    if [ "$compliance_percentage" = "N/A" ] || [ "$(echo "$compliance_percentage >= 85" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
        echo -e "Overall Health: ${GREEN}EXCELLENT (Target: 94+/100)${NC}"
    else
        echo -e "Overall Health: ${YELLOW}NEEDS ATTENTION${NC}"
    fi
}

# Main execution
main() {
    echo "Starting architecture guard patrol..."
    echo "===================================="
    
    local total_violations=0
    
    check_file_sizes
    total_violations=$((total_violations + $?))
    
    check_mvvm_compliance
    total_violations=$((total_violations + $?))
    
    check_async_compliance
    total_violations=$((total_violations + $?))
    
    check_singleton_usage
    check_memory_patterns
    
    echo ""
    generate_health_report
    
    echo ""
    if [ $total_violations -eq 0 ]; then
        echo -e "${GREEN}🎉 Architecture guard patrol complete - All systems healthy!${NC}"
    else
        echo -e "${RED}⚠️  Architecture guard patrol complete - $total_violations violations detected${NC}"
        echo -e "${YELLOW}Please address violations to maintain 94+/100 quality score${NC}"
    fi
    
    return $total_violations
}

# Execute main function
main "$@"
