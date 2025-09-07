#!/bin/bash

# PayslipMax Component Extraction Helper
# Assists in maintaining 300-line rule through guided component extraction
# Preserves architectural excellence achieved through debt elimination

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
MAX_LINES=300
WARNING_THRESHOLD=250

show_help() {
    echo -e "${BLUE}PayslipMax Component Extraction Helper${NC}"
    echo "======================================"
    echo ""
    echo "Usage: $0 [OPTIONS] <file>"
    echo ""
    echo "Options:"
    echo "  -a, --analyze      Analyze file for extraction opportunities"
    echo "  -s, --suggest      Suggest extraction strategies"
    echo "  -p, --preview      Preview extraction plan"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --analyze PayslipMax/Features/Home/Views/HomeView.swift"
    echo "  $0 --suggest PayslipMax/Services/LargeService.swift"
    echo ""
}

analyze_file() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}❌ File not found: $file_path${NC}"
        return 1
    fi
    
    local lines=$(wc -l < "$file_path")
    local filename=$(basename "$file_path")
    
    echo -e "${BLUE}📊 Analyzing: $filename${NC}"
    echo "Current lines: $lines"
    
    if [ "$lines" -le $WARNING_THRESHOLD ]; then
        echo -e "${GREEN}✅ File is healthy (under $WARNING_THRESHOLD lines)${NC}"
        return 0
    elif [ "$lines" -le $MAX_LINES ]; then
        echo -e "${YELLOW}⚠️  File approaching limit ($lines/$MAX_LINES lines)${NC}"
        echo "Consider planning component extraction soon"
    else
        echo -e "${RED}🚨 VIOLATION: File exceeds limit ($lines/$MAX_LINES lines)${NC}"
        echo "IMMEDIATE extraction required!"
    fi
    
    # Analyze file structure
    echo ""
    echo -e "${CYAN}📋 File Structure Analysis:${NC}"
    
    # Count different sections
    local imports=$(grep -c "^import " "$file_path" 2>/dev/null || echo 0)
    local classes=$(grep -c "^class\|^struct\|^enum" "$file_path" 2>/dev/null || echo 0)
    local functions=$(grep -c "func " "$file_path" 2>/dev/null || echo 0)
    local properties=$(grep -c "@Published\|@State\|let \|var " "$file_path" 2>/dev/null || echo 0)
    local extensions=$(grep -c "^extension " "$file_path" 2>/dev/null || echo 0)
    
    echo "  Imports: $imports"
    echo "  Types (class/struct/enum): $classes"
    echo "  Functions: $functions"
    echo "  Properties: $properties"
    echo "  Extensions: $extensions"
    
    # Check for specific patterns
    local swiftui_views=$(grep -c "View\|Button\|Text\|VStack\|HStack" "$file_path" 2>/dev/null || echo 0)
    local viewmodel_patterns=$(grep -c "ObservableObject\|@Published" "$file_path" 2>/dev/null || echo 0)
    local service_patterns=$(grep -c "protocol\|async func\|throws" "$file_path" 2>/dev/null || echo 0)
    
    echo ""
    echo -e "${CYAN}🏗️ Architecture Pattern Detection:${NC}"
    [ "$swiftui_views" -gt 10 ] && echo "  High UI complexity detected ($swiftui_views UI elements)"
    [ "$viewmodel_patterns" -gt 0 ] && echo "  ViewModel patterns detected ($viewmodel_patterns)"
    [ "$service_patterns" -gt 5 ] && echo "  Service patterns detected ($service_patterns)"
}

