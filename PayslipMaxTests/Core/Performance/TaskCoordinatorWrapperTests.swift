import XCTest
import Combine
@testable import PayslipMax

/// Tests for the TaskCoordinatorWrapper class
class TaskCoordinatorWrapperTests: XCTestCase {
    
    var wrapper: TaskCoordinatorWrapper!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        wrapper = TaskCoordinatorWrapper()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        wrapper = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Create a simple test task
    private func createTestTask(name: String = "Test Task", 
                              progress: Double = 1.0, 
                              duration: TimeInterval = 0.1) async throws -> String {
        
        var eventReceived = false
        let expectation = XCTestExpectation(description: "Task completed")
        
        // Subscribe to events
        wrapper.publisher
            .sink { event in
                switch event.baseEvent {
                case .completed:
                    eventReceived = true
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Execute a simple task
        let taskResult = try await wrapper.executeTask(name: name) { progressHandler in
            // Simulate work with progress
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            progressHandler(progress, "Task completed")
            return "Task result: \(name)"
        }
        
        // Wait for event
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(eventReceived, "Should receive task completed event")
        return taskResult
    }
    
    // MARK: - Tests
    
    /// Test basic task execution
    func testExecuteTask() async throws {
        let result = try await createTestTask()
        XCTAssertEqual(result, "Task result: Test Task")
        
        // Get task registry and check
        let registry = wrapper.getTaskRegistrySnapshot()
        XCTAssertFalse(registry.isEmpty, "Task registry should not be empty")
    }
    
    /// Test task with error
    func testTaskWithError() async {
        let expectation = XCTestExpectation(description: "Task failed")
        
        var receivedError: Error?
        
        // Subscribe to events
        wrapper.publisher
            .sink { event in
                switch event.baseEvent {
                case .failed(_, let error):
                    receivedError = error
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Execute a task that will fail
        do {
            _ = try await wrapper.executeTask(name: "Failing Task") { progressHandler in
                progressHandler(0.5, "About to fail")
                throw NSError(domain: "TaskTest", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
            }
            XCTFail("Task should have thrown an error")
        } catch {
            // Expected error
        }
        
        // Wait for event
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(receivedError, "Should receive error event")
        
        if let error = receivedError as NSError? {
            XCTAssertEqual(error.domain, "TaskTest")
            XCTAssertEqual(error.code, 123)
        }
    }
    
    /// Test task cancellation
    func testTaskCancellation() async throws {
        let expectation = XCTestExpectation(description: "Task cancelled")
        
        var taskCancelled = false
        
        // Subscribe to events
        wrapper.publisher
            .sink { event in
                switch event.baseEvent {
                case .cancelled:
                    taskCancelled = true
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Create a long-running task
        let taskId = try await wrapper.coordinator.createTask(name: "Task to cancel") { _ in
            // Simulate long operation
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            return "Should not get here"
        }
        
        // Start the task in a separate task so we can cancel it
        Task {
            do {
                _ = try await wrapper.coordinator.startTask(id: taskId) as String
                XCTFail("Task should have been cancelled")
            } catch {
                // Expected error due to cancellation
            }
        }
        
        // Give it a moment to start
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Cancel the task
        await wrapper.cancelAllTasks()
        
        // Wait for cancellation event
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertTrue(taskCancelled, "Task should have been cancelled")
    }
    
    /// Test multiple tasks
    func testMultipleTasks() async throws {
        let count = 5
        let expectation = XCTestExpectation(description: "Multiple tasks completed")
        expectation.expectedFulfillmentCount = count
        
        // Subscribe to events
        wrapper.publisher
            .sink { event in
                switch event.baseEvent {
                case .completed:
                    expectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Execute multiple tasks concurrently
        async let task1: String = createTestTask(name: "Task 1", progress: 1.0, duration: 0.1)
        async let task2: String = createTestTask(name: "Task 2", progress: 1.0, duration: 0.2)
        async let task3: String = createTestTask(name: "Task 3", progress: 1.0, duration: 0.3)
        async let task4: String = createTestTask(name: "Task 4", progress: 1.0, duration: 0.4)
        async let task5: String = createTestTask(name: "Task 5", progress: 1.0, duration: 0.5)
        
        let results = try await [task1, task2, task3, task4, task5]
        
        // Wait for all events
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertEqual(results.count, count)
        
        // Check registry
        let registry = wrapper.getTaskRegistrySnapshot()
        XCTAssertGreaterThanOrEqual(registry.count, count)
    }
    
    /// Test active task counting
    func testActiveTasks() async throws {
        // First create and complete a task
        _ = try await createTestTask()
        
        // Then create some tasks that will remain active
        let runningTaskCount = 3
        
        for i in 1...runningTaskCount {
            let taskId = try await wrapper.coordinator.createTask(name: "Running Task \(i)") { _ in
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                return "Should not get here"
            }
            
            // Start the task in a background task
            Task {
                do {
                    _ = try await wrapper.coordinator.startTask(id: taskId) as String
                } catch {
                    // Expected error if cancelled
                }
            }
        }
        
        // Give tasks time to start
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Check active tasks
        let taskCounts = await wrapper.getActiveTasks()
        
        // We should have at least the running tasks
        XCTAssertGreaterThanOrEqual(taskCounts[.running, default: 0], runningTaskCount)
        
        // Clean up
        await wrapper.cancelAllTasks()
    }
    
    /// Test cleanup
    func testCleanup() async throws {
        // Create and complete several tasks
        for i in 1...5 {
            _ = try await createTestTask(name: "Cleanup Test \(i)")
        }
        
        // Verify tasks are in registry
        var registry = wrapper.getTaskRegistrySnapshot()
        XCTAssertGreaterThanOrEqual(registry.count, 5)
        
        // Clean up tasks
        await wrapper.cleanupTasks()
        
        // Verify cleanup
        registry = wrapper.getTaskRegistrySnapshot()
        
        // Registry should still have entries because our wrapper keeps them longer than 
        // the coordinator for diagnostics
        XCTAssertGreaterThanOrEqual(registry.count, 5)
    }
} 