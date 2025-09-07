#!/bin/bash

# PayslipMax Smart Component Extraction Helper
# AI-powered analysis and refactoring suggestions for maintaining 300-line rule
# Part of Phase 4: Bulletproof Prevention System

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
MAX_LINES=300
WARNING_THRESHOLD=250
CRITICAL_THRESHOLD=280

echo -e "${BLUE}🔧 PayslipMax Component Extraction Helper${NC}"
echo "============================================="

# Function to analyze file structure
analyze_file_structure() {
    local file="$1"
    local filename=$(basename "$file")
    local lines=$(wc -l < "$file")

    echo -e "${CYAN}📊 Analyzing $filename ($lines lines)...${NC}"
    echo ""

    # Basic structure analysis
    local imports=$(grep -c "^import " "$file" 2>/dev/null || echo "0")
    local protocols=$(grep -c "protocol.*{" "$file" 2>/dev/null || echo "0")
    local classes=$(grep -c "class.*{" "$file" 2>/dev/null || echo "0")
    local structs=$(grep -c "struct.*{" "$file" 2>/dev/null || echo "0")
    local extensions=$(grep -c "extension.*{" "$file" 2>/dev/null || echo "0")
    local functions=$(grep -c "func " "$file" 2>/dev/null || echo "0")
    local computed_props=$(grep -c "var.*{" "$file" 2>/dev/null || echo "0")
    local enums=$(grep -c "enum.*{" "$file" 2>/dev/null || echo "0")

    # Advanced analysis
    local init_methods=$(grep -c "init(" "$file" 2>/dev/null || echo "0")
    local async_functions=$(grep -c "func.*async" "$file" 2>/dev/null || echo "0")
    local published_props=$(grep -c "@Published" "$file" 2>/dev/null || echo "0")
    local state_props=$(grep -c "@State" "$file" 2>/dev/null || echo "0")
    local private_methods=$(grep -c "private func" "$file" 2>/dev/null || echo "0")
    local public_methods=$(grep -c "public func" "$file" 2>/dev/null || echo "0")
    local internal_methods=$(grep -c "internal func\|^[[:space:]]*func" "$file" 2>/dev/null || echo "0")

    # MARK comments analysis
    local mark_sections=$(grep -c "// MARK:" "$file" 2>/dev/null || echo "0")

    echo -e "${BLUE}📋 Structure Analysis:${NC}"
    echo "   Imports: $imports"
    echo "   Protocols: $protocols"
    echo "   Classes: $classes"
    echo "   Structs: $structs"
    echo "   Extensions: $extensions"
    echo "   Enums: $enums"
    echo "   Functions: $functions"
    echo "   Computed Properties: $computed_props"
    echo "   Init Methods: $init_methods"
    echo "   MARK Sections: $mark_sections"
    echo ""

    echo -e "${BLUE}🔍 Advanced Analysis:${NC}"
    echo "   Async Functions: $async_functions"
    echo "   @Published Properties: $published_props"
    echo "   @State Properties: $state_props"
    echo "   Private Methods: $private_methods"
    echo "   Public Methods: $public_methods"
    echo "   Internal Methods: $internal_methods"
    echo ""

    # Store analysis results for use in suggestions
    export FILE_LINES=$lines
    export FILE_PROTOCOLS=$protocols
    export FILE_CLASSES=$classes
    export FILE_STRUCTS=$structs
    export FILE_EXTENSIONS=$extensions
    export FILE_FUNCTIONS=$functions
    export FILE_COMPUTED_PROPS=$computed_props
    export FILE_ENUMS=$enums
    export FILE_INIT_METHODS=$init_methods
    export FILE_ASYNC_FUNCTIONS=$async_functions
    export FILE_PUBLISHED_PROPS=$published_props
    export FILE_PRIVATE_METHODS=$private_methods
    export FILE_PUBLIC_METHODS=$public_methods
    export FILE_MARK_SECTIONS=$mark_sections
}

