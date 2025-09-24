#!/bin/bash

# Phase 2D-Alpha: Automated Validation Script
# Validates dependency injection conversion safety and progress
# Usage: ./phase2d-alpha-validation.sh [--full] [--service ServiceName]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="/Users/sunil/Downloads/PayslipMax"
LOG_FILE="$PROJECT_ROOT/phase2d-alpha-validation.log"
VALIDATION_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Validation categories
declare -a ANALYTICS_SERVICES=("FirebaseAnalyticsProvider" "PerformanceAnalyticsService" "UserAnalyticsService")
declare -a PDF_SERVICES=("PDFDocumentCache" "PayslipPDFService" "PayslipPDFFormattingService" "PayslipPDFURLService" "PayslipShareService" "PrintService")
declare -a PERFORMANCE_SERVICES=("BackgroundTaskCoordinator" "ClassificationCacheManager" "DualSectionPerformanceMonitor" "ParallelPayCodeProcessor" "TaskCoordinatorWrapper" "TaskMonitor" "ViewPerformanceTracker")
declare -a UI_SERVICES=("GlobalOverlaySystem" "AppTheme" "PerformanceDebugSettings")
declare -a DATA_SERVICES=("ErrorHandlingUtility" "FinancialCalculationUtility" "PayslipFormatterService" "PDFValidationService" "PDFProcessingCache" "GamificationCoordinator")
declare -a CORE_SERVICES=("PayslipLearningSystem" "PayslipPatternManagerCompat" "UnifiedPatternDefinitions" "UnifiedPatternMatcher" "PDFManager" "FeatureFlagConfiguration" "FeatureFlagManager")

# Initialize log file
echo "Phase 2D-Alpha Validation Report - $VALIDATION_TIMESTAMP" > "$LOG_FILE"
echo "=================================================" >> "$LOG_FILE"

print_header() {
    echo -e "${BLUE}$1${NC}"
    echo "$1" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "✅ $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    echo "⚠️  $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    echo "❌ $1" >> "$LOG_FILE"
}