suggest_extraction() {
    local file_path="$1"
    local filename=$(basename "$file_path")
    local directory=$(dirname "$file_path")
    local base_name="${filename%.*}"
    
    echo -e "${BLUE}💡 Extraction Suggestions for: $filename${NC}"
    echo "============================================"
    
    # Analyze file type and suggest appropriate patterns
    if grep -q "View" "$file_path" && grep -q "SwiftUI" "$file_path"; then
        echo -e "${CYAN}📱 SwiftUI View Component Extraction:${NC}"
        echo "1. Extract reusable UI components:"
        echo "   - ${base_name}HeaderSection.swift"
        echo "   - ${base_name}ContentView.swift"
        echo "   - ${base_name}FooterSection.swift"
        echo ""
        echo "2. Extract complex subviews:"
        echo "   - Extract VStack/HStack with >20 lines"
        echo "   - Move sheet/modal content to separate files"
        echo "   - Create component library files"
        
    elif grep -q "ObservableObject\|ViewModel" "$file_path"; then
        echo -e "${CYAN}🧠 ViewModel Component Extraction:${NC}"
        echo "1. Extract coordinators:"
        echo "   - ${base_name}Coordinator.swift"
        echo "   - ${base_name}StateManager.swift"
        echo ""
        echo "2. Extract handlers:"
        echo "   - ${base_name}DataHandler.swift"
        echo "   - ${base_name}ValidationHandler.swift"
        echo "   - ${base_name}ErrorHandler.swift"
        echo ""
        echo "3. Extract business logic:"
        echo "   - Move service calls to dedicated coordinators"
        echo "   - Create focused sub-ViewModels"
        
    elif grep -q "protocol\|class.*Service\|func.*async" "$file_path"; then
        echo -e "${CYAN}⚙️ Service Component Extraction:${NC}"
        echo "1. Split by responsibility:"
        echo "   - ${base_name}Protocol.swift"
        echo "   - ${base_name}Implementation.swift"
        echo "   - ${base_name}Extensions.swift"
        echo ""
        echo "2. Extract utilities:"
        echo "   - ${base_name}Utilities.swift"
        echo "   - ${base_name}Helpers.swift"
        echo "   - ${base_name}Constants.swift"
        
    else
        echo -e "${CYAN}📄 Generic Component Extraction:${NC}"
        echo "1. Extract by functionality:"
        echo "   - Move related functions to separate files"
        echo "   - Create protocol extensions"
        echo "   - Split complex types"
    fi
    
    echo ""
    echo -e "${YELLOW}📋 Extraction Checklist:${NC}"
    echo "□ Maintain public interface compatibility"
    echo "□ Use protocol abstractions where appropriate"
    echo "□ Ensure each extracted component has single responsibility"
    echo "□ Keep extracted files under 300 lines"
    echo "□ Update import statements"
    echo "□ Run build verification after extraction"
    echo "□ Update DI container registrations if needed"
}

preview_extraction() {
    local file_path="$1"
    local lines=$(wc -l < "$file_path")
    
    echo -e "${BLUE}🔍 Extraction Preview for: $(basename "$file_path")${NC}"
    echo "Current size: $lines lines"
    echo ""
    
    # Calculate potential reduction
    local target_files=3
    local avg_lines_per_file=$((lines / target_files))
    
    if [ "$avg_lines_per_file" -gt $MAX_LINES ]; then
        target_files=$(((lines / MAX_LINES) + 1))
        avg_lines_per_file=$((lines / target_files))
    fi
    
    echo -e "${CYAN}📊 Extraction Plan:${NC}"
    echo "Target files: $target_files"
    echo "Average lines per file: ~$avg_lines_per_file"
    echo "Compliance status after extraction: $([ "$avg_lines_per_file" -le $MAX_LINES ] && echo "✅ COMPLIANT" || echo "❌ NEEDS MORE SPLITTING")"
    
    echo ""
    echo -e "${CYAN}🎯 Recommended Structure:${NC}"
    local base_name=$(basename "$file_path" .swift)
    
    for i in $(seq 1 $target_files); do
        case $i in
            1) echo "  $base_name.swift (~$avg_lines_per_file lines) - Main interface" ;;
            2) echo "  ${base_name}Implementation.swift (~$avg_lines_per_file lines) - Core logic" ;;
            3) echo "  ${base_name}Extensions.swift (~$avg_lines_per_file lines) - Utilities" ;;
            *) echo "  ${base_name}Component$((i-3)).swift (~$avg_lines_per_file lines) - Additional component" ;;
        esac
    done
    
    echo ""
    echo -e "${GREEN}💾 Benefits of Extraction:${NC}"
    echo "• Improved maintainability"
    echo "• Better testability"
    echo "• Enhanced code reusability"
    echo "• Compliance with 300-line rule"
    echo "• Adherence to Single Responsibility Principle"
}

# Main execution
case "${1}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -a|--analyze)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please specify a file to analyze${NC}"
            exit 1
        fi
        analyze_file "$2"
        ;;
    -s|--suggest)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please specify a file for suggestions${NC}"
            exit 1
        fi
        suggest_extraction "$2"
        ;;
    -p|--preview)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please specify a file for preview${NC}"
            exit 1
        fi
        preview_extraction "$2"
        ;;
    "")
        echo -e "${RED}❌ No option specified${NC}"
        show_help
        exit 1
        ;;
    *)
        # Default to analysis if file path is provided directly
        if [ -f "$1" ]; then
            analyze_file "$1"
            echo ""
            suggest_extraction "$1"
        else
            echo -e "${RED}❌ Invalid option or file not found: $1${NC}"
            show_help
            exit 1
        fi
        ;;
esac
