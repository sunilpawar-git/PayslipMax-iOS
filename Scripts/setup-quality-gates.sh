#!/bin/bash

# PayslipMax Quality Gates Setup Script
# Activates dormant quality enforcement and prevents future violations
# Based on forensic analysis of how 58 files exceeded 300-line limit

set -e

echo "🛡️ PayslipMax Quality Gates Setup"
echo "=================================="
echo "Mission: Activate dormant quality enforcement system"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -d "PayslipMax" ] || [ ! -f "Scripts/architecture-guard.sh" ]; then
    echo -e "${RED}❌ Error: Run this script from PayslipMax project root${NC}"
    echo "Expected: PayslipMax/ directory and Scripts/architecture-guard.sh"
    exit 1
fi

echo -e "${BLUE}🔍 Analyzing current state...${NC}"

# Count current violations
CURRENT_VIOLATIONS=$(find PayslipMax -name "*.swift" -exec sh -c 'test $(wc -l < "$1") -gt 300' _ {} \; -print | wc -l)
echo "Current violations: $CURRENT_VIOLATIONS files >300 lines"

# Check if quality gates are already active
if [ -x ".git/hooks/pre-commit" ] && grep -q "architecture-guard\|pre-commit-enforcement" .git/hooks/pre-commit 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Quality gates appear to be already active${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}📋 Phase 1: Git Hook Integration${NC}"
echo "================================"