# Function to determine file type and appropriate strategy
determine_extraction_strategy() {
    local file="$1"
    local filename=$(basename "$file")

    echo -e "${MAGENTA}🎯 Determining Extraction Strategy...${NC}"

    # Analyze file type based on naming and content
    if [[ "$filename" == *ViewModel* ]]; then
        echo "   File Type: ViewModel"
        suggest_viewmodel_extraction "$file"
    elif [[ "$filename" == *Service* ]] || [[ "$filename" == *Manager* ]]; then
        echo "   File Type: Service/Manager"
        suggest_service_extraction "$file"
    elif [[ "$filename" == *View* ]] && grep -q "import SwiftUI" "$file" 2>/dev/null; then
        echo "   File Type: SwiftUI View"
        suggest_view_extraction "$file"
    elif [[ "$filename" == *Model* ]] || [[ "$filename" == *Data* ]]; then
        echo "   File Type: Model/Data"
        suggest_model_extraction "$file"
    elif grep -q "protocol.*{" "$file" 2>/dev/null; then
        echo "   File Type: Protocol-heavy"
        suggest_protocol_extraction "$file"
    else
        echo "   File Type: General"
        suggest_general_extraction "$file"
    fi
}

# Function to suggest ViewModel extraction
suggest_viewmodel_extraction() {
    local file="$1"
    local basename=$(basename "$file" .swift)
    local dirname=$(dirname "$file")

    echo -e "${GREEN}📝 ViewModel Extraction Suggestions:${NC}"
    echo ""

    if [ "$FILE_LINES" -gt $CRITICAL_THRESHOLD ]; then
        echo -e "${RED}🚨 CRITICAL: Immediate extraction required${NC}"
    elif [ "$FILE_LINES" -gt $WARNING_THRESHOLD ]; then
        echo -e "${YELLOW}⚠️  WARNING: Plan extraction soon${NC}"
    fi

    echo "Recommended 4-component pattern for ViewModels:"
    echo ""
    echo "1. ${basename}.swift (Core state and initialization, target: <200 lines)"
    echo "   - @Published properties"
    echo "   - Dependencies injection"
    echo "   - Basic initialization"
    echo ""
    echo "2. ${basename}Actions.swift (Action methods, target: <150 lines)"
    echo "   - All public action methods"
    echo "   - User interaction handlers"
    echo "   - Async operations"
    echo ""
    echo "3. ${basename}Setup.swift (Setup and bindings, target: <150 lines)"
    echo "   - Coordinator setup"
    echo "   - Notification bindings"
    echo "   - Initial data loading"
    echo ""
    echo "4. ${basename}Support.swift (Utilities and helpers, target: <100 lines)"
    echo "   - Computed properties"
    echo "   - Helper methods"
    echo "   - Convenience functions"
    echo ""

    generate_viewmodel_commands "$file" "$basename" "$dirname"
}

# Function to suggest Service extraction
suggest_service_extraction() {
    local file="$1"
    local basename=$(basename "$file" .swift)
    local dirname=$(dirname "$file")

    echo -e "${GREEN}🔧 Service Extraction Suggestions:${NC}"
    echo ""

    echo "Recommended pattern for Services:"
    echo ""
    echo "1. ${basename}Protocols.swift (Protocols and types, target: <100 lines)"
    echo "   - Protocol definitions"
    echo "   - Associated types"
    echo "   - Error enums"
    echo ""
    echo "2. ${basename}Core.swift (Core service logic, target: <200 lines)"
    echo "   - Main service class"
    echo "   - Dependencies"
    echo "   - Primary interface methods"
    echo ""
    echo "3. ${basename}Operations.swift (Operations, target: <150 lines)"
    echo "   - Complex algorithms"
    echo "   - Data processing"
    echo "   - Async operations"
    echo ""
    echo "4. ${basename}Support.swift (Utilities, target: <100 lines)"
    echo "   - Helper methods"
    echo "   - Validation logic"
    echo "   - Extension functionality"
    echo ""

    generate_service_commands "$file" "$basename" "$dirname"
}

