import Foundation

// Simple mock classes to simulate the encryption functionality
class MockEncryptionService {
    var encryptionCount = 0
    
    func encryptString(_ input: String, fieldName: String) async -> String {
        encryptionCount += 1
        return "ENCRYPTED_\(input)_\(fieldName)"
    }
}

class PayslipSensitiveDataHandler {
    private let encryptionService: MockEncryptionService
    
    init(encryptionService: MockEncryptionService) {
        self.encryptionService = encryptionService
    }
    
    func testConcurrentEncryptionOperations() async {
        let testString = "Test String"
        let fieldNames = ["field1", "field2", "field3", "field4", "field5", 
                         "field6", "field7", "field8", "field9", "field10"]
        
        await withTaskGroup(of: String.self) { group in
            for fieldName in fieldNames {
                group.addTask {
                    // This is what we fixed - adding await here
                    let encrypted = await self.encryptionService.encryptString(testString, fieldName: fieldName)
                    return encrypted
                }
            }
            
            // Wait for all tasks to complete
            for await _ in group {
                // Just collect the results
            }
        }
        
        // The encryptionCount should match the number of field names
        assert(encryptionService.encryptionCount == fieldNames.count, 
               "Expected \(fieldNames.count) encryptions, but got \(encryptionService.encryptionCount)")
        print("✅ Test passed! Encryption count: \(encryptionService.encryptionCount)")
    }
}

// Run the test directly with top-level code
print("Running concurrent encryption test...")
let mockEncryptionService = MockEncryptionService()
let handler = PayslipSensitiveDataHandler(encryptionService: mockEncryptionService)

// Create and run a task for the async function
Task {
    await handler.testConcurrentEncryptionOperations()
    print("All tests completed successfully!")
}

// Keep the program running to allow the task to complete
RunLoop.main.run(until: Date(timeIntervalSinceNow: 2)) 