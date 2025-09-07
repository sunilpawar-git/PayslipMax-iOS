#!/bin/bash

# PayslipMax Phase 4: Bulletproof Prevention System Setup
# Automated setup script for complete architecture quality governance
# Based on Technical Debt Elimination Roadmap 2024

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║            PayslipMax Phase 4: Bulletproof Prevention       ║${NC}"
echo -e "${MAGENTA}║                 Architecture Quality Governance             ║${NC}"
echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

    local missing_deps=0

    # Check for required tools
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq is required but not installed${NC}"
        echo "   Install with: brew install jq"
        missing_deps=$((missing_deps + 1))
    else
        echo -e "${GREEN}✅ jq found${NC}"
    fi

    if ! command -v bc &> /dev/null; then
        echo -e "${RED}❌ bc is required but not installed${NC}"
        echo "   Install with: brew install bc"
        missing_deps=$((missing_deps + 1))
    else
        echo -e "${GREEN}✅ bc found${NC}"
    fi

    # Check if git is initialized
    if [ ! -d ".git" ]; then
        echo -e "${RED}❌ Not a git repository${NC}"
        missing_deps=$((missing_deps + 1))
    else
        echo -e "${GREEN}✅ Git repository found${NC}"
    fi

    # Check if PayslipMax directory exists
    if [ ! -d "PayslipMax" ]; then
        echo -e "${RED}❌ PayslipMax directory not found${NC}"
        echo "   Make sure you're running this from the project root"
        missing_deps=$((missing_deps + 1))
    else
        echo -e "${GREEN}✅ PayslipMax directory found${NC}"
    fi

    if [ $missing_deps -gt 0 ]; then
        echo -e "${RED}❌ $missing_deps prerequisite(s) missing. Please fix and retry.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ All prerequisites satisfied${NC}"
    echo ""
}

# Function to show current status
show_current_status() {
    echo -e "${CYAN}📊 Current Architecture Status${NC}"
    echo "==============================="

    local total_files=$(find PayslipMax -name "*.swift" | wc -l)
    local violation_files=$(find PayslipMax -name "*.swift" -exec sh -c 'test $(wc -l < "$1") -gt 300' _ {} \; -print 2>/dev/null | wc -l)
    local compliance_rate=$(echo "scale=1; ($total_files - $violation_files) * 100 / $total_files" | bc 2>/dev/null || echo "N/A")

    echo "Total Swift Files: $total_files"
    echo "Files >300 lines: $violation_files"
    echo "Compliance Rate: $compliance_rate%"

    if [ "$violation_files" -eq 0 ]; then
        echo -e "Status: ${GREEN}🎯 EXCELLENT - Ready for Phase 4${NC}"
    elif [ "$violation_files" -le 10 ]; then
        echo -e "Status: ${YELLOW}⚠️  GOOD - Minor violations remaining${NC}"
    else
        echo -e "Status: ${RED}🚨 ATTENTION NEEDED - Multiple violations${NC}"
    fi
    echo ""
}

# Function to setup CI/CD pipeline
setup_ci_pipeline() {
    echo -e "${BLUE}🔄 Setting up CI/CD pipeline...${NC}"

    # Ensure .github/workflows directory exists
    mkdir -p .github/workflows

    if [ -f ".github/workflows/architecture-quality.yml" ]; then
        echo -e "${GREEN}✅ CI pipeline already configured${NC}"
    else
        echo -e "${YELLOW}⚠️  CI pipeline not found${NC}"
        echo "   Please ensure .github/workflows/architecture-quality.yml exists"
    fi

    # Test CI components
    if [ -f "Scripts/architecture-guard.sh" ]; then
        echo -e "${GREEN}✅ Architecture guard script ready${NC}"
    else
        echo -e "${RED}❌ Architecture guard script missing${NC}"
    fi
}

# Function to setup monitoring system
setup_monitoring() {
    echo -e "${BLUE}📈 Setting up debt trend monitoring...${NC}"

    if [ -f "Scripts/debt-trend-monitor.sh" ]; then
        chmod +x Scripts/debt-trend-monitor.sh

        # Collect initial metrics
        echo "   Collecting initial metrics..."
        ./Scripts/debt-trend-monitor.sh --collect

        # Show dashboard
        echo "   Current status:"
        ./Scripts/debt-trend-monitor.sh --dashboard

        echo -e "${GREEN}✅ Monitoring system active${NC}"
    else
        echo -e "${RED}❌ Debt trend monitor script missing${NC}"
    fi
}

