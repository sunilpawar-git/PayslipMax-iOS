#!/bin/bash

# Create a temporary directory for our test
TEMP_DIR=$(mktemp -d)
echo "Creating temporary test directory: $TEMP_DIR"

# Create a simple Swift test file
cat > "$TEMP_DIR/SimpleTest.swift" << 'EOF'
import XCTest

class SimpleTest: XCTestCase {
    func testSimpleBoolean() {
        // A very basic test that should always pass
        let testValue = true
        XCTAssertTrue(testValue, "Boolean test should pass")
    }
    
    func testStringComparison() {
        let testString = "Hello World"
        XCTAssertEqual(testString, "Hello World", "String comparison should match")
    }
    
    func testMathOperation() {
        let result = 2 + 2
        XCTAssertEqual(result, 4, "Basic math should work correctly")
    }
}
EOF

# Compile and run the test
echo "Compiling and running test..."
cd "$TEMP_DIR"
xcrun swiftc -sdk $(xcrun --show-sdk-path --sdk iphonesimulator) -target arm64-apple-ios18.0-simulator -F $(xcrun --show-sdk-path --sdk iphonesimulator)/System/Library/Frameworks -I $(xcrun --show-sdk-path --sdk iphonesimulator)/System/Library/Frameworks/XCTest.framework/Headers -L $(xcrun --show-sdk-path --sdk iphonesimulator)/System/Library/Frameworks/XCTest.framework -lXCTest -o SimpleTest SimpleTest.swift && ./SimpleTest

# Check the result
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo "Test passed!"
else
    echo "Test failed with exit code $EXIT_CODE"
fi

# Clean up
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

exit $EXIT_CODE 