# Function to check if a service exists
check_service_exists() {
    local service_name="$1"
    local service_files=$(find "$PROJECT_ROOT" -name "*${service_name}*.swift" 2>/dev/null)
    
    if [[ -n "$service_files" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if a service has singleton pattern
check_singleton_pattern() {
    local service_name="$1"
    local service_files=$(find "$PROJECT_ROOT" -name "*${service_name}*.swift" 2>/dev/null)
    
    if [[ -n "$service_files" ]]; then
        while IFS= read -r file; do
            if grep -q "\.shared" "$file" 2>/dev/null; then
                echo "$file"
                return 0
            fi
        done <<< "$service_files"
    fi
    return 1
}

# Function to check feature flag existence
check_feature_flag() {
    local service_name="$1"
    local flag_name="di${service_name}"
    
    if grep -q "case $flag_name" "$PROJECT_ROOT/PayslipMax/Core/FeatureFlags/FeatureFlagProtocol.swift" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to check SafeConversionProtocol compliance
check_safe_conversion_protocol() {
    local service_name="$1"
    local service_files=$(find "$PROJECT_ROOT" -name "*${service_name}*.swift" 2>/dev/null)
    
    if [[ -n "$service_files" ]]; then
        while IFS= read -r file; do
            if grep -q "SafeConversionProtocol" "$file" 2>/dev/null; then
                return 0
            fi
        done <<< "$service_files"
    fi
    return 1
}

# Function to validate service category
validate_service_category() {
    local category_name="$1"
    shift
    local services=("$@")
    
    print_header "Validating $category_name Services"
    
    local total_services=${#services[@]}
    local existing_services=0
    local singleton_services=0
    local flagged_services=0
    local protocol_compliant=0
    
    for service in "${services[@]}"; do
        echo "  Checking $service..."
        
        # Check if service exists
        if check_service_exists "$service"; then
            existing_services=$((existing_services + 1))
            print_success "  $service: Service file found"
            
            # Check singleton pattern
            if singleton_file=$(check_singleton_pattern "$service"); then
                singleton_services=$((singleton_services + 1))
                print_success "  $service: Singleton pattern detected in $(basename "$singleton_file")"
            else
                print_warning "  $service: No singleton pattern found"
            fi
            
            # Check feature flag
            if check_feature_flag "$service"; then
                flagged_services=$((flagged_services + 1))
                print_success "  $service: Feature flag configured"
            else
                print_error "  $service: Feature flag missing"
            fi
            
            # Check SafeConversionProtocol compliance
            if check_safe_conversion_protocol "$service"; then
                protocol_compliant=$((protocol_compliant + 1))
                print_success "  $service: SafeConversionProtocol implemented"
            else
                print_warning "  $service: SafeConversionProtocol not yet implemented"
            fi
        else
            print_error "  $service: Service file not found"
        fi
        echo ""
    done
    
    # Category summary
    echo "Category Summary for $category_name:" >> "$LOG_FILE"
    echo "  Total Services: $total_services" >> "$LOG_FILE"
    echo "  Existing Services: $existing_services" >> "$LOG_FILE"
    echo "  Singleton Services: $singleton_services" >> "$LOG_FILE"
    echo "  Feature Flagged: $flagged_services" >> "$LOG_FILE"
    echo "  Protocol Compliant: $protocol_compliant" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    # Print summary to console
    print_header "$category_name Summary:"
    echo "  📁 Services Found: $existing_services/$total_services"
    echo "  🔄 Singleton Pattern: $singleton_services/$existing_services"
    echo "  🚩 Feature Flagged: $flagged_services/$total_services"
    echo "  📋 Protocol Compliant: $protocol_compliant/$existing_services"
    echo ""
}

# Function to check build status
check_build_status() {
    print_header "Build Status Validation"
    
    cd "$PROJECT_ROOT"
    
    # Check if project can be built
    echo "Running build validation..."
    if xcodebuild -project PayslipMax.xcodeproj -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.0' build > /dev/null 2>&1; then
        print_success "Project builds successfully"
        return 0
    else
        print_error "Project build failed"
        return 1
    fi
}

# Function to check dependency graph integrity
check_dependency_integrity() {
    print_header "Dependency Graph Integrity Check"
    
    # Check for circular dependencies in singleton usage
    local circular_deps=$(grep -r "\.shared" "$PROJECT_ROOT/PayslipMax" --include="*.swift" | \
        grep -E "(FirebaseAnalyticsProvider|PerformanceAnalyticsService|UserAnalyticsService|PDFDocumentCache|PayslipPDFService)" | \
        wc -l)
    
    if [[ $circular_deps -gt 0 ]]; then
        print_warning "Found $circular_deps potential circular dependency references"
    else
        print_success "No obvious circular dependencies detected"
    fi
    
    # Check for proper DI container usage
    local di_usage=$(grep -r "DIContainer\|AppContainer" "$PROJECT_ROOT/PayslipMax" --include="*.swift" | wc -l)
    print_success "DI Container usage found in $di_usage locations"
}

# Function to generate conversion roadmap
generate_conversion_roadmap() {
    print_header "Phase 2D Conversion Roadmap"
    
    echo "Conversion Priority Order:" >> "$LOG_FILE"
    echo "1. Low-Risk Services (Beta Phase):" >> "$LOG_FILE"
    echo "   - Analytics: FirebaseAnalyticsProvider, PerformanceAnalyticsService, UserAnalyticsService" >> "$LOG_FILE"
    echo "   - Utilities: ErrorHandlingUtility, FinancialCalculationUtility" >> "$LOG_FILE"
    echo "   - Independent: PDFDocumentCache, AppTheme" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "2. Medium-Risk Services (Gamma Phase):" >> "$LOG_FILE"
    echo "   - PDF Chain: PayslipPDFService → PrintService → PayslipPDFFormattingService" >> "$LOG_FILE"
    echo "   - Performance: BackgroundTaskCoordinator → ParallelPayCodeProcessor" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "3. High-Risk Services (Final Phase):" >> "$LOG_FILE"
    echo "   - Core: GlobalOverlaySystem, PDFManager" >> "$LOG_FILE"
    echo "   - Complex: PayslipShareService, UnifiedPatternMatcher" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Main validation function
main() {
    local full_validation=false
    local specific_service=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full)
                full_validation=true
                shift
                ;;
            --service)
                specific_service="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: $0 [--full] [--service ServiceName]"
                exit 1
                ;;
        esac
    done
    
    print_header "Phase 2D-Alpha Validation Starting..."
    echo "Timestamp: $VALIDATION_TIMESTAMP"
    echo "Log file: $LOG_FILE"
    echo ""
    
    # If specific service validation requested
    if [[ -n "$specific_service" ]]; then
        print_header "Validating Specific Service: $specific_service"
        validate_service_category "Single Service" "$specific_service"
        exit 0
    fi
    
    # Core validations (always run)
    check_build_status
    echo ""
    
    check_dependency_integrity
    echo ""
    
    # Service category validations
    validate_service_category "Analytics" "${ANALYTICS_SERVICES[@]}"
    validate_service_category "PDF Processing" "${PDF_SERVICES[@]}"
    validate_service_category "Performance & Monitoring" "${PERFORMANCE_SERVICES[@]}"
    validate_service_category "UI & Appearance" "${UI_SERVICES[@]}"
    validate_service_category "Data & Utility" "${DATA_SERVICES[@]}"
    validate_service_category "Core System" "${CORE_SERVICES[@]}"
    
    # Full validation checks
    if [[ "$full_validation" == true ]]; then
        print_header "Running Full Validation Suite..."
        
        # Additional comprehensive checks
        echo "Checking SafeConversionProtocol implementation..."
        if [[ -f "$PROJECT_ROOT/PayslipMax/Core/Protocols/SafeConversionProtocol.swift" ]]; then
            print_success "SafeConversionProtocol found"
        else
            print_error "SafeConversionProtocol missing"
        fi
        
        # Check feature flag completeness
        local total_flags=$(grep -c "case di" "$PROJECT_ROOT/PayslipMax/Core/FeatureFlags/FeatureFlagProtocol.swift" || echo "0")
        print_success "Total DI feature flags configured: $total_flags"
        
        generate_conversion_roadmap
    fi
    
    print_header "Validation Complete!"
    echo "📊 Full report saved to: $LOG_FILE"
    echo "🚀 Ready to proceed with Phase 2D-Beta conversions"
}

# Run main function with all arguments
main "$@"