# Function to suggest View extraction
suggest_view_extraction() {
    local file="$1"
    local basename=$(basename "$file" .swift)
    local dirname=$(dirname "$file")

    echo -e "${GREEN}🎨 SwiftUI View Extraction Suggestions:${NC}"
    echo ""

    echo "Recommended pattern for Views:"
    echo ""
    echo "1. ${basename}.swift (Core view and layout, target: <200 lines)"
    echo "   - Main view structure"
    echo "   - Navigation and state"
    echo "   - High-level layout"
    echo ""
    echo "2. ${basename}Components.swift (UI components, target: <200 lines)"
    echo "   - Reusable view components"
    echo "   - Individual UI elements"
    echo "   - Custom view builders"
    echo ""
    echo "3. ${basename}Helpers.swift (Helper views and logic, target: <150 lines)"
    echo "   - Supporting views"
    echo "   - Custom styles"
    echo "   - View utilities"
    echo ""

    generate_view_commands "$file" "$basename" "$dirname"
}

# Function to suggest Model extraction
suggest_model_extraction() {
    local file="$1"
    local basename=$(basename "$file" .swift)
    local dirname=$(dirname "$file")

    echo -e "${GREEN}📊 Model Extraction Suggestions:${NC}"
    echo ""

    echo "Recommended pattern for Models:"
    echo ""
    echo "1. ${basename}Core.swift (Core model, target: <200 lines)"
    echo "   - Main struct/class definition"
    echo "   - Essential properties"
    echo "   - Basic initialization"
    echo ""
    echo "2. ${basename}Extensions.swift (Extensions, target: <150 lines)"
    echo "   - Computed properties"
    echo "   - Helper methods"
    echo "   - Protocol conformances"
    echo ""
    echo "3. ${basename}Factory.swift (Factory methods, target: <150 lines)"
    echo "   - Complex initialization"
    echo "   - Creation methods"
    echo "   - Builder patterns"
    echo ""

    generate_model_commands "$file" "$basename" "$dirname"
}

# Function to suggest protocol extraction
suggest_protocol_extraction() {
    local file="$1"
    local basename=$(basename "$file" .swift)
    local dirname=$(dirname "$file")

    echo -e "${GREEN}🔗 Protocol Extraction Suggestions:${NC}"
    echo ""

    if [ "$FILE_PROTOCOLS" -gt 2 ]; then
        echo "Multiple protocols detected - extract to separate file:"
        echo ""
        echo "1. ${basename}Protocols.swift (Protocol definitions)"
        echo "2. ${basename}Implementations.swift (Concrete implementations)"
        echo ""
    fi

    if [ "$FILE_EXTENSIONS" -gt 3 ]; then
        echo "Multiple extensions detected - group by functionality:"
        echo ""
        echo "1. ${basename}Extensions.swift (Related extensions)"
        echo "2. ${basename}ProtocolConformances.swift (Protocol conformances)"
        echo ""
    fi
}

# Function to suggest general extraction
suggest_general_extraction() {
    local file="$1"
    local basename=$(basename "$file" .swift)

    echo -e "${GREEN}🔄 General Extraction Suggestions:${NC}"
    echo ""

    if [ "$FILE_FUNCTIONS" -gt 15 ]; then
        echo "• High function count - group related functions into helper classes"
    fi

    if [ "$FILE_EXTENSIONS" -gt 2 ]; then
        echo "• Multiple extensions - extract to separate files by functionality"
    fi

    if [ "$FILE_PROTOCOLS" -gt 1 ]; then
        echo "• Multiple protocols - extract to ${basename}Protocols.swift"
    fi

    if [ "$FILE_ENUMS" -gt 3 ]; then
        echo "• Multiple enums - extract to ${basename}Types.swift"
    fi
}

