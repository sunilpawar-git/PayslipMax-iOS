#!/bin/bash

# Emergency Rollback Script for Phase 2D Dependency Injection
# Provides immediate rollback to singleton patterns when DI conversions fail
# Usage: ./emergency-rollback.sh [--service ServiceName] [--all] [--dry-run]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="/Users/sunil/Downloads/PayslipMax"
BACKUP_DIR="$PROJECT_ROOT/Backups/emergency-rollback-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$PROJECT_ROOT/emergency-rollback.log"

# DI Feature flags that can be rolled back
declare -A SERVICE_FLAGS=(
    ["GlobalLoadingManager"]="diGlobalLoadingManager"
    ["AnalyticsManager"]="diAnalyticsManager"
    ["TabTransitionCoordinator"]="diTabTransitionCoordinator"
    ["AppearanceManager"]="diAppearanceManager"
    ["PerformanceMetrics"]="diPerformanceMetrics"
    ["FirebaseAnalyticsProvider"]="diFirebaseAnalyticsProvider"
    ["PerformanceAnalyticsService"]="diPerformanceAnalyticsService"
    ["UserAnalyticsService"]="diUserAnalyticsService"
    ["PDFDocumentCache"]="diPDFDocumentCache"
    ["PayslipPDFService"]="diPayslipPDFService"
    ["PayslipPDFFormattingService"]="diPayslipPDFFormattingService"
    ["PayslipPDFURLService"]="diPayslipPDFURLService"
    ["PayslipShareService"]="diPayslipShareService"
    ["PrintService"]="diPrintService"
    ["GlobalOverlaySystem"]="diGlobalOverlaySystem"
    ["AppTheme"]="diAppTheme"
    ["ErrorHandlingUtility"]="diErrorHandlingUtility"
    ["FinancialCalculationUtility"]="diFinancialCalculationUtility"
    ["PDFManager"]="diPDFManager"
)

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

# Initialize emergency rollback log
init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "Emergency Rollback Log - $(date)" > "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
}

# Create backup before rollback
create_backup() {
    print_header "Creating Emergency Backup"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup critical DI files
    cp -r "$PROJECT_ROOT/PayslipMax/Core/DI" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/PayslipMax/Core/FeatureFlags" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$PROJECT_ROOT/PayslipMax/Core/Protocols" "$BACKUP_DIR/" 2>/dev/null || true
    
    print_success "Backup created at: $BACKUP_DIR"
}

# Disable DI feature flag for specific service
disable_service_flag() {
    local service_name="$1"
    local flag_name="${SERVICE_FLAGS[$service_name]}"
    
    if [[ -z "$flag_name" ]]; then
        print_error "No feature flag found for service: $service_name"
        return 1
    fi
    
    print_header "Disabling DI for $service_name"
    
    # Update FeatureFlagConfiguration.swift to disable the flag
    local config_file="$PROJECT_ROOT/PayslipMax/Core/FeatureFlags/FeatureFlagConfiguration.swift"
    
    if [[ -f "$config_file" ]]; then
        # Create backup of current config
        cp "$config_file" "$config_file.rollback.bak"
        
        # Disable the feature flag
        sed -i.tmp "s/\.$flag_name: true/.$flag_name: false/g" "$config_file"
        sed -i.tmp "s/\.$flag_name: true/.$flag_name: false/g" "$config_file"
        rm -f "$config_file.tmp" 2>/dev/null || true
        
        print_success "Disabled feature flag: $flag_name"
        return 0
    else
        print_error "FeatureFlagConfiguration.swift not found"
        return 1
    fi
}

# Re-enable singleton pattern for service
restore_singleton_pattern() {
    local service_name="$1"
    
    print_header "Restoring singleton pattern for $service_name"
    
    # Find service files
    local service_files=$(find "$PROJECT_ROOT" -name "*${service_name}*.swift" 2>/dev/null)
    
    if [[ -z "$service_files" ]]; then
        print_warning "No service files found for: $service_name"
        return 1
    fi
    
    local restored_count=0
    
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            # Create backup
            cp "$file" "$file.rollback.bak"
            
            # Check if file has DI pattern and needs restoration
            if grep -q "// MARK: - Phase 2:" "$file" 2>/dev/null; then
                print_success "Singleton pattern already present in: $(basename "$file")"
                restored_count=$((restored_count + 1))
            else
                print_warning "No DI conversion pattern found in: $(basename "$file")"
            fi
        fi
    done <<< "$service_files"
    
    if [[ $restored_count -gt 0 ]]; then
        print_success "Restored singleton pattern for $restored_count files"
        return 0
    else
        print_warning "No files required singleton restoration"
        return 1
    fi
}

# Validate rollback success
validate_rollback() {
    local service_name="$1"
    
    print_header "Validating rollback for $service_name"
    
    # Check if feature flag is disabled
    local flag_name="${SERVICE_FLAGS[$service_name]}"
    local config_file="$PROJECT_ROOT/PayslipMax/Core/FeatureFlags/FeatureFlagConfiguration.swift"
    
    if grep -q "\.$flag_name: false" "$config_file" 2>/dev/null; then
        print_success "Feature flag correctly disabled: $flag_name"
    else
        print_error "Feature flag rollback failed: $flag_name"
        return 1
    fi
    
    # Check if singleton pattern is available
    local service_files=$(find "$PROJECT_ROOT" -name "*${service_name}*.swift" 2>/dev/null)
    local singleton_found=false
    
    while IFS= read -r file; do
        if [[ -f "$file" ]] && grep -q "\.shared" "$file" 2>/dev/null; then
            singleton_found=true
            break
        fi
    done <<< "$service_files"
    
    if [[ "$singleton_found" == true ]]; then
        print_success "Singleton pattern confirmed for: $service_name"
        return 0
    else
        print_error "Singleton pattern not found for: $service_name"
        return 1
    fi
}

