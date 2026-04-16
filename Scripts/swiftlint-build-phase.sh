#!/bin/bash

# PayslipMax SwiftLint Build Phase
# Runs SwiftLint during Xcode builds to catch style violations early
# Aligned with Apple/Swift guidelines and project-specific MVVM rules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Only run in Debug configuration to avoid slowing down release builds
# Set SWIFTLINT_ALWAYS_RUN=1 to run in all configurations
if [ "${SWIFTLINT_ALWAYS_RUN}" != "1" ] && [ "${CONFIGURATION}" != "Debug" ]; then
    echo -e "${BLUE}ℹ️  SwiftLint: Skipping in ${CONFIGURATION} build (set SWIFTLINT_ALWAYS_RUN=1 to enable)${NC}"
    exit 0
fi

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo -e "${YELLOW}⚠️  SwiftLint not installed. Install with: brew install swiftlint${NC}"
    echo -e "${YELLOW}   Build will continue, but code style checks are skipped.${NC}"
    exit 0
fi

# Change to project root directory
cd "${SRCROOT}" || exit 1

# Check if .swiftlint.yml exists
if [ ! -f ".swiftlint.yml" ]; then
    echo -e "${YELLOW}⚠️  .swiftlint.yml not found in project root${NC}"
    exit 0
fi

# Run SwiftLint
echo -e "${BLUE}🔍 Running SwiftLint (${CONFIGURATION})...${NC}"

# Use --strict mode to treat warnings as errors in CI/CD
# In local builds, warnings are shown but don't fail the build
STRICT_MODE="${SWIFTLINT_STRICT:-0}"

if [ "${STRICT_MODE}" = "1" ]; then
    # Strict mode: warnings become errors
    if swiftlint lint --config .swiftlint.yml --strict; then
        echo -e "${GREEN}✅ SwiftLint passed (strict mode)${NC}"
    else
        echo -e "${RED}❌ SwiftLint failed (strict mode)${NC}"
        echo -e "${RED}   Fix violations before building${NC}"
        exit 1
    fi
else
    # Normal mode: show warnings but don't fail build
    if swiftlint lint --config .swiftlint.yml; then
        echo -e "${GREEN}✅ SwiftLint passed${NC}"
    else
        echo -e "${YELLOW}⚠️  SwiftLint found style violations (non-blocking)${NC}"
        echo -e "${YELLOW}   Review warnings above or run: swiftlint lint${NC}"
        # Don't exit with error in normal mode - allow build to continue
        exit 0
    fi
fi


