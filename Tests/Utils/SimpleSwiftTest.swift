// Simple Swift test that doesn't require XCTest
func testSimpleBoolean() -> Bool {
    let testValue = true
    return testValue == true
}

func testStringComparison() -> Bool {
    let testString = "Hello World"
    return testString == "Hello World"
}

func testMathOperation() -> Bool {
    let result = 2 + 2
    return result == 4
}

// Run the tests and print results
func runTests() {
    var allTestsPassed = true
    
    // Test 1
    if testSimpleBoolean() {
        print("✅ testSimpleBoolean passed")
    } else {
        print("❌ testSimpleBoolean failed")
        allTestsPassed = false
    }
    
    // Test 2
    if testStringComparison() {
        print("✅ testStringComparison passed")
    } else {
        print("❌ testStringComparison failed")
        allTestsPassed = false
    }
    
    // Test 3
    if testMathOperation() {
        print("✅ testMathOperation passed")
    } else {
        print("❌ testMathOperation failed")
        allTestsPassed = false
    }
    
    // Summary
    if allTestsPassed {
        print("\n🎉 All tests passed!")
    } else {
        print("\n⚠️ Some tests failed!")
    }
}

// Execute tests
runTests() 