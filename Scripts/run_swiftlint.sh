#!/bin/bash

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "SwiftLint is not installed. Installing..."
    brew install swiftlint
fi

# Run SwiftLint
echo "Running SwiftLint..."
swiftlint lint --config .swiftlint.yml

# Check if there are any errors
if [ $? -eq 0 ]; then
    echo "SwiftLint completed successfully!"
else
    echo "SwiftLint found issues. Please fix them before committing."
    exit 1
fi 