import XCTest

/// Non-blocking wait helper for UI tests to replace Thread.sleep/sleep/usleep.
@MainActor
func wait(seconds: TimeInterval, file: StaticString = #filePath, line: UInt = #line) {
    let expectation = XCTestExpectation(description: "wait \(seconds)s")
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        expectation.fulfill()
    }
    let result = XCTWaiter.wait(for: [expectation], timeout: seconds + 1.0)
    XCTAssertEqual(result, .completed, "Wait timed out", file: file, line: line)
}

