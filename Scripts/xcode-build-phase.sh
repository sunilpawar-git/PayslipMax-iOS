#!/bin/bash

# PayslipMax Xcode Build Phase - Architecture Quality Gate
# Integrates architecture checking into Xcode build process

echo "🔍 PayslipMax Architecture Quality Gate"
echo "======================================"

# Ensure we're in the project directory
cd "$PROJECT_DIR" || exit 1

# Check if architecture guard script exists
if [ ! -f "./Scripts/architecture-guard.sh" ]; then
    echo "⚠️ Architecture guard script not found, skipping check"
    exit 0
fi

# Make script executable
chmod +x ./Scripts/architecture-guard.sh

# Run architecture check in build mode (fast check)
echo "Running quick architecture compliance check..."
if ./Scripts/architecture-guard.sh --build-mode; then
    echo "✅ Architecture quality gate passed"
else
    echo "❌ Architecture quality gate failed"
    echo ""
    echo "🔧 Fix violations before building:"
    echo "   1. Check file sizes: find PayslipMax -name '*.swift' -exec wc -l {} + | sort -n"
    echo "   2. Get fix suggestions: ./Scripts/architecture-guard.sh --fix-suggestions"
    echo "   3. Use component extraction: ./Scripts/component-extraction-helper.sh"
    echo ""
    exit 1
fi
