import XCTest
@testable import Payslip_Max
@testable import PayslipMaxTests

// Simple test runner
@main
struct TestRunner {
    static func main() async throws {
        let testClass = EncryptionEdgeCaseTests()
        
        // Setup
        try await testClass.setUp()
        
        print("Running tests...")
        
        // Run the tests
        try testClass.testEncryptDecryptEmptyString()
        try testClass.testEncryptDecryptVeryLargeString()
        try testClass.testEncryptDecryptSpecialCharacters()
        try testClass.testEncryptDecryptEmojisAndUnicode()
        testClass.testDecryptInvalidBase64String()
        try testClass.testEncryptInvalidUTF8Data()
        try testClass.testRepeatedEncryptionOperations()
        await testClass.testConcurrentEncryptionOperations()
        testClass.testEncryptionServiceCustomError()
        
        // Teardown
        try await testClass.tearDown()
        
        print("All tests completed successfully!")
    }
} 