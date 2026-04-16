#!/bin/bash

# Script to add SwiftLint build phase to Xcode project
# This integrates SwiftLint into the build process

set -e

PROJECT_FILE="PayslipMax.xcodeproj/project.pbxproj"
SCRIPT_PATH="Scripts/swiftlint-build-phase.sh"

# Generate a unique 24-character hex ID (Xcode format)
generate_id() {
    openssl rand -hex 12 | tr '[:lower:]' '[:upper:]'
}

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: $PROJECT_FILE not found"
    exit 1
fi

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: $SCRIPT_PATH not found"
    exit 1
fi

# Generate IDs
BUILD_PHASE_ID=$(generate_id)
echo "Generated Build Phase ID: $BUILD_PHASE_ID"

# Check if SwiftLint build phase already exists
if grep -q "SwiftLint" "$PROJECT_FILE"; then
    echo "⚠️  SwiftLint build phase may already exist. Checking..."
    if grep -q "PBXShellScriptBuildPhase.*SwiftLint" "$PROJECT_FILE"; then
        echo "✅ SwiftLint build phase already exists in project"
        exit 0
    fi
fi

# Create backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
echo "✅ Created backup of project file"

# Add build phase entry before "/* End PBXShellScriptBuildPhase section */" or at end of file
# First, find where to insert it (after Resources phase, before closing brace)

# Find the Resources build phase for PayslipMax target
RESOURCES_PHASE_LINE=$(grep -n "10171F662D3FFE010053BAB6 /\* Resources \*/" "$PROJECT_FILE" | head -1 | cut -d: -f1)

if [ -z "$RESOURCES_PHASE_LINE" ]; then
    echo "❌ Error: Could not find Resources build phase"
    exit 1
fi

# Find the end of Resources section
END_RESOURCES_LINE=$(awk "NR > $RESOURCES_PHASE_LINE && /^[[:space:]]*\};[[:space:]]*$/ {print NR; exit}" "$PROJECT_FILE")

if [ -z "$END_RESOURCES_LINE" ]; then
    echo "❌ Error: Could not find end of Resources section"
    exit 1
fi

# Insert build phase definition after Resources section
INSERT_LINE=$((END_RESOURCES_LINE + 1))

# Build phase definition
BUILD_PHASE_DEF="\t\t${BUILD_PHASE_ID} /* SwiftLint */ = {\n\t\t\tisa = PBXShellScriptBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);\n\t\t\tinputFileListPaths = (\n\t\t\t);\n\t\t\tinputPaths = (\n\t\t\t);\n\t\t\tname = SwiftLint;\n\t\t\toutputFileListPaths = (\n\t\t\t);\n\t\t\toutputPaths = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t\tshellPath = /bin/sh;\n\t\t\tshellScript = \"\\\"\\\$SRCROOT/${SCRIPT_PATH}\\\"\";\n\t\t\tshowEnvVarsInLog = 0;\n\t\t};"

# Insert the build phase
awk -v line="$INSERT_LINE" -v def="$BUILD_PHASE_DEF" '
NR == line {
    print def
    print
    next
}
{ print }
' "$PROJECT_FILE" > "${PROJECT_FILE}.tmp" && mv "${PROJECT_FILE}.tmp" "$PROJECT_FILE"

# Add to buildPhases array for PayslipMax target (after Resources)
BUILD_PHASES_LINE=$(grep -n "buildPhases = (" "$PROJECT_FILE" | grep -A 5 "10171F672D3FFE010053BAB6 /\* PayslipMax \*/" | grep "buildPhases = (" | head -1 | cut -d: -f1)

if [ -z "$BUILD_PHASES_LINE" ]; then
    echo "❌ Error: Could not find buildPhases array"
    exit 1
fi

# Find the Resources entry in buildPhases
RESOURCES_IN_PHASES=$(awk "NR > $BUILD_PHASES_LINE && /10171F662D3FFE010053BAB6.*Resources/ {print NR}" "$PROJECT_FILE" | head -1)

if [ -z "$RESOURCES_IN_PHASES" ]; then
    echo "❌ Error: Could not find Resources in buildPhases"
    exit 1
fi

# Insert SwiftLint phase reference after Resources
INSERT_PHASE_LINE=$((RESOURCES_IN_PHASES + 1))

awk -v line="$INSERT_PHASE_LINE" -v id="$BUILD_PHASE_ID" '
NR == line {
    print
    print "\t\t\t\t" id " /* SwiftLint */,"
    next
}
{ print }
' "$PROJECT_FILE" > "${PROJECT_FILE}.tmp" && mv "${PROJECT_FILE}.tmp" "$PROJECT_FILE"

echo "✅ SwiftLint build phase added successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Open PayslipMax.xcodeproj in Xcode"
echo "   2. Select the PayslipMax target"
echo "   3. Go to Build Phases tab"
echo "   4. Verify 'SwiftLint' phase appears after 'Resources'"
echo "   5. Build the project (Cmd+B) to test"
echo ""
echo "💡 The SwiftLint phase will run during Debug builds by default"
echo "   Set SWIFTLINT_ALWAYS_RUN=1 to run in all configurations"