# Function to generate ViewModel extraction commands
generate_viewmodel_commands() {
    local file="$1"
    local basename="$2"
    local dirname="$3"

    echo -e "${CYAN}🔧 Extraction Commands:${NC}"
    echo ""
    echo "# Create component files"
    echo "mkdir -p \"$dirname/Components\""
    echo ""
    echo "# 1. Extract Actions to separate file"
    echo "grep -A 200 'MARK.*Action\\|func.*Action\\|func.*Load\\|func.*Save\\|func.*Delete' \"$file\" > \"$dirname/${basename}Actions.swift\""
    echo ""
    echo "# 2. Extract Setup logic"
    echo "grep -A 100 'MARK.*Setup\\|func.*setup\\|func.*bind\\|NotificationCenter' \"$file\" > \"$dirname/${basename}Setup.swift\""
    echo ""
    echo "# 3. Extract Support utilities"
    echo "grep -A 50 'MARK.*Support\\|var.*Bool\\|func.*helper\\|computed property' \"$file\" > \"$dirname/${basename}Support.swift\""
    echo ""
    echo "# Manual steps:"
    echo "# 1. Move @Published properties to Core file"
    echo "# 2. Move dependencies and init to Core file"
    echo "# 3. Move action methods to Actions file"
    echo "# 4. Move setup/binding methods to Setup file"
    echo "# 5. Move helper/computed properties to Support file"
    echo "# 6. Add proper imports and class extensions"
    echo "# 7. Test compilation after each step"
}

# Function to generate Service extraction commands
generate_service_commands() {
    local file="$1"
    local basename="$2"
    local dirname="$3"

    echo -e "${CYAN}🔧 Extraction Commands:${NC}"
    echo ""
    echo "# Create protocol file first"
    echo "grep -A 50 'protocol.*{' \"$file\" > \"$dirname/${basename}Protocols.swift\""
    echo ""
    echo "# Extract core service"
    echo "grep -A 100 'class.*{\\|struct.*{' \"$file\" | head -n 100 > \"$dirname/${basename}Core.swift\""
    echo ""
    echo "# Extract operations"
    echo "grep -A 200 'MARK.*Operation\\|func.*async\\|func.*process' \"$file\" > \"$dirname/${basename}Operations.swift\""
    echo ""
    echo "# Extract support utilities"
    echo "grep -A 50 'private func\\|helper\\|utility' \"$file\" > \"$dirname/${basename}Support.swift\""
}

# Function to generate View extraction commands
generate_view_commands() {
    local file="$1"
    local basename="$2"
    local dirname="$3"

    echo -e "${CYAN}🔧 Extraction Commands:${NC}"
    echo ""
    echo "# Extract components"
    echo "grep -A 100 'struct.*View\\|var.*some View' \"$file\" | grep -v '^--' > \"$dirname/${basename}Components.swift\""
    echo ""
    echo "# Extract helpers and styles"
    echo "grep -A 50 'ButtonStyle\\|ViewModifier\\|Color\\|Font' \"$file\" > \"$dirname/${basename}Helpers.swift\""
}

# Function to generate Model extraction commands
generate_model_commands() {
    local file="$1"
    local basename="$2"
    local dirname="$3"

    echo -e "${CYAN}🔧 Extraction Commands:${NC}"
    echo ""
    echo "# Extract core model"
    echo "grep -A 100 'struct.*{\\|class.*{' \"$file\" | head -n 100 > \"$dirname/${basename}Core.swift\""
    echo ""
    echo "# Extract extensions"
    echo "grep -A 200 'extension.*{' \"$file\" > \"$dirname/${basename}Extensions.swift\""
    echo ""
    echo "# Extract factory methods"
    echo "grep -A 100 'static func\\|init.*{\\|convenience init' \"$file\" > \"$dirname/${basename}Factory.swift\""
}

