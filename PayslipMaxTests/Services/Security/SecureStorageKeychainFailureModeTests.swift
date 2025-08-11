import XCTest
import Security
@testable import PayslipMax

final class SecureStorageKeychainFailureModeTests: XCTestCase {
    override func tearDown() {
        // Reset simulation hooks
        #if DEBUG
        KeychainSecureStorage.simulateAddFailureStatus = nil
        KeychainSecureStorage.simulateCopyFailureStatus = nil
        KeychainSecureStorage.simulateDeleteFailureStatus = nil
        #endif
        super.tearDown()
    }

    func testSaveData_WhenKeychainReturnsInteractionNotAllowed_ThrowsError() {
        #if DEBUG
        let storage = KeychainSecureStorage(serviceName: "com.payslipmax.test.securestorage")
        KeychainSecureStorage.simulateAddFailureStatus = errSecInteractionNotAllowed

        XCTAssertThrowsError(try storage.saveData(key: "k", data: Data([1,2,3]))) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "KeychainErrorDomain")
            XCTAssertEqual(nsError.code, Int(errSecInteractionNotAllowed))
        }
        #else
        throw XCTSkip("Failure simulation hooks only available in DEBUG builds")
        #endif
    }

    func testGetData_WhenKeychainItemNotFound_ReturnsNil() throws {
        let storage = KeychainSecureStorage(serviceName: "com.payslipmax.test.securestorage")
        // Ensure no value exists
        _ = try? storage.deleteItem(key: "missing")
        let result = try storage.getData(key: "missing")
        XCTAssertNil(result)
    }

    func testGetData_WhenKeychainReturnsAuthFailed_ThrowsError() {
        #if DEBUG
        let storage = KeychainSecureStorage(serviceName: "com.payslipmax.test.securestorage")
        KeychainSecureStorage.simulateCopyFailureStatus = errSecAuthFailed
        XCTAssertThrowsError(try storage.getData(key: "k")) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, Int(errSecAuthFailed))
        }
        #else
        throw XCTSkip("Failure simulation hooks only available in DEBUG builds")
        #endif
    }

    func testDeleteItem_WhenKeychainReturnsDecodeError_ThrowsError() {
        #if DEBUG
        let storage = KeychainSecureStorage(serviceName: "com.payslipmax.test.securestorage")
        KeychainSecureStorage.simulateDeleteFailureStatus = errSecDecode
        XCTAssertThrowsError(try storage.deleteItem(key: "k")) { error in
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, Int(errSecDecode))
        }
        #else
        throw XCTSkip("Failure simulation hooks only available in DEBUG builds")
        #endif
    }

    func testSaveAndGetString_SuccessPath() throws {
        let storage = KeychainSecureStorage(serviceName: "com.payslipmax.test.securestorage")
        try storage.saveString(key: "user_token", value: "abc123")
        let value = try storage.getString(key: "user_token")
        XCTAssertEqual(value, "abc123")
        try storage.deleteItem(key: "user_token")
    }
}