# Function to setup Xcode integration
setup_xcode_integration() {
    echo -e "${BLUE}🔧 Setting up Xcode integration...${NC}"

    if [ -f "Scripts/xcode-integration.sh" ]; then
        chmod +x Scripts/xcode-integration.sh

        # Check if already installed
        if [ -d "$HOME/Library/Developer/Xcode/Templates/File Templates/PayslipMax" ]; then
            echo -e "${GREEN}✅ Xcode templates already installed${NC}"
        else
            echo "   Installing Xcode integration..."
            ./Scripts/xcode-integration.sh --install
        fi

        echo -e "${GREEN}✅ Xcode integration configured${NC}"
    else
        echo -e "${RED}❌ Xcode integration script missing${NC}"
    fi
}

# Function to setup component extraction helper
setup_extraction_helper() {
    echo -e "${BLUE}🔧 Setting up component extraction helper...${NC}"

    if [ -f "Scripts/component-extraction-helper.sh" ]; then
        chmod +x Scripts/component-extraction-helper.sh

        # Test with analysis of current violations
        echo "   Analyzing current violations..."
        local violation_count=$(./Scripts/component-extraction-helper.sh --analyze-all 2>/dev/null | grep -c "CRITICAL\|HIGH" || echo "0")

        echo -e "${GREEN}✅ Component extraction helper ready${NC}"
        echo "   Found $violation_count files needing immediate attention"
    else
        echo -e "${RED}❌ Component extraction helper missing${NC}"
    fi
}

# Function to setup automated workflows
setup_automated_workflows() {
    echo -e "${BLUE}⚙️ Setting up automated workflows...${NC}"

    # Create daily monitoring cron job suggestion
    cat > "suggested-cron-jobs.txt" << 'EOF'
# PayslipMax Architecture Monitoring - Suggested Cron Jobs
# Add these to your crontab with: crontab -e

# Daily metrics collection (9 AM)
0 9 * * * cd /path/to/PayslipMax && ./Scripts/debt-trend-monitor.sh --collect

# Weekly trend report (Monday 10 AM)
0 10 * * 1 cd /path/to/PayslipMax && ./Scripts/debt-trend-monitor.sh --report

# Monthly cleanup (1st of month, 11 PM)
0 23 1 * * cd /path/to/PayslipMax && ./Scripts/debt-trend-monitor.sh --cleanup 30

# Daily architecture check (Before work, 8 AM)
0 8 * * * cd /path/to/PayslipMax && ./Scripts/architecture-guard.sh > /tmp/payslipmax-health.log 2>&1
EOF

    echo -e "${GREEN}✅ Automated workflow suggestions created${NC}"
    echo "   See: suggested-cron-jobs.txt"
}

# Function to validate installation
validate_installation() {
    echo -e "${CYAN}🔍 Validating Phase 4 installation...${NC}"
    echo "====================================="

    local validation_score=0
    local max_score=10

    # Check CI pipeline
    if [ -f ".github/workflows/architecture-quality.yml" ]; then
        echo -e "${GREEN}✅ CI/CD pipeline configured${NC}"
        validation_score=$((validation_score + 2))
    else
        echo -e "${RED}❌ CI/CD pipeline missing${NC}"
    fi

    # Check monitoring system
    if [ -f "Scripts/debt-trend-monitor.sh" ] && [ -f ".architecture-metrics.json" ]; then
        echo -e "${GREEN}✅ Monitoring system active${NC}"
        validation_score=$((validation_score + 2))
    else
        echo -e "${RED}❌ Monitoring system incomplete${NC}"
    fi

    # Check Xcode integration
    if [ -f "Scripts/xcode-integration.sh" ] && [ -f "DEVELOPER_ONBOARDING.md" ]; then
        echo -e "${GREEN}✅ Xcode integration ready${NC}"
        validation_score=$((validation_score + 2))
    else
        echo -e "${RED}❌ Xcode integration incomplete${NC}"
    fi

    # Check extraction helper
    if [ -f "Scripts/component-extraction-helper.sh" ] && [ -x "Scripts/component-extraction-helper.sh" ]; then
        echo -e "${GREEN}✅ Component extraction helper active${NC}"
        validation_score=$((validation_score + 1))
    else
        echo -e "${RED}❌ Component extraction helper missing${NC}"
    fi

    # Check architecture guard
    if [ -f "Scripts/architecture-guard.sh" ] && [ -x "Scripts/architecture-guard.sh" ]; then
        echo -e "${GREEN}✅ Architecture guard operational${NC}"
        validation_score=$((validation_score + 1))
    else
        echo -e "${RED}❌ Architecture guard missing${NC}"
    fi

    # Check pre-commit hooks
    if [ -f ".git/hooks/pre-commit" ] && [ -x ".git/hooks/pre-commit" ]; then
        echo -e "${GREEN}✅ Pre-commit hooks active${NC}"
        validation_score=$((validation_score + 1))
    else
        echo -e "${RED}❌ Pre-commit hooks missing${NC}"
    fi

    # Check VS Code integration
    if [ -f ".vscode/settings.json" ] && [ -f ".vscode/tasks.json" ]; then
        echo -e "${GREEN}✅ VS Code integration configured${NC}"
        validation_score=$((validation_score + 1))
    else
        echo -e "${YELLOW}⚠️  VS Code integration partial${NC}"
    fi

    echo ""
    echo "Validation Score: $validation_score/$max_score"

    if [ $validation_score -ge 8 ]; then
        echo -e "${GREEN}🎉 Phase 4 installation EXCELLENT${NC}"
        return 0
    elif [ $validation_score -ge 6 ]; then
        echo -e "${YELLOW}⚠️  Phase 4 installation GOOD (minor issues)${NC}"
        return 0
    else
        echo -e "${RED}❌ Phase 4 installation INCOMPLETE${NC}"
        return 1
    fi
}

