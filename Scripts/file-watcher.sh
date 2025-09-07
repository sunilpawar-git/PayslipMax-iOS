#!/bin/bash

# PayslipMax Real-Time Architecture Monitoring
# Provides immediate feedback on file size violations during development
# Maintains 94+/100 architecture quality through proactive monitoring

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MAX_LINES=300
WARNING_THRESHOLD=280
CHECK_INTERVAL=5

echo -e "${BLUE}🔍 PayslipMax Real-Time Architecture Monitor${NC}"
echo "============================================="
echo -e "${CYAN}Monitoring PayslipMax directory for file size violations...${NC}"
echo -e "${CYAN}Press Ctrl+C to stop monitoring${NC}"
echo ""

# Create timestamp file for tracking changes
touch /tmp/payslipmax-last-check

# Function to check a specific file
check_file() {
    local file="$1"
    local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
    local filename=$(basename "$file")
    
    # Skip test files and mocks for now (lower priority)
    if [[ "$file" == *"Test"* || "$file" == *"Mock"* ]]; then
        return 0
    fi
    
    if [ "$lines" -gt $MAX_LINES ]; then
        echo -e "${RED}🚨 CRITICAL VIOLATION: $filename now has $lines lines (EXCEEDS 300)${NC}"
        echo -e "${RED}🔧 Run: ./Scripts/component-extraction-helper.sh \"$file\"${NC}"
        
        # macOS notification if available
        if command -v osascript >/dev/null 2>&1; then
            osascript -e "display notification \"$filename exceeds 300 lines ($lines)!\" with title \"PayslipMax Architecture Alert\" sound name \"Basso\""
        fi
        
        # Log violation
        echo "$(date): REALTIME_VIOLATION - $file - $lines lines" >> .architecture-violations.log
        
        return 1
    elif [ "$lines" -gt $WARNING_THRESHOLD ]; then
        echo -e "${YELLOW}⚠️  WARNING: $filename approaching limit ($lines lines)${NC}"
        echo -e "${YELLOW}💡 Start planning component extraction at 280+ lines${NC}"
        
        # Gentle notification for warnings
        if command -v osascript >/dev/null 2>&1; then
            osascript -e "display notification \"$filename approaching 300-line limit ($lines)\" with title \"PayslipMax Architecture Warning\""
        fi
    elif [ "$lines" -gt 250 ]; then
        echo -e "${CYAN}ℹ️  INFO: $filename growing ($lines lines) - monitor closely${NC}"
    fi
    
    return 0
}

# Function to check all Swift files for violations
check_all_files() {
    local violations=0
    local warnings=0
    local total_checked=0
    
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            check_file "$file"
            local result=$?
            total_checked=$((total_checked + 1))
            
            if [ $result -eq 1 ]; then
                violations=$((violations + 1))
            fi
            
            local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
            if [ "$lines" -gt $WARNING_THRESHOLD ] && [ "$lines" -le $MAX_LINES ]; then
                warnings=$((warnings + 1))
            fi
        fi
    done < <(find PayslipMax -name "*.swift" -newer /tmp/payslipmax-last-check -print0 2>/dev/null)
    
    if [ $total_checked -gt 0 ]; then
        echo -e "${BLUE}📊 Scan complete: $total_checked files checked${NC}"
        if [ $violations -gt 0 ]; then
            echo -e "${RED}❌ $violations critical violations found${NC}"
        fi
        if [ $warnings -gt 0 ]; then
            echo -e "${YELLOW}⚠️  $warnings files approaching limit${NC}"
        fi
        if [ $violations -eq 0 ] && [ $warnings -eq 0 ]; then
            echo -e "${GREEN}✅ All modified files compliant${NC}"
        fi
        echo ""
    fi
}

# Function to monitor using fswatch if available
monitor_with_fswatch() {
    if ! command -v fswatch >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  fswatch not found, falling back to polling mode${NC}"
        echo -e "${CYAN}💡 Install fswatch with: brew install fswatch${NC}"
        echo ""
        return 1
    fi
    
    echo -e "${GREEN}✅ Using fswatch for real-time monitoring${NC}"
    echo ""
    
    fswatch -o PayslipMax --include="\.swift$" --exclude=".*Test.*" --exclude=".*Mock.*" | while read f; do
        echo -e "${BLUE}🔍 File change detected, checking Swift files...${NC}"
        check_all_files
        touch /tmp/payslipmax-last-check
    done
}

# Function to monitor using polling
monitor_with_polling() {
    echo -e "${CYAN}📡 Using polling mode (checking every ${CHECK_INTERVAL} seconds)${NC}"
    echo ""
    
    while true; do
        check_all_files
        touch /tmp/payslipmax-last-check
        sleep $CHECK_INTERVAL
    done
}

# Main monitoring function
start_monitoring() {
    # Try fswatch first, fall back to polling
    if ! monitor_with_fswatch; then
        monitor_with_polling
    fi
}

# Handle cleanup on exit
cleanup() {
    echo ""
    echo -e "${BLUE}🛑 Stopping PayslipMax architecture monitor...${NC}"
    rm -f /tmp/payslipmax-last-check
    exit 0
}

# Set up signal handling
trap cleanup SIGINT SIGTERM

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "PayslipMax Real-Time Architecture Monitor"
    echo "========================================"
    echo ""
    echo "This script monitors Swift files in real-time and alerts when:"
    echo "• Files exceed 300 lines (critical violation)"
    echo "• Files exceed 280 lines (warning threshold)"
    echo "• Files exceed 250 lines (informational)"
    echo ""
    echo "Features:"
    echo "• Real-time file system monitoring (with fswatch)"
    echo "• Fallback polling mode (every 5 seconds)"
    echo "• macOS notifications for violations"
    echo "• Violation logging for tracking"
    echo "• Automatic component extraction suggestions"
    echo ""
    echo "Installation:"
    echo "  brew install fswatch  # Optional, for better performance"
    echo ""
    echo "Usage:"
    echo "  $0              # Start monitoring"
    echo "  $0 --help       # Show this help"
    echo ""
    exit 0
fi

# Start monitoring
start_monitoring
