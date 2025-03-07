# Standalone Tests

This directory contains standalone tests that don't depend on the main app's code or frameworks. These tests are designed to be simple, fast, and independent.

## Purpose

The standalone tests serve several purposes:

1. **Framework Independence**: Test core business logic without dependencies on SwiftUI, SwiftData, or other frameworks.
2. **Compilation Speed**: Run faster than traditional XCTest-based tests.
3. **Isolation**: Avoid issues with circular dependencies or complex initialization.
4. **Simplicity**: Use simple assertions and straightforward test structure.

## Directory Structure

- `AuthTests/`: Tests for authentication-related functionality
- `PayslipTests/`: Tests for payslip processing and management
- `Utilities/`: Shared utilities for standalone tests

## Running Tests

Each test directory contains a `run_tests.sh` script that compiles and runs the tests. To run all standalone tests:

```bash
# Run from the project root
find StandaloneTests -name "run_tests.sh" -exec sh {} \;
```

Or run individual test suites:

```bash
# Run auth tests
cd StandaloneTests/AuthTests
./run_tests.sh
```

## Creating New Tests

To create a new standalone test:

1. Create a new directory under `StandaloneTests/`
2. Create a Swift file with your test code
3. Create a `run_tests.sh` script to compile and run the tests
4. Make the script executable with `chmod +x run_tests.sh`

## Best Practices

- Keep tests simple and focused
- Use descriptive function names
- Include both success and failure cases
- Use standard Swift assertions (`assert()`, `precondition()`)
- Avoid dependencies on external frameworks 