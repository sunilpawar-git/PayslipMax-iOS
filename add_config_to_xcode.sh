#!/bin/bash

# Script to add Config directory to Xcode project
# This ensures APIKeys.swift is included in the build

echo "Adding Config directory to Xcode project..."

cd /Users/sunil/Downloads/PayslipMax

# Check if Config directory exists
if [ ! -d "Config" ]; then
    echo "Error: Config directory not found!"
    exit 1
fi

# Check if APIKeys.swift exists
if [ ! -f "Config/APIKeys.swift" ]; then
    echo "Error: Config/APIKeys.swift not found!"
    exit 1
fi

echo "✅ Config directory and APIKeys.swift found"
echo ""
echo "⚠️  MANUAL STEP REQUIRED:"
echo "The Config directory exists but needs to be added to your Xcode project."
echo ""
echo "Please follow these steps in Xcode:"
echo "1. Open PayslipMax.xcodeproj in Xcode"
echo "2. In the left sidebar (Project Navigator), right-click on 'PayslipMax' folder"
echo "3. Select 'Add Files to PayslipMax...'"
echo "4. Navigate to and select the 'Config' folder"
echo "5. Make sure these options are checked:"
echo "   ✅ 'Create groups' (NOT 'Create folder references')"
echo "   ✅ Target: 'PayslipMax'"
echo "6. Click 'Add'"
echo ""
echo "After adding, rebuild the project with: Cmd+B"
echo ""
echo "Security verification:"
git check-ignore Config/APIKeys.swift && echo "✅ APIKeys.swift is gitignored (safe)" || echo "⚠️  WARNING: APIKeys.swift not gitignored!"

exit 0
