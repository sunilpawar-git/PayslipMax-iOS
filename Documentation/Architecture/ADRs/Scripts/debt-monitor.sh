#!/bin/bash

# PayslipMax Technical Debt Monitor
# Monitors key technical debt indicators and prevents new debt accumulation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MAX_FILE_SIZE=300
WARNING_FILE_SIZE=250
PROJECT_DIR="PayslipMax"

echo -e "${BLUE}=== PayslipMax Technical Debt Monitor ===${NC}"
echo "Scanning project for technical debt indicators..."
echo

# Function to print section headers
print_section() {
    echo -e "${BLUE}--- $1 ---${NC}"
}

# Function to print success/failure status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✅ $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

# Initialize counters
total_violations=0
critical_violations=0
warnings=0

# 1. Check for files exceeding size limits
print_section "File Size Analysis"

echo "Checking for files exceeding $MAX_FILE_SIZE lines..."
large_files=$(find $PROJECT_DIR -name "*.swift" -exec wc -l {} + | awk -v max=$MAX_FILE_SIZE '$1 > max {print $2 " (" $1 " lines)"}' | sort -nr)

if [ -z "$large_files" ]; then
    print_status 0 "No files exceed $MAX_FILE_SIZE lines"
else
    echo -e "${RED}Files exceeding $MAX_FILE_SIZE lines:${NC}"
    echo "$large_files"
    critical_count=$(echo "$large_files" | wc -l)
    critical_violations=$((critical_violations + critical_count))
    echo -e "${RED}Critical violations: $critical_count${NC}"
fi

echo
echo "Checking for files approaching size limit ($WARNING_FILE_SIZE+ lines)..."
warning_files=$(find $PROJECT_DIR -name "*.swift" -exec wc -l {} + | awk -v warn=$WARNING_FILE_SIZE -v max=$MAX_FILE_SIZE '$1 >= warn && $1 <= max {print $2 " (" $1 " lines)"}' | sort -nr)

if [ -z "$warning_files" ]; then
    print_status 0 "No files approaching size limit"
else
    echo -e "${YELLOW}Files approaching size limit:${NC}"
    echo "$warning_files"
    warning_count=$(echo "$warning_files" | wc -l)
    warnings=$((warnings + warning_count))
    echo -e "${YELLOW}Warnings: $warning_count${NC}"
fi

echo

# 2. Check for DispatchSemaphore usage (concurrency anti-pattern)
print_section "Concurrency Anti-Pattern Detection"

semaphore_usage=$(grep -r "DispatchSemaphore" $PROJECT_DIR --include="*.swift" 2>/dev/null || true)
semaphore_count=$(echo "$semaphore_usage" | grep -v "^$" | wc -l)

if [ "$semaphore_count" -eq 0 ]; then
    print_status 0 "No DispatchSemaphore usage found"
else
    echo -e "${RED}DispatchSemaphore usage found:${NC}"
    echo "$semaphore_usage"
    critical_violations=$((critical_violations + semaphore_count))
    echo -e "${RED}Critical violations: $semaphore_count${NC}"
fi

echo

# 3. Check for fatalError usage (unsafe error handling)
print_section "Error Handling Analysis"

fatal_error_usage=$(grep -r "fatalError" $PROJECT_DIR --include="*.swift" 2>/dev/null || true)
fatal_error_count=$(echo "$fatal_error_usage" | grep -v "^$" | wc -l)

if [ "$fatal_error_count" -eq 0 ]; then
    print_status 0 "No fatalError usage found"
else
    echo -e "${YELLOW}fatalError usage found:${NC}"
    echo "$fatal_error_usage"
    warnings=$((warnings + fatal_error_count))
    echo -e "${YELLOW}Warnings: $fatal_error_count${NC}"
fi

echo

# 4. Check for TODO/FIXME/HACK markers
print_section "Technical Debt Markers"

debt_markers=$(grep -r "TODO\|FIXME\|HACK\|XXX" $PROJECT_DIR --include="*.swift" 2>/dev/null || true)
debt_marker_count=$(echo "$debt_markers" | grep -v "^$" | wc -l)

if [ "$debt_marker_count" -eq 0 ]; then
    print_status 0 "No technical debt markers found"
else
    echo -e "${YELLOW}Technical debt markers found:${NC}"
    echo "$debt_markers" | head -10  # Show first 10
    if [ "$debt_marker_count" -gt 10 ]; then
        echo "... and $((debt_marker_count - 10)) more"
    fi
    warnings=$((warnings + debt_marker_count))
    echo -e "${YELLOW}Total markers: $debt_marker_count${NC}"
fi

echo

# 5. Project Statistics
print_section "Project Statistics"

total_swift_files=$(find $PROJECT_DIR -name "*.swift" | wc -l)
total_lines=$(find $PROJECT_DIR -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print $1}')
average_file_size=$((total_lines / total_swift_files))

echo "Total Swift files: $total_swift_files"
echo "Total lines of code: $total_lines"
echo "Average file size: $average_file_size lines"

echo

# 6. Quality Score Calculation
print_section "Quality Score"

total_violations=$((critical_violations + warnings))
max_possible_score=100
deduction_per_critical=5
deduction_per_warning=1

score=$((max_possible_score - (critical_violations * deduction_per_critical) - (warnings * deduction_per_warning)))
if [ "$score" -lt 0 ]; then
    score=0
fi

echo "Critical violations: $critical_violations"
echo "Warnings: $warnings"
echo "Total violations: $total_violations"
echo

if [ "$score" -ge 90 ]; then
    color=$GREEN
    grade="A"
elif [ "$score" -ge 80 ]; then
    color=$YELLOW
    grade="B"
elif [ "$score" -ge 70 ]; then
    color=$YELLOW
    grade="C"
else
    color=$RED
    grade="F"
fi

echo -e "Quality Score: ${color}$score/100 (Grade: $grade)${NC}"

echo

# 7. Recommendations
print_section "Recommendations"

if [ "$critical_violations" -gt 0 ]; then
    echo -e "${RED}🚨 CRITICAL: Address critical violations before proceeding${NC}"
fi

if [ "$warnings" -gt 5 ]; then
    echo -e "${YELLOW}⚠️  Consider addressing warnings in next sprint${NC}"
fi

if [ "$score" -ge 90 ]; then
    echo -e "${GREEN}🎉 Excellent code quality! Keep it up!${NC}"
elif [ "$score" -ge 80 ]; then
    echo -e "${YELLOW}👍 Good code quality, minor improvements needed${NC}"
else
    echo -e "${RED}📈 Code quality needs improvement${NC}"
fi

echo

# 8. Exit status
if [ "$critical_violations" -gt 0 ]; then
    echo -e "${RED}❌ Quality gate FAILED - Critical violations found${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Quality gate PASSED${NC}"
    exit 0
fi 