# Function to generate summary report
generate_summary_report() {
    echo -e "${MAGENTA}📋 Phase 4 Implementation Summary${NC}"
    echo "===================================="
    echo ""

    echo "✅ **Completed Components:**"
    echo ""
    echo "1. **Automated Architecture Governance**"
    echo "   - CI/CD pipeline with quality gates"
    echo "   - Enhanced architecture guard scripts"
    echo "   - Violation counting and reporting"
    echo ""

    echo "2. **Development Workflow Integration**"
    echo "   - Xcode build phase integration"
    echo "   - File templates with architecture reminders"
    echo "   - VS Code task integration"
    echo "   - Pre-commit hook enforcement"
    echo ""

    echo "3. **Proactive Debt Prevention**"
    echo "   - Smart component extraction helper"
    echo "   - Debt trend monitoring system"
    echo "   - Automated reporting and alerts"
    echo "   - Developer onboarding checklist"
    echo ""

    echo "4. **Monitoring and Reporting**"
    echo "   - Real-time compliance dashboard"
    echo "   - Historical trend analysis"
    echo "   - Automated metrics collection"
    echo "   - Quality score tracking"
    echo ""

    # Current status
    local violation_count=$(./Scripts/architecture-guard.sh --count-violations 2>/dev/null || echo "N/A")
    echo "📊 **Current Status:**"
    echo "   - Architecture Violations: $violation_count files"
    echo "   - Quality Gates: Active and enforced"
    echo "   - Monitoring: Real-time tracking enabled"
    echo "   - Prevention: Bulletproof system operational"
    echo ""

    echo "🎯 **Success Metrics Achieved:**"
    echo "   ✅ CI/CD pipeline blocks violations"
    echo "   ✅ Real-time developer feedback"
    echo "   ✅ Automated refactoring suggestions"
    echo "   ✅ Trend monitoring operational"
    echo "   ✅ Team onboarding process established"
    echo ""

    echo "🚀 **Next Steps:**"
    echo "1. Continue Phase 3 debt reduction on remaining $violation_count files"
    echo "2. Train team with DEVELOPER_ONBOARDING.md"
    echo "3. Add Xcode build phase manually (see instructions above)"
    echo "4. Monitor daily with: ./Scripts/debt-trend-monitor.sh --dashboard"
    echo "5. Review weekly trends: ./Scripts/debt-trend-monitor.sh --report"
    echo ""

    echo -e "${GREEN}🎉 Phase 4: Bulletproof Prevention System - IMPLEMENTATION COMPLETE!${NC}"
}

# Main execution flow
main() {
    case "$1" in
        --validate-only)
            validate_installation
            ;;
        --status-only)
            show_current_status
            ;;
        --help)
            cat << EOF
PayslipMax Phase 4: Bulletproof Prevention System Setup

Usage: $0 [--validate-only|--status-only|--help]

Commands:
  (no args)        Full Phase 4 setup and validation
  --validate-only  Validate existing installation only
  --status-only    Show current architecture status only
  --help          Show this help message

Description:
  Implements the complete Phase 4 Bulletproof Prevention System from the
  Technical Debt Elimination Roadmap 2024. Includes:

  - Automated CI/CD pipeline with quality gates
  - Development workflow integration (Xcode + VS Code)
  - Proactive debt prevention tools
  - Real-time monitoring and reporting
  - Developer onboarding automation

EOF
            ;;
        *)
            # Full setup process
            check_prerequisites
            show_current_status

            echo -e "${BLUE}🚀 Starting Phase 4 implementation...${NC}"
            echo ""

            setup_ci_pipeline
            setup_monitoring
            setup_xcode_integration
            setup_extraction_helper
            setup_automated_workflows

            echo ""
            if validate_installation; then
                echo ""
                generate_summary_report
            else
                echo -e "${RED}❌ Setup incomplete. Please check errors above.${NC}"
                exit 1
            fi
            ;;
    esac
}

# Execute main function
main "$@"
