import XCTest
import Combine
@testable import PayslipMax

/// Tests for the ProgressReporterWrapper class
class ProgressReporterWrapperTests: XCTestCase {
    
    var wrapper: ProgressReporterWrapper!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        wrapper = ProgressReporterWrapper(name: "TestReporter")
    }
    
    override func tearDown() {
        cancellables.removeAll()
        wrapper = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    /// Test basic progress updating
    func testProgressUpdating() {
        // Set up an expectation for progress updates
        let expectation = XCTestExpectation(description: "Progress update received")
        expectation.expectedFulfillmentCount = 3 // We'll make 3 updates
        
        var progressUpdates: [(Double, String)] = []
        
        // Subscribe to progress updates
        wrapper.progressPublisher
            .sink { update in
                progressUpdates.append((update.progress, update.message))
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Make some progress updates
        wrapper.update(progress: 0.25, message: "Quarter done")
        wrapper.update(progress: 0.5, message: "Half done")
        wrapper.update(progress: 1.0, message: "Completed")
        
        // Wait for the updates
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the updates
        XCTAssertEqual(progressUpdates.count, 3)
        XCTAssertEqual(progressUpdates[0].0, 0.25)
        XCTAssertEqual(progressUpdates[0].1, "Quarter done")
        XCTAssertEqual(progressUpdates[1].0, 0.5)
        XCTAssertEqual(progressUpdates[1].1, "Half done")
        XCTAssertEqual(progressUpdates[2].0, 1.0)
        XCTAssertEqual(progressUpdates[2].1, "Completed")
        
        // Check current progress
        XCTAssertEqual(wrapper.progress, 1.0)
        XCTAssertEqual(wrapper.statusMessage, "Completed")
    }
    
    /// Test progress history
    func testProgressHistory() {
        // Make some progress updates
        wrapper.update(progress: 0.25, message: "Quarter done")
        wrapper.update(progress: 0.5, message: "Half done")
        wrapper.update(progress: 0.75, message: "Three quarters")
        wrapper.update(progress: 1.0, message: "Completed")
        
        // Get history
        let history = wrapper.getProgressHistory()
        
        // Verify history
        XCTAssertEqual(history.count, 4)
        XCTAssertEqual(history[0].progress, 0.25)
        XCTAssertEqual(history[0].message, "Quarter done")
        XCTAssertEqual(history[3].progress, 1.0)
        XCTAssertEqual(history[3].message, "Completed")
    }
    
    /// Test progress analytics
    func testProgressAnalytics() {
        // Make some progress updates with delays to create a realistic timeline
        wrapper.update(progress: 0.25, message: "Quarter done")
        Thread.sleep(forTimeInterval: 0.1)
        wrapper.update(progress: 0.5, message: "Half done")
        Thread.sleep(forTimeInterval: 0.1)
        wrapper.update(progress: 0.75, message: "Three quarters")
        Thread.sleep(forTimeInterval: 0.1)
        wrapper.update(progress: 1.0, message: "Completed")
        
        // Get analytics
        let analytics = wrapper.getProgressAnalytics()
        
        // Verify analytics
        XCTAssertEqual(analytics["name"] as? String, "TestReporter")
        XCTAssertEqual(analytics["progress"] as? Double, 1.0)
        XCTAssertEqual(analytics["updateCount"] as? Int, 4)
        XCTAssertEqual(analytics["isComplete"] as? Bool, true)
        
        // Verify timing analytics (approximate due to timing variations)
        XCTAssertNotNil(analytics["totalDuration"])
        XCTAssertNotNil(analytics["progressRate"])
    }
    
    /// Test reset functionality
    func testReset() {
        // Set up an expectation for reset
        let expectation = XCTestExpectation(description: "Reset notification received")
        
        // Subscribe to progress updates
        wrapper.progressPublisher
            .sink { update in
                if update.message == "Reset" && update.progress == 0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Make some progress updates
        wrapper.update(progress: 0.5, message: "Half done")
        
        // Reset
        wrapper.reset()
        
        // Wait for reset notification
        wait(for: [expectation], timeout: 1.0)
        
        // Verify reset
        XCTAssertEqual(wrapper.progress, 0.0)
        XCTAssertEqual(wrapper.getProgressHistory().count, 0)
    }
    
    /// Test error reporting
    func testErrorReporting() {
        // Set up an expectation for error report
        let expectation = XCTestExpectation(description: "Error report received")
        
        // Subscribe to progress updates
        wrapper.progressPublisher
            .sink { update in
                if update.message.starts(with: "Error:") {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Report an error
        let error = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        wrapper.reportError(error, progress: 0.7)
        
        // Wait for error report
        wait(for: [expectation], timeout: 1.0)
        
        // Verify error reporting
        XCTAssertEqual(wrapper.progress, 0.7)
        XCTAssertTrue(wrapper.statusMessage.contains("Test error"))
    }
    
    /// Test convenience methods
    func testConvenienceMethods() {
        // Test updateWithItemCount
        wrapper.updateWithItemCount(itemsProcessed: 3, totalItems: 10)
        XCTAssertEqual(wrapper.progress, 0.3)
        XCTAssertTrue(wrapper.statusMessage.contains("3 of 10"))
        
        // Test updateWithStages
        wrapper.updateWithStages(currentStage: 2, totalStages: 4, stageProgress: 0.5)
        XCTAssertEqual(wrapper.progress, 0.375) // (1/4 + 1/4*0.5) = 0.25 + 0.125 = 0.375
        XCTAssertTrue(wrapper.statusMessage.contains("Stage 2 of 4"))
        
        // Test complete
        wrapper.complete(with: "All done")
        XCTAssertEqual(wrapper.progress, 1.0)
        XCTAssertEqual(wrapper.statusMessage, "All done")
    }
} 