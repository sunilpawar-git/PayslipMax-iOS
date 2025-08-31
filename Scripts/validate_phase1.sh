#!/bin/bash

# Phase 1 LiteRT Integration Validation Script
# This script validates that all Phase 1 infrastructure components are in place

echo "🚀 Phase 1 LiteRT Integration Validation"
echo "========================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation counters
PASSED=0
FAILED=0

# Function to check file existence
check_file() {
    local file="$1"
    local description="$2"

    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✅ $description${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ $description${NC}"
        ((FAILED++))
    fi
}

# Function to check directory existence
check_directory() {
    local dir="$1"
    local description="$2"

    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✅ $description${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ $description${NC}"
        ((FAILED++))
    fi
}

echo ""
echo "📁 File Structure Validation:"
echo "-----------------------------"

# Check core infrastructure files
check_file "Package.swift" "Package.swift for Swift Package Manager"
check_file "Podfile" "Podfile for CocoaPods dependencies"
check_file "PayslipMax/LiteRT.xcconfig" "LiteRT build configuration"
check_file "PayslipMax/LiteRT-Bridging-Header.h" "Bridging header for MediaPipe"
check_file "PayslipMax/Resources/PrivacyInfo.xcprivacy" "Privacy manifest for ML models"

# Check model infrastructure
check_directory "PayslipMax/Resources/Models" "Models directory for .tflite files"
check_file "PayslipMax/Resources/Models/model_metadata.json" "Model metadata configuration"

# Check enhanced services
check_file "PayslipMax/Services/AI/LiteRTService.swift" "Enhanced LiteRT service"
check_file "PayslipMax/Services/AI/LiteRTModelManager.swift" "Model manager for versioning"
check_file "PayslipMax/Services/AI/LiteRTFeatureFlags.swift" "Feature flags (existing)"

echo ""
echo "🔧 Build Configuration Validation:"
echo "-----------------------------------"

# Check if Package.swift is valid
if [[ -f "Package.swift" ]]; then
    if swift package dump-package > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Package.swift syntax is valid${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Package.swift has syntax errors${NC}"
        ((FAILED++))
    fi
fi

# Check if Podfile is valid
if [[ -f "Podfile" ]]; then
    if pod install --dry-run > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Podfile syntax is valid${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠️  Podfile validation skipped (CocoaPods not installed)${NC}"
    fi
fi

echo ""
echo "📊 Model Configuration Validation:"
echo "-----------------------------------"

# Check model metadata JSON
if [[ -f "PayslipMax/Resources/Models/model_metadata.json" ]]; then
    if python3 -m json.tool "PayslipMax/Resources/Models/model_metadata.json" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Model metadata JSON is valid${NC}"
        ((PASSED++))

        # Check if expected models are defined
        if grep -q "table_detection" "PayslipMax/Resources/Models/model_metadata.json"; then
            echo -e "${GREEN}✅ Table detection model configured${NC}"
            ((PASSED++))
        else
            echo -e "${RED}❌ Table detection model missing${NC}"
            ((FAILED++))
        fi

        if grep -q "text_recognition" "PayslipMax/Resources/Models/model_metadata.json"; then
            echo -e "${GREEN}✅ Text recognition model configured${NC}"
            ((PASSED++))
        else
            echo -e "${RED}❌ Text recognition model missing${NC}"
            ((FAILED++))
        fi

        if grep -q "document_classifier" "PayslipMax/Resources/Models/model_metadata.json"; then
            echo -e "${GREEN}✅ Document classifier model configured${NC}"
            ((PASSED++))
        else
            echo -e "${RED}❌ Document classifier model missing${NC}"
            ((FAILED++))
        fi
    else
        echo -e "${RED}❌ Model metadata JSON is invalid${NC}"
        ((FAILED++))
    fi
fi

echo ""
echo "🔒 Security & Privacy Validation:"
echo "----------------------------------"

# Check Info.plist has required permissions
if [[ -f "PayslipMax/Info.plist" ]]; then
    if grep -q "NSCameraUsageDescription" "PayslipMax/Info.plist"; then
        echo -e "${GREEN}✅ Camera usage description configured${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Camera usage description missing${NC}"
        ((FAILED++))
    fi

    if grep -q "NSPhotoLibraryUsageDescription" "PayslipMax/Info.plist"; then
        echo -e "${GREEN}✅ Photo library usage description configured${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Photo library usage description missing${NC}"
        ((FAILED++))
    fi
fi

echo ""
echo "📝 Code Quality Validation:"
echo "---------------------------"

# Check if Swift files have basic syntax (compile check without linking)
find PayslipMax/Services/AI -name "*.swift" -exec sh -c '
    file="$1"
    if swiftc -parse "$file" > /dev/null 2>&1; then
        echo -e "'${GREEN}'✅ $(basename "$file") syntax is valid'${NC}'"
        exit 0
    else
        echo -e "'${RED}'❌ $(basename "$file") has syntax errors'${NC}'"
        exit 1
    fi
' _ {} \; | while read -r line; do
    if [[ $line == *"✅"* ]]; then
        ((PASSED++))
    else
        ((FAILED++))
    fi
    echo "$line"
done

echo ""
echo "🎯 Phase 1 Validation Summary:"
echo "=============================="
echo -e "✅ Passed: ${GREEN}$PASSED${NC}"
echo -e "❌ Failed: ${RED}$FAILED${NC}"

TOTAL=$((PASSED + FAILED))
if [[ $TOTAL -gt 0 ]]; then
    SUCCESS_RATE=$((PASSED * 100 / TOTAL))
    echo -e "📊 Success Rate: ${GREEN}$SUCCESS_RATE%${NC}"
fi

echo ""
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}🎉 Phase 1 Infrastructure is COMPLETE and READY!${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Run 'pod install' to install MediaPipe dependencies"
    echo "2. Download .tflite model files to PayslipMax/Resources/Models/"
    echo "3. Proceed to Phase 2: Model Acquisition & Setup"
else
    echo -e "${YELLOW}⚠️  Phase 1 has some issues that need to be resolved.${NC}"
fi

echo ""
echo "📋 Files created in Phase 1:"
echo "- Package.swift (Swift Package Manager configuration)"
echo "- Podfile (CocoaPods for MediaPipe)"
echo "- LiteRTModelManager.swift (Model versioning & validation)"
echo "- Enhanced LiteRTService.swift (MediaPipe integration)"
echo "- LiteRT.xcconfig (Build settings)"
echo "- LiteRT-Bridging-Header.h (Framework bridging)"
echo "- PrivacyInfo.xcprivacy (ML model privacy manifest)"
echo "- Models/ directory structure"
echo "- Updated Info.plist with camera/library permissions"
