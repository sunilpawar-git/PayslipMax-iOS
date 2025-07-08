import XCTest
import Combine
import Foundation
@testable import PayslipMax

/// Integration tests for the background task system components
class TaskSystemIntegrationTests: XCTestCase {
    
    var taskCoordinator: TaskCoordinatorWrapper!
    var taskMonitor: TaskMonitor!
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        taskCoordinator = TaskCoordinatorWrapper()
        taskMonitor = TaskMonitor(taskCoordinatorWrapper: taskCoordinator)
    }
    
    override func tearDown() {
        Task { @MainActor in
            taskMonitor.stopMonitoring()
        }
        taskMonitor = nil
        taskCoordinator = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    /// Test that all components work together properly for a simple task
    func testBasicTaskIntegration() async throws {
        // Set up expectations
        let taskCompletedExpectation = XCTestExpectation(description: "Task completed")
        let progressReporterUpdatedExpectation = XCTestExpectation(description: "Progress reporter updated")
        let monitorReceivedEventExpectation = XCTestExpectation(description: "Monitor received event")
        
        // Create a progress reporter
        let progressReporter = ProgressReporterWrapper(name: "IntegrationTest")
        
        // Subscribe to progress updates
        progressReporter.progressPublisher
            .sink { update in
                if update.progress > 0 {
                    progressReporterUpdatedExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to task monitor events
        taskMonitor.publisher
            .sink { event in
                switch event {
                case .taskCompleted:
                    monitorReceivedEventExpectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Execute a task with the wrapper
        Task {
            do {
                let result: String = try await taskCoordinator.executeTask(
                    name: "Integration Test Task",
                    category: .general,
                    priority: .medium
                ) { progressCallback in
                    // Update our progress reporter
                    progressReporter.update(progress: 0.5, message: "Halfway done")
                    
                    // Forward progress to the task system
                    progressCallback(0.5, "Halfway done")
                    
                    // Simulate work
                    try await Task.sleep(nanoseconds: 100_000_000)
                    
                    // Update progress again
                    progressReporter.update(progress: 1.0, message: "Complete")
                    progressCallback(1.0, "Complete")
                    
                    return "Success"
                }
                
                XCTAssertEqual(result, "Success")
                taskCompletedExpectation.fulfill()
            } catch {
                XCTFail("Task should not fail: \(error)")
            }
        }
        
        // Wait for all expectations
        await fulfillment(of: [
            taskCompletedExpectation,
            progressReporterUpdatedExpectation,
            monitorReceivedEventExpectation
        ], timeout: 5.0)
        
        // Verify task is recorded in monitor
        let history = taskMonitor.getTaskHistorySnapshot()
        XCTAssertFalse(history.isEmpty, "Task history should not be empty")
        
        // Verify metrics are available
        let metrics = taskMonitor.getTaskPerformanceMetrics()
        XCTAssertEqual(metrics["completedTasks"] as? Int, 1, "Should have one completed task")
    }
    
    /// Test handling of task errors across all components
    func testErrorHandlingIntegration() async {
        // Set up expectations
        let taskFailedExpectation = XCTestExpectation(description: "Task failed")
        let errorReportedExpectation = XCTestExpectation(description: "Error reported")
        let monitorReceivedErrorExpectation = XCTestExpectation(description: "Monitor received error")
        
        // Create a progress reporter
        let progressReporter = ProgressReporterWrapper(name: "ErrorTest")
        
        // Subscribe to progress updates for error reporting
        progressReporter.progressPublisher
            .sink { update in
                if update.message.starts(with: "Error:") {
                    errorReportedExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to task monitor events
        taskMonitor.publisher
            .sink { event in
                switch event {
                case .taskFailed:
                    monitorReceivedErrorExpectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Execute a failing task
        do {
            _ = try await taskCoordinator.executeTask(
                name: "Failing Integration Test",
                category: .general,
                priority: .medium
            ) { progressCallback in
                // Update progress
                progressCallback(0.5, "About to fail")
                progressReporter.update(progress: 0.5, "About to fail")
                
                // Simulate work
                try await Task.sleep(nanoseconds: 100_000_000)
                
                // Throw an error
                let error = NSError(domain: "IntegrationTest", code: 100, userInfo: [
                    NSLocalizedDescriptionKey: "Test failure"
                ])
                
                // Report error in progress reporter
                progressReporter.reportError(error)
                
                throw error
            }
            
            XCTFail("Task should have failed")
        } catch {
            // Expected
            taskFailedExpectation.fulfill()
        }
        
        // Wait for all expectations
        await fulfillment(of: [
            taskFailedExpectation,
            errorReportedExpectation,
            monitorReceivedErrorExpectation
        ], timeout: 5.0)
        
        // Verify task failure is recorded in monitor
        let metrics = taskMonitor.getTaskPerformanceMetrics()
        XCTAssertEqual(metrics["failedTasks"] as? Int, 1, "Should have one failed task")
    }
    
    /// Test handling of multiple concurrent tasks
    func testMultipleTasksIntegration() async throws {
        // Set up expectations
        let allTasksCompletedExpectation = XCTestExpectation(description: "All tasks completed")
        allTasksCompletedExpectation.expectedFulfillmentCount = 3
        
        // Create an aggregate progress reporter
        let aggregateReporter = ProgressReporterWrapper(name: "MultiTaskTest")
        
        // Track task completion using a counter
        let taskCountLock = NSLock()
        var completedTasks = 0
        
        // Function to create and run a single task
        func runTask(id: Int) async throws {
            let name = "Task \(id)"
            let taskReporter = ProgressReporterWrapper(name: name)
            
            // Execute task
            try await taskCoordinator.executeTask(
                name: name,
                category: .general
            ) { progressCallback in
                // Simulate multiple steps
                for step in 1...5 {
                    let progress = Double(step) / 5.0
                    let message = "Step \(step) of 5"
                    
                    // Update both reporters
                    taskReporter.update(progress: progress, message: message)
                    progressCallback(progress, message)
                    
                    // Simulate work
                    try await Task.sleep(nanoseconds: UInt64(50_000_000 * id))
                }
                
                return name
            }
            
            // Mark task as completed
            taskCountLock.lock()
            completedTasks += 1
            
            // Update aggregate progress
            aggregateReporter.updateWithItemCount(
                itemsProcessed: completedTasks,
                totalItems: 3,
                message: "Completed \(completedTasks) of 3 tasks"
            )
            
            taskCountLock.unlock()
            
            allTasksCompletedExpectation.fulfill()
        }
        
        // Run multiple tasks concurrently
        async let task1: Void = runTask(id: 1)
        async let task2: Void = runTask(id: 2)
        async let task3: Void = runTask(id: 3)
        
        // Wait for all tasks to complete
        try await [task1, task2, task3]
        
        // Wait for completion notifications
        await fulfillment(of: [allTasksCompletedExpectation], timeout: 5.0)
        
        // Verify tasks are recorded in monitor
        let metrics = taskMonitor.getTaskPerformanceMetrics()
        XCTAssertEqual(metrics["completedTasks"] as? Int, 3, "Should have three completed tasks")
        
        // Verify aggregate progress reached 100%
        XCTAssertEqual(aggregateReporter.progress, 1.0, "Aggregate progress should be 100%")
        XCTAssertTrue(aggregateReporter.statusMessage.contains("Completed 3 of 3"), 
                    "Status message should indicate completion")
    }
} 