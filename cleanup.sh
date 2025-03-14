#!/bin/bash

# Cleanup script for PayslipMax-iOS project
# This script removes build artifacts and temporary files to reduce project size

echo "Starting cleanup of PayslipMax-iOS project..."

# Remove Swift build artifacts
if [ -d ".build" ]; then
    echo "Removing .build directory..."
    rm -rf .build
fi

if [ -d "PayslipStandaloneTests/.build" ]; then
    echo "Removing PayslipStandaloneTests/.build directory..."
    rm -rf PayslipStandaloneTests/.build
fi

# Remove Xcode derived data (if present)
if [ -d "DerivedData" ]; then
    echo "Removing DerivedData directory..."
    rm -rf DerivedData
fi

# Remove any .DS_Store files
echo "Removing .DS_Store files..."
find . -name ".DS_Store" -delete

# Remove any Xcode user-specific files
echo "Removing Xcode user-specific files..."
find . -name "xcuserdata" -type d -exec rm -rf {} \; 2>/dev/null || true

echo "Cleanup complete!"
echo "Run 'du -sh .' to see the new project size." 