import XCTest
@testable import PayslipMax

@MainActor
class SecurityInitializationTests: XCTestCase {

    var sut: SecurityServiceImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = SecurityServiceImpl()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInitialize_SetsInitializedFlag() async throws {
        // Given
        XCTAssertFalse(sut.isInitialized)

        // When
        try await sut.initialize()

        // Then
        XCTAssertTrue(sut.isInitialized)
    }

    func testInitialize_CanBeCalledMultipleTimes() async throws {
        // Given
        try await sut.initialize()
        XCTAssertTrue(sut.isInitialized)

        // When
        try await sut.initialize()

        // Then
        XCTAssertTrue(sut.isInitialized)
    }
}
