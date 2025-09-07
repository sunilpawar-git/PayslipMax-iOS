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

# Build mode for Xcode integration
build_mode() {
    echo -e "${BLUE}🔍 Architecture Quality Gate - Build Mode${NC}"
    local violations=0
    
    # Quick file size check only for build speed
    local large_files=$(find PayslipMax -name "*.swift" -exec sh -c 'test $(wc -l < "$1") -gt 300' _ {} \; -print 2>/dev/null | wc -l)
    
    if [ "$large_files" -gt 0 ]; then
        echo -e "${RED}❌ $large_files files exceed 300-line limit${NC}"
        violations=$((violations + 1))
    fi
    
    # Quick MVVM check
    local swiftui_in_services=$(find PayslipMax/Services -name "*.swift" -exec grep -l "import SwiftUI" {} \; 2>/dev/null | grep -v UIAppearanceService.swift | wc -l)
    if [ "$swiftui_in_services" -gt 0 ]; then
        echo -e "${RED}❌ SwiftUI imports detected in services${NC}"
        violations=$((violations + 1))
    fi
    
    return $violations
}

# CI mode for automated pipelines
ci_mode() {
    echo "ARCHITECTURE_COMPLIANCE_CHECK_START"
    local violations=0
    
    # Comprehensive check for CI
    check_file_sizes
    violations=$((violations + $?))
    
    check_mvvm_compliance  
    violations=$((violations + $?))
    
    check_async_compliance
    violations=$((violations + $?))
    
    echo "ARCHITECTURE_COMPLIANCE_CHECK_END"
    echo "VIOLATIONS_FOUND=$violations"
    
    return $violations
}

# Generate detailed report
generate_report() {
    echo "# PayslipMax Architecture Compliance Report"
    echo "Generated: $(date)"
    echo ""
    
    generate_health_report
    
    echo ""
    echo "## Detailed Analysis"
    check_file_sizes
    check_mvvm_compliance
    check_async_compliance
    check_singleton_usage
    check_memory_patterns
}

# Count violations for automation
count_violations() {
    local violations=0
    
    # Count file size violations
    local large_files=$(find PayslipMax -name "*.swift" -exec sh -c 'test $(wc -l < "$1") -gt 300' _ {} \; -print 2>/dev/null | wc -l)
    violations=$((violations + large_files))
    
    # Count MVVM violations
    local mvvm_violations=$(find PayslipMax/Services -name "*.swift" -exec grep -l "import SwiftUI" {} \; 2>/dev/null | grep -v UIAppearanceService.swift | wc -l)
    violations=$((violations + mvvm_violations))
    
    echo $violations
}

# Provide fix suggestions
fix_suggestions() {
    echo -e "${BLUE}🔧 Architecture Fix Suggestions${NC}"
    echo "================================="
    
    # Find largest files
    echo -e "${CYAN}Largest files requiring immediate attention:${NC}"
    find PayslipMax -name "*.swift" -exec sh -c 'echo "$(wc -l < "$1") $1"' _ {} \; | sort -nr | head -5 | while read size file; do
        if [ "$size" -gt 300 ]; then
            echo "  📄 $(basename "$file"): $size lines"
            echo "     💡 Run: ./Scripts/component-extraction-helper.sh \"$file\""
        fi
    done
}

# Main execution with mode support
main() {
    case "$1" in
        --build-mode)
            build_mode
            ;;
        --ci-mode)
            ci_mode
            ;;
        --report)
            generate_report
            ;;
        --count-violations)
            count_violations
            ;;
        --fix-suggestions)
            fix_suggestions
            ;;
        --help)
            echo "PayslipMax Architecture Guard"
            echo "Usage: $0 [--build-mode|--ci-mode|--report|--count-violations|--fix-suggestions|--help]"
            echo ""
            echo "Modes:"
            echo "  --build-mode       Fast check for Xcode build integration"
            echo "  --ci-mode          Comprehensive check for CI/CD pipelines"
            echo "  --report           Generate detailed compliance report"
            echo "  --count-violations Count total violations for automation"
            echo "  --fix-suggestions  Provide specific fix suggestions"
            echo "  --help            Show this help message"
            ;;
        *)
            # Default comprehensive check
            echo "🛡️ PayslipMax Architecture Quality Gate"
            echo "======================================="
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
                echo ""
                fix_suggestions
            fi
            
            return $total_violations
            ;;
    esac
}

# Execute main function
main "$@"
