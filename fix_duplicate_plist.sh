#!/bin/bash

# Script to fix duplicate GoogleService-Info.plist in Xcode project
# This removes duplicate references from the Copy Bundle Resources phase

PROJECT_FILE="PayslipMax.xcodeproj/project.pbxproj"
BACKUP_FILE="PayslipMax.xcodeproj/project.pbxproj.backup"

echo "🔧 Fixing duplicate GoogleService-Info.plist references..."

# Create backup
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Find the GoogleService-Info.plist file reference ID
PLIST_ID=$(grep "GoogleService-Info.plist.*PBXFileReference" "$PROJECT_FILE" | grep -o "[A-Z0-9]\{24\}" | head -1)

if [ -z "$PLIST_ID" ]; then
    echo "❌ Could not find GoogleService-Info.plist reference"
    exit 1
fi

echo "📝 Found plist reference ID: $PLIST_ID"

# Count how many times it appears in Resources build phase
COUNT=$(grep -c "$PLIST_ID.*in Resources" "$PROJECT_FILE")
echo "📊 Found $COUNT references in Copy Bundle Resources phase"

if [ "$COUNT" -gt 1 ]; then
    echo "🔨 Removing duplicate references..."

    # Keep only the first occurrence, remove the rest
    awk -v id="$PLIST_ID" '
        /in Resources/ && $0 ~ id {
            if (!seen[id]++) {
                print
            }
            next
        }
        {print}
    ' "$PROJECT_FILE" > "$PROJECT_FILE.tmp"

    mv "$PROJECT_FILE.tmp" "$PROJECT_FILE"
    echo "✅ Removed duplicate references"
else
    echo "ℹ️  No duplicates found in Resources phase"
fi

echo "🎉 Done! Try building again."
