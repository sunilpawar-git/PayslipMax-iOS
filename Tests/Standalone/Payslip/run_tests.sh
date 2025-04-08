#!/bin/bash

# Compile and run the PayslipItem tests
echo "Compiling PayslipItem tests..."

# Create a temporary directory for the compiled files
mkdir -p .build

# Compile the PayslipItemProtocol
swiftc -emit-module -emit-object \
    -o .build/PayslipItemProtocol.o \
    -module-name PayslipTests \
    ../../Payslip\ Max/Models/PayslipItemProtocol.swift

# Compile the PayslipSensitiveDataHandler
swiftc -emit-object \
    -o .build/PayslipSensitiveDataHandler.o \
    -I .build \
    ../../Payslip\ Max/Models/PayslipSensitiveDataHandler.swift

# Compile the tests
swiftc -o PayslipItemTests \
    -I .build \
    -module-name PayslipTests \
    PayslipItemTests.swift \
    .build/PayslipItemProtocol.o \
    .build/PayslipSensitiveDataHandler.o

# Run the tests
echo "Running PayslipItem tests..."
./PayslipItemTests

# Check the exit code
if [ $? -eq 0 ]; then
    echo "PayslipItem tests passed!"
    # Clean up
    rm -rf .build
    rm PayslipItemTests
    exit 0
else
    echo "PayslipItem tests failed!"
    # Clean up
    rm -rf .build
    rm PayslipItemTests
    exit 1
fi 