# Function to provide specific line-by-line guidance
provide_detailed_guidance() {
    local file="$1"

    echo -e "${MAGENTA}📝 Detailed Extraction Guidance:${NC}"
    echo ""

    echo "Step-by-step extraction process:"
    echo ""
    echo "1. **Backup Original File**"
    echo "   cp \"$file\" \"$file.backup\""
    echo ""
    echo "2. **Create Protocol File First** (if applicable)"
    echo "   - Extract all protocol definitions"
    echo "   - Include associated types and enums"
    echo "   - Add proper imports"
    echo ""
    echo "3. **Extract Core Implementation**"
    echo "   - Keep main class/struct definition"
    echo "   - Include essential properties"
    echo "   - Basic initialization only"
    echo ""
    echo "4. **Extract Secondary Components**"
    echo "   - Group related functionality"
    echo "   - Use extensions for organization"
    echo "   - Maintain single responsibility"
    echo ""
    echo "5. **Verify and Test**"
    echo "   - Compile after each extraction"
    echo "   - Run tests to ensure functionality"
    echo "   - Check architecture compliance"
    echo ""
    echo "6. **Final Validation**"
    echo "   ./Scripts/architecture-guard.sh"
    echo "   # All extracted files should be <300 lines"
}

# Function to provide automation assistance
provide_automation_assistance() {
    local file="$1"
    local basename=$(basename "$file" .swift)

    echo -e "${BLUE}🤖 Automation Assistance:${NC}"
    echo ""

    echo "Run this automated extraction starter:"
    echo ""
    cat << EOF
# PayslipMax Component Extraction Script for $basename
#!/bin/bash

FILE="$file"
BASENAME="$basename"
DIRNAME="\$(dirname "\$FILE")"
BACKUP_FILE="\$FILE.backup"

echo "Starting component extraction for \$BASENAME..."

# 1. Create backup
cp "\$FILE" "\$BACKUP_FILE"
echo "✅ Backup created: \$BACKUP_FILE"

# 2. Create directory structure
mkdir -p "\$DIRNAME/Components"

# 3. Analyze current file
echo "📊 Current file: \$(wc -l < "\$FILE") lines"

# 4. Extract based on MARK sections
awk '/MARK.*Protocol/,/^}/ {print}' "\$FILE" > "\$DIRNAME/\${BASENAME}Protocols.swift" 2>/dev/null || true
awk '/MARK.*Extension/,/^}/ {print}' "\$FILE" > "\$DIRNAME/\${BASENAME}Extensions.swift" 2>/dev/null || true

# 5. Verify extracted files
for extracted_file in "\$DIRNAME/\${BASENAME}"*.swift; do
    if [ -f "\$extracted_file" ] && [ -s "\$extracted_file" ]; then
        lines=\$(wc -l < "\$extracted_file")
        echo "📄 \$(basename "\$extracted_file"): \$lines lines"
    fi
done

echo "🔧 Manual steps still required:"
echo "1. Review and refine extracted files"
echo "2. Add proper imports and structure"
echo "3. Test compilation"
echo "4. Run architecture check"

EOF
}

# Function to analyze all files needing extraction
analyze_all_violations() {
    echo -e "${RED}🚨 Analyzing All Architecture Violations${NC}"
    echo "============================================="
    echo ""

    local violation_count=0

    while IFS= read -r -d '' file; do
        lines=$(wc -l < "$file")
        filename=$(basename "$file")

        if [ "$lines" -gt $MAX_LINES ]; then
            violation_count=$((violation_count + 1))

            echo -e "${RED}$violation_count. $filename: $lines lines${NC}"
            echo "   Priority: $([ "$lines" -gt 400 ] && echo "CRITICAL" || echo "HIGH")"
            echo "   Suggested approach: $(determine_file_type "$file")"
            echo ""
        fi
    done < <(find PayslipMax -name "*.swift" -print0)

    if [ $violation_count -eq 0 ]; then
        echo -e "${GREEN}🎉 No violations found! All files comply with 300-line rule.${NC}"
    else
        echo -e "${YELLOW}📊 Total violations: $violation_count files${NC}"
        echo ""
        echo "Recommended order for refactoring:"
        echo "1. Files >400 lines (CRITICAL priority)"
        echo "2. ViewModels and Services (High impact)"
        echo "3. Views and Models (Medium impact)"
        echo "4. Utilities and Extensions (Lower impact)"
    fi
}

