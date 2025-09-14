import Foundation

/// Extension to detect test environment for logging optimization
extension ProcessInfo {
    /// Detects if the current process is running in a test environment
    static var isRunningInTestEnvironment: Bool {
        return NSClassFromString("XCTestCase") != nil ||
               processInfo.arguments.contains("UI_TESTING") ||
               processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
