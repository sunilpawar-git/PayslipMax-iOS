#!/bin/bash

# Create a temporary directory for the test bundle
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Compile the test files
echo "Compiling test files..."
swiftc -o "$TEMP_DIR/StandaloneTests" \
    -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -F $(xcrun --show-sdk-path --sdk macosx)/System/Library/Frameworks \
    -I $(xcrun --show-sdk-path --sdk macosx)/usr/lib \
    -L $(xcrun --show-sdk-path --sdk macosx)/usr/lib \
    -framework XCTest \
    StandaloneTests/BasicTests.swift \
    StandaloneTests/StandalonePayslipItem.swift \
    StandaloneTests/StandalonePayslipItemTests.swift

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful. Running tests..."
    "$TEMP_DIR/StandaloneTests"
else
    echo "Compilation failed."
fi

# Clean up
echo "Cleaning up..."
rm -rf "$TEMP_DIR" 