# Helper function to determine file type
determine_file_type() {
    local file="$1"
    local filename=$(basename "$file")

    if [[ "$filename" == *ViewModel* ]]; then
        echo "ViewModel (4-component pattern)"
    elif [[ "$filename" == *Service* ]]; then
        echo "Service (Protocol + Core + Operations + Support)"
    elif [[ "$filename" == *View* ]]; then
        echo "View (Core + Components + Helpers)"
    elif [[ "$filename" == *Model* ]]; then
        echo "Model (Core + Extensions + Factory)"
    else
        echo "General (Function/protocol-based extraction)"
    fi
}

# Main function
main() {
    case "$1" in
        --analyze-file)
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Error: Please specify a file to analyze${NC}"
                echo "Usage: $0 --analyze-file <filepath>"
                exit 1
            fi

            if [ ! -f "$2" ]; then
                echo -e "${RED}❌ Error: File not found: $2${NC}"
                exit 1
            fi

            analyze_file_structure "$2"
            determine_extraction_strategy "$2"
            provide_detailed_guidance "$2"
            provide_automation_assistance "$2"
            ;;

        --analyze-all)
            analyze_all_violations
            ;;

        --quick-suggestions)
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Error: Please specify a file${NC}"
                exit 1
            fi

            local lines=$(wc -l < "$2" 2>/dev/null || echo "0")
            local filename=$(basename "$2")

            echo -e "${BLUE}Quick suggestions for $filename ($lines lines):${NC}"

            if [ "$lines" -gt $MAX_LINES ]; then
                echo -e "${RED}🚨 EXCEEDS 300 LINES - Immediate action required${NC}"
                determine_file_type "$2"
            elif [ "$lines" -gt $WARNING_THRESHOLD ]; then
                echo -e "${YELLOW}⚠️  Approaching limit - Plan extraction${NC}"
            else
                echo -e "${GREEN}✅ Within limits${NC}"
            fi
            ;;

        --help)
            cat << EOF
PayslipMax Component Extraction Helper

Usage: $0 [--analyze-file <file>|--analyze-all|--quick-suggestions <file>|--help]

Commands:
  --analyze-file <file>     Detailed analysis and extraction suggestions for specific file
  --analyze-all            Analyze all files exceeding 300-line limit
  --quick-suggestions <file> Quick status and basic suggestions
  --help                   Show this help message

Examples:
  $0 --analyze-file PayslipMax/Features/Home/ViewModels/HomeViewModel.swift
  $0 --analyze-all
  $0 --quick-suggestions SomeFile.swift

Description:
  Provides intelligent suggestions for extracting components from large files
  to maintain the 300-line rule. Analyzes file structure and suggests
  appropriate extraction patterns based on file type and content.
EOF
            ;;

        *)
            if [ -n "$1" ] && [ -f "$1" ]; then
                # Default behavior: analyze provided file
                main --analyze-file "$1"
            else
                echo -e "${BLUE}🔧 PayslipMax Component Extraction Helper${NC}"
                echo "Usage: $0 [--analyze-file <file>|--analyze-all|--help]"
                echo ""
                echo "Quick start:"
                echo "  $0 --analyze-all                    # Show all violations"
                echo "  $0 --analyze-file <filename>        # Detailed file analysis"
                echo "  $0 <filename>                       # Same as --analyze-file"
                echo ""
                echo "Run '$0 --help' for full usage information."
            fi
            ;;
    esac
}

# Execute main function
main "$@"
