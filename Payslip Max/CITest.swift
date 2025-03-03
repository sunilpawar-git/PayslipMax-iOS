import Foundation

/// A simple test class to verify CI workflows
final class CITest {
    /// Test function to verify code coverage
    func testFunction() -> String {
        return "CI Test Successful"
    }
    
    /// Test function with parameters to verify SwiftLint
    func processValue(_ value: Int) -> Int {
        guard value > 0 else { return 0 }
        return value * 2
    }
}
