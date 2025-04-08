#!/bin/bash

# Compile and run the standalone tests
swiftc -o AuthViewModelTests \
    -parse-as-library \
    -enable-testing \
    -sdk $(xcrun --show-sdk-path --sdk iphonesimulator) \
    -target arm64-apple-ios17.0-simulator \
    -I $(xcrun --find xctest) \
    -F $(xcrun --find xctest | xargs dirname)/../Frameworks \
    -framework XCTest \
    AuthViewModelTests.swift

# Run the tests
./AuthViewModelTests 