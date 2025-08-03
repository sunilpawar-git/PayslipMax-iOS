
import Foundation

class MockDeviceRegistrationService: DeviceRegistrationServiceProtocol {
    func registerDevice() async throws -> String {
        print("MockDeviceRegistrationService: registerDevice called. Returning a mock token.")
        return "mock_device_token_12345"
    }
    
    func getDeviceToken() async throws -> String {
        print("MockDeviceRegistrationService: getDeviceToken called. Returning a mock token.")
        return "mock_device_token_12345"
    }
}