# Step 1: Make scripts executable
echo "Making quality scripts executable..."
chmod +x Scripts/*.sh
echo "✅ Scripts are now executable"

# Step 2: Install pre-commit hook
echo "Installing git pre-commit hook..."

# Backup existing hook if it exists
if [ -f ".git/hooks/pre-commit" ]; then
    echo "Backing up existing pre-commit hook..."
    cp .git/hooks/pre-commit .git/hooks/pre-commit.backup.$(date +%Y%m%d_%H%M%S)
fi

# Install new pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

# PayslipMax Quality Gate - Pre-Commit Hook
# Prevents commits that violate architectural constraints

echo "🔍 PayslipMax Quality Gate Enforcement..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VIOLATIONS=0

# Check file size compliance
echo "📏 Checking file size compliance (300-line rule)..."
while IFS= read -r -d '' file; do
    lines=$(wc -l < "$file")
    filename=$(basename "$file")
    
    # Skip test files for now (lower priority)
    if [[ "$file" == *"Test"* || "$file" == *"Mock"* ]]; then
        continue
    fi
    
    if [ "$lines" -gt 300 ]; then
        echo -e "${RED}❌ VIOLATION: $filename has $lines lines (>300)${NC}"
        echo "   File: $file"
        VIOLATIONS=$((VIOLATIONS + 1))
    elif [ "$lines" -gt 280 ]; then
        echo -e "${YELLOW}⚠️  WARNING: $filename has $lines lines (approaching limit)${NC}"
    fi
done < <(find PayslipMax -name "*.swift" -print0 2>/dev/null || true)

# Check MVVM compliance (no SwiftUI in Services)
echo "🏗️ Checking MVVM compliance..."
SWIFTUI_IN_SERVICES=$(find PayslipMax/Services -name "*.swift" -exec grep -l "import SwiftUI" {} \; 2>/dev/null | grep -v UIAppearanceService.swift || true)
if [ -n "$SWIFTUI_IN_SERVICES" ]; then
    echo -e "${RED}❌ MVVM VIOLATION: SwiftUI imported in services:${NC}"
    echo "$SWIFTUI_IN_SERVICES"
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Check async compliance (no DispatchSemaphore)
echo "⚡ Checking async-first compliance..."
DISPATCH_SEMAPHORE=$(grep -r "DispatchSemaphore" PayslipMax/ --include="*.swift" 2>/dev/null || true)
if [ -n "$DISPATCH_SEMAPHORE" ]; then
    echo -e "${RED}❌ ASYNC VIOLATION: DispatchSemaphore usage found${NC}"
    echo "$DISPATCH_SEMAPHORE" | head -3
    VIOLATIONS=$((VIOLATIONS + 1))
fi

# Final verdict
if [ $VIOLATIONS -eq 0 ]; then
    echo -e "${GREEN}✅ All quality gates passed! Commit approved.${NC}"
    exit 0
else
    echo -e "${RED}❌ Quality gate failures detected ($VIOLATIONS violations)${NC}"
    echo ""
    echo "🔧 To fix file size violations:"
    echo "   ./Scripts/component-extraction-helper.sh"
    echo ""
    echo "💡 To bypass this check (NOT RECOMMENDED):"
    echo "   git commit --no-verify -m \"Your message\""
    echo ""
    echo "📚 Architecture guidelines:"
    echo "   Documentation/TechnicalDebtReduction/DebtEliminationRoadmap2024.md"
    exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
echo "✅ Pre-commit hook installed and activated"

echo ""
echo -e "${BLUE}📋 Phase 2: Xcode Build Integration${NC}"
echo "=================================="

# Check if this is an Xcode project
if [ -f "PayslipMax.xcodeproj/project.pbxproj" ]; then
    echo "Xcode project detected"
    echo "⚠️  Manual step required:"
    echo "   1. Open PayslipMax.xcodeproj in Xcode"
    echo "   2. Select PayslipMax target"
    echo "   3. Go to Build Phases"
    echo "   4. Click '+' → New Run Script Phase"
    echo "   5. Name: 'Architecture Quality Gate'"
    echo "   6. Add this script:"
    echo ""
    echo "   #!/bin/bash"
    echo "   cd \"\$PROJECT_DIR\""
    echo "   if [ -f \"./Scripts/architecture-guard.sh\" ]; then"
    echo "       chmod +x ./Scripts/architecture-guard.sh"
    echo "       ./Scripts/architecture-guard.sh --build-mode"
    echo "       if [ \$? -ne 0 ]; then"
    echo "           echo \"❌ Build failed due to architectural violations\""
    echo "           exit 1"
    echo "       fi"
    echo "   fi"
    echo ""
    echo "   7. Move this phase to run early (after 'Target Dependencies')"
else
    echo "⚠️  No Xcode project found - skipping build integration"
fi

echo ""
echo -e "${BLUE}📋 Phase 3: Enhanced Architecture Guard${NC}"
echo "======================================"

# Enhance architecture-guard.sh with new modes
if [ -f "Scripts/architecture-guard.sh" ]; then
    echo "Enhancing architecture-guard.sh with new capabilities..."
    
    # Add build mode support if not already present
    if ! grep -q "build-mode" Scripts/architecture-guard.sh; then
        cat >> Scripts/architecture-guard.sh << 'EOF'

# Enhanced modes for different use cases
case "$1" in
    --build-mode)
        echo "🏗️ Build-time architecture check..."
        # Quick check optimized for build performance
        violations=0
        while IFS= read -r -d '' file; do
            lines=$(wc -l < "$file")
            if [ "$lines" -gt 300 ] && [[ "$file" != *"Test"* ]] && [[ "$file" != *"Mock"* ]]; then
                echo "❌ $(basename "$file"): $lines lines"
                violations=$((violations + 1))
            fi
        done < <(find PayslipMax -name "*.swift" -print0)
        
        if [ $violations -gt 0 ]; then
            echo "❌ $violations architectural violations - build failed"
            exit 1
        fi
        echo "✅ Architecture compliance verified"
        exit 0
        ;;
        
    --count-violations)
        find PayslipMax -name "*.swift" -exec sh -c 'test $(wc -l < "$1") -gt 300' _ {} \; -print | wc -l
        exit 0
        ;;
        
    --fix-suggestions)
        echo "🔧 Architectural Violation Fix Suggestions"
        echo "========================================"
        find PayslipMax -name "*.swift" -exec sh -c 'test $(wc -l < "$1") -gt 300' _ {} \; -print | while read file; do
            lines=$(wc -l < "$file")
            filename=$(basename "$file")
            echo ""
            echo "📄 $filename ($lines lines)"
            
            # Analyze file type and suggest fixes
            if [[ "$filename" == *"ViewModel"* ]]; then
                echo "💡 Extract: Actions, Validation, Support files"
            elif [[ "$filename" == *"Service"* ]]; then
                echo "💡 Extract: Algorithms, Validation, Utilities"
            elif [[ "$filename" == *"View"* ]]; then
                echo "💡 Extract: Components, Helpers, Models"
            else
                echo "💡 Extract: Protocols, Extensions, Support classes"
            fi
            
            echo "🔧 Command: ./Scripts/component-extraction-helper.sh '$file'"
        done
        exit 0
        ;;
esac
EOF
        echo "✅ Architecture guard enhanced with new modes"
    else
        echo "✅ Architecture guard already has enhanced modes"
    fi
else
    echo "❌ Scripts/architecture-guard.sh not found"
fi

echo ""
echo -e "${BLUE}📋 Phase 4: Testing Quality Gates${NC}"
echo "================================"

echo "Testing pre-commit hook..."
# Create a temporary test file to trigger the hook
echo "// Test file with many lines" > test-temp.swift
for i in {1..310}; do
    echo "// Line $i" >> test-temp.swift
done

# Add to git and try to commit (should fail)
git add test-temp.swift
echo "Attempting test commit (should fail)..."
if git commit -m "Test commit - should fail" 2>&1 | grep -q "Quality gate failures"; then
    echo -e "${GREEN}✅ Pre-commit hook is working correctly (rejected test commit)${NC}"
    git reset HEAD test-temp.swift
    rm test-temp.swift
else
    echo -e "${RED}❌ Pre-commit hook may not be working properly${NC}"
    git reset HEAD test-temp.swift 2>/dev/null || true
    rm -f test-temp.swift
fi

echo ""
echo -e "${BLUE}📋 Phase 5: Developer Tools Setup${NC}"
echo "================================"

# Create component extraction helper if it doesn't exist
if [ ! -f "Scripts/component-extraction-helper.sh" ]; then
    echo "Creating component extraction helper..."
    cat > Scripts/component-extraction-helper.sh << 'EOF'
#!/bin/bash

# PayslipMax Component Extraction Helper
# Provides guided refactoring for files exceeding 300-line limit

if [ $# -eq 0 ]; then
    echo "Usage: $0 <swift-file>"
    echo ""
    echo "Analyzes a Swift file and provides refactoring suggestions"
    echo "to bring it under the 300-line architectural limit"
    exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
    echo "❌ File not found: $FILE"
    exit 1
fi

LINES=$(wc -l < "$FILE")
FILENAME=$(basename "$FILE" .swift)

echo "📊 Analyzing $FILE"
echo "Current size: $LINES lines"

if [ "$LINES" -le 300 ]; then
    echo "✅ File is already compliant (<300 lines)"
    exit 0
fi

echo ""
echo "🔍 Structure Analysis:"

# Count different code elements
PROTOCOLS=$(grep -c "protocol.*{" "$FILE" 2>/dev/null || echo "0")
CLASSES=$(grep -c "class.*{" "$FILE" 2>/dev/null || echo "0")
STRUCTS=$(grep -c "struct.*{" "$FILE" 2>/dev/null || echo "0")
EXTENSIONS=$(grep -c "extension.*{" "$FILE" 2>/dev/null || echo "0")
FUNCTIONS=$(grep -c "func " "$FILE" 2>/dev/null || echo "0")

echo "  Protocols: $PROTOCOLS"
echo "  Classes: $CLASSES"
echo "  Structs: $STRUCTS"
echo "  Extensions: $EXTENSIONS"
echo "  Functions: $FUNCTIONS"

echo ""
echo "💡 Refactoring Suggestions:"

DIR=$(dirname "$FILE")

# Suggest specific extractions
if [ "$PROTOCOLS" -gt 0 ]; then
    echo "  1. Extract protocols → ${DIR}/${FILENAME}Protocols.swift"
fi

if [ "$EXTENSIONS" -gt 1 ]; then
    echo "  2. Extract extensions → ${DIR}/${FILENAME}Extensions.swift"
fi

if [ "$FUNCTIONS" -gt 10 ]; then
    echo "  3. Group functions → ${DIR}/${FILENAME}Helpers.swift"
fi

# File-type specific suggestions
if [[ "$FILENAME" == *"ViewModel"* ]]; then
    echo "  4. Extract actions → ${DIR}/${FILENAME}Actions.swift"
    echo "  5. Extract validation → ${DIR}/${FILENAME}Validation.swift"
elif [[ "$FILENAME" == *"Service"* ]]; then
    echo "  4. Extract algorithms → ${DIR}/${FILENAME}Algorithms.swift"
    echo "  5. Extract validation → ${DIR}/${FILENAME}Validation.swift"
elif [[ "$FILENAME" == *"View"* ]]; then
    echo "  4. Extract components → ${DIR}/Components/${FILENAME}Components.swift"
    echo "  5. Extract helpers → ${DIR}/${FILENAME}Helpers.swift"
fi

echo ""
echo "🔧 Next Steps:"
echo "  1. Create component directory: mkdir -p ${DIR}/Components"
echo "  2. Extract largest logical groups first"
echo "  3. Maintain public interface compatibility"
echo "  4. Test after each extraction"
echo "  5. Update imports in dependent files"

echo ""
echo "📚 Reference: Documentation/TechnicalDebtReduction/DebtEliminationRoadmap2024.md"
EOF
    chmod +x Scripts/component-extraction-helper.sh
    echo "✅ Component extraction helper created"
else
    echo "✅ Component extraction helper already exists"
fi

echo ""
echo -e "${GREEN}🎉 Quality Gates Setup Complete!${NC}"
echo "================================"
echo ""
echo "📊 Current Status:"
echo "  Files >300 lines: $CURRENT_VIOLATIONS"
echo "  Pre-commit hook: ✅ Active"
echo "  Architecture guard: ✅ Enhanced"
echo "  Build integration: ⚠️  Manual step required (Xcode)"
echo ""
echo "🔧 Available Tools:"
echo "  ./Scripts/architecture-guard.sh           - Full compliance check"
echo "  ./Scripts/architecture-guard.sh --count-violations - Count violations"
echo "  ./Scripts/architecture-guard.sh --fix-suggestions  - Get fix suggestions"
echo "  ./Scripts/component-extraction-helper.sh <file>    - Guided refactoring"
echo ""
echo "📋 Next Steps:"
echo "  1. Complete Xcode build integration (see instructions above)"
echo "  2. Start fixing violations: ./Scripts/architecture-guard.sh --fix-suggestions"
echo "  3. Follow roadmap: Documentation/TechnicalDebtReduction/DebtEliminationRoadmap2024.md"
echo ""
echo -e "${YELLOW}⚠️  Remember: Quality gates will now block commits with violations!${NC}"
echo "   To bypass (NOT RECOMMENDED): git commit --no-verify"
echo ""
echo "🚀 Quality gates are now active and protecting your architecture!"