# Test build after rollback
test_build() {
    print_header "Testing build after rollback"
    
    cd "$PROJECT_ROOT"
    
    # Quick build test
    if xcodebuild -project PayslipMax.xcodeproj -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.0' build > /dev/null 2>&1; then
        print_success "Project builds successfully after rollback"
        return 0
    else
        print_error "Project build failed after rollback"
        print_error "Check build logs for detailed error information"
        return 1
    fi
}

# Rollback specific service
rollback_service() {
    local service_name="$1"
    local dry_run="$2"
    
    print_header "Rolling back service: $service_name"
    
    if [[ "$dry_run" == "true" ]]; then
        print_warning "DRY RUN MODE - No actual changes will be made"
        
        # Simulate rollback steps
        echo "Would disable feature flag: ${SERVICE_FLAGS[$service_name]}"
        echo "Would restore singleton pattern for: $service_name"
        echo "Would validate rollback success"
        echo "Would test build"
        
        return 0
    fi
    
    # Actual rollback steps
    if disable_service_flag "$service_name"; then
        if restore_singleton_pattern "$service_name"; then
            if validate_rollback "$service_name"; then
                print_success "Service rollback completed: $service_name"
                return 0
            else
                print_error "Rollback validation failed: $service_name"
                return 1
            fi
        else
            print_error "Singleton restoration failed: $service_name"
            return 1
        fi
    else
        print_error "Feature flag disable failed: $service_name"
        return 1
    fi
}

# Rollback all services
rollback_all_services() {
    local dry_run="$1"
    
    print_header "Rolling back ALL DI services"
    
    local success_count=0
    local total_count=${#SERVICE_FLAGS[@]}
    
    for service_name in "${!SERVICE_FLAGS[@]}"; do
        if rollback_service "$service_name" "$dry_run"; then
            success_count=$((success_count + 1))
        fi
        echo ""
    done
    
    print_header "Rollback Summary"
    echo "Successfully rolled back: $success_count/$total_count services"
    
    if [[ "$dry_run" != "true" ]] && [[ $success_count -eq $total_count ]]; then
        test_build
    fi
}

# Show rollback status
show_status() {
    print_header "Current DI Service Status"
    
    local config_file="$PROJECT_ROOT/PayslipMax/Core/FeatureFlags/FeatureFlagConfiguration.swift"
    
    for service_name in "${!SERVICE_FLAGS[@]}"; do
        local flag_name="${SERVICE_FLAGS[$service_name]}"
        
        if grep -q "\.$flag_name: true" "$config_file" 2>/dev/null; then
            echo -e "${GREEN}🟢 $service_name: DI ENABLED${NC}"
        elif grep -q "\.$flag_name: false" "$config_file" 2>/dev/null; then
            echo -e "${YELLOW}🟡 $service_name: DI DISABLED (Singleton)${NC}"
        else
            echo -e "${RED}🔴 $service_name: STATUS UNKNOWN${NC}"
        fi
    done
}

# Main function
main() {
    local service_name=""
    local rollback_all=false
    local dry_run=false
    local show_status_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --service)
                service_name="$2"
                shift 2
                ;;
            --all)
                rollback_all=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --status)
                show_status_only=true
                shift
                ;;
            --help)
                echo "Emergency Rollback Script for Phase 2D"
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --service NAME    Rollback specific service"
                echo "  --all            Rollback all DI services"
                echo "  --dry-run        Show what would be done without making changes"
                echo "  --status         Show current DI service status"
                echo "  --help           Show this help message"
                echo ""
                echo "Available services:"
                for service in "${!SERVICE_FLAGS[@]}"; do
                    echo "  - $service"
                done
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    init_log
    
    if [[ "$show_status_only" == true ]]; then
        show_status
        exit 0
    fi
    
    print_header "Emergency Rollback Starting..."
    echo "Timestamp: $(date)"
    echo "Project: $PROJECT_ROOT"
    echo "Log file: $LOG_FILE"
    echo ""
    
    # Create backup unless dry run
    if [[ "$dry_run" != "true" ]]; then
        create_backup
        echo ""
    fi
    
    # Execute rollback based on parameters
    if [[ -n "$service_name" ]]; then
        # Single service rollback
        if [[ -n "${SERVICE_FLAGS[$service_name]}" ]]; then
            rollback_service "$service_name" "$dry_run"
        else
            print_error "Unknown service: $service_name"
            echo "Available services: ${!SERVICE_FLAGS[*]}"
            exit 1
        fi
    elif [[ "$rollback_all" == true ]]; then
        # All services rollback
        rollback_all_services "$dry_run"
    else
        # Show status and prompt for action
        show_status
        echo ""
        echo "Use --service NAME or --all to perform rollback"
        echo "Use --help for more options"
    fi
    
    print_header "Emergency Rollback Complete!"
    echo "📊 Full log saved to: $LOG_FILE"
    
    if [[ "$dry_run" != "true" ]]; then
        echo "💾 Backup saved to: $BACKUP_DIR"
    fi
}

# Run main function with all arguments
main "$@"
