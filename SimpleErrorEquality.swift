import Foundation

// Recreate the error types from the app
enum SensitiveDataError: Error, Equatable {
    case invalidData
    case decryptionFailed
    case encryptionFailed
    case invalidBase64String
}

// Function to test the errors
func testErrorEquality() {
    // Create two errors of the same type
    let error1 = SensitiveDataError.invalidBase64String
    let error2 = SensitiveDataError.invalidBase64String
    
    // Check if they're equal (they should be)
    let areEqual = (error1 == error2)
    assert(areEqual, "Errors of the same type should be equal")
    print("✅ Equal errors test passed!")
    
    // Create two errors of different types
    let error3 = SensitiveDataError.invalidBase64String
    let error4 = SensitiveDataError.decryptionFailed
    
    // Check if they're equal (they should not be)
    let areDifferent = (error3 != error4)
    assert(areDifferent, "Errors of different types should not be equal")
    print("✅ Different errors test passed!")
}

// Run the test
print("Running error equality test...")
testErrorEquality()
print("All tests completed successfully!") 