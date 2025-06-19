#!/bin/bash

# PayslipMax Xcode Build Phase Script
# Runs quality checks during Xcode builds (Debug only)

# Only run in Debug configuration to avoid slowing down release builds
if [ "${CONFIGURATION}" != "Debug" ]; then
    echo "ℹ️ Skipping quality checks in ${CONFIGURATION} build"
    exit 0
fi

echo "🔍 Running technical debt checks during build..."

# Change to project root directory
cd "$SRCROOT"

# Run debt monitor with relaxed criteria for build-time checks
# We don't want to fail builds, just warn developers
if bash Scripts/debt-monitor.sh 2>/dev/null; then
    echo "✅ Code quality looks good!"
else
    echo "⚠️ Technical debt detected - consider running 'bash Scripts/debt-monitor.sh' for details"
    echo "💡 This doesn't block your build, but please review quality issues"
fi 