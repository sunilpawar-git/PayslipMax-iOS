import XCTest
@testable import PayslipMax
import Combine

class TaskPriorityQueueTests: XCTestCase {
    // Test variables
    private var queue: TaskPriorityQueue!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        queue = TaskPriorityQueue(maxConcurrentTasks: 2) // Limit to 2 concurrent tasks for testing
    }
    
    override func tearDown() {
        queue = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testEnqueueTask() {
        // Arrange
        let expectation = expectation(description: "Task queued")
        var receivedEvent: TaskPriorityQueue.QueueEvent?
        
        queue.publisher
            .sink { event in
                receivedEvent = event
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        let task = createMockTask(id: "testTask", priority: .medium)
        queue.enqueue(task: task)
        
        // Assert
        waitForExpectations(timeout: 1)
        
        if case .taskQueued(let taskId, let priority) = receivedEvent {
            XCTAssertEqual(taskId.name, "testTask")
            XCTAssertEqual(priority, .medium)
        } else {
            XCTFail("Expected taskQueued event but received \(String(describing: receivedEvent))")
        }
        
        XCTAssertEqual(queue.queuedTaskCount, 0, "Task should have been moved to running")
        XCTAssertEqual(queue.runningTaskCount, 1, "Task should be running")
    }
    
    func testPriorityOrderingHigh() {
        // Arrange - Create tasks with different priorities
        let highPriorityTask = createSlowMockTask(id: "highTask", priority: .high)
        let mediumPriorityTask = createSlowMockTask(id: "mediumTask", priority: .medium)
        let lowPriorityTask = createSlowMockTask(id: "lowTask", priority: .low)
        
        // Create expectations for the started events
        let expectation1 = expectation(description: "First task started")
        let expectation2 = expectation(description: "Second task started")
        
        var startedTasks: [String] = []
        
        queue.publisher
            .compactMap { event -> String? in
                if case .taskStarted(let taskId) = event {
                    return taskId.name
                }
                return nil
            }
            .sink { taskName in
                startedTasks.append(taskName)
                if startedTasks.count == 1 {
                    expectation1.fulfill()
                } else if startedTasks.count == 2 {
                    expectation2.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act - Add tasks in non-priority order
        queue.enqueue(task: lowPriorityTask)
        queue.enqueue(task: highPriorityTask)
        queue.enqueue(task: mediumPriorityTask)
        
        // Assert - First two should be high and medium
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(startedTasks.count, 2)
        XCTAssertEqual(startedTasks[0], "highTask", "High priority task should start first")
        XCTAssertEqual(startedTasks[1], "mediumTask", "Medium priority task should start second")
        
        // Check queue state
        XCTAssertEqual(queue.runningTaskCount, 2, "Should be running 2 tasks")
        XCTAssertEqual(queue.queuedTaskCount, 1, "Should have 1 task queued")
    }
    
    func testMaxConcurrentTasksLimit() {
        // Arrange - Create max+1 tasks
        let task1 = createSlowMockTask(id: "task1", priority: .medium)
        let task2 = createSlowMockTask(id: "task2", priority: .medium)
        let task3 = createSlowMockTask(id: "task3", priority: .medium)
        
        let throttledExpectation = expectation(description: "Queue throttled")
        
        queue.publisher
            .compactMap { event -> (currentCount: Int, maxAllowed: Int)? in
                if case .queueThrottled(let currentCount, let maxAllowed) = event {
                    return (currentCount, maxAllowed)
                }
                return nil
            }
            .sink { throttleInfo in
                XCTAssertEqual(throttleInfo.currentCount, 2)
                XCTAssertEqual(throttleInfo.maxAllowed, 2)
                throttledExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act - Add all tasks
        queue.enqueue(task: task1)
        queue.enqueue(task: task2)
        queue.enqueue(task: task3)
        
        // Assert
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(queue.runningTaskCount, 2, "Should be running 2 tasks")
        XCTAssertEqual(queue.queuedTaskCount, 1, "Should have 1 task queued")
    }
    
    // Helper method to create mock tasks
    private func createMockTask(id: String, priority: TaskPriority) -> MockTask {
        return MockTask(id: TaskIdentifier(name: id), priority: priority)
    }
    
    private func createSlowMockTask(id: String, priority: TaskPriority) -> MockTask {
        return MockTask(id: TaskIdentifier(name: id), priority: priority, shouldComplete: false)
    }
}

// MARK: - Mock implementation for testing

/// Mock task implementation for testing
class MockTask: ManagedTask {
    let id: TaskIdentifier
    let priority: TaskPriority
    private(set) var status: TaskStatus = .pending
    let shouldComplete: Bool
    
    init(id: TaskIdentifier, priority: TaskPriority, shouldComplete: Bool = true) {
        self.id = id
        self.priority = priority
        self.shouldComplete = shouldComplete
    }
    
    var progress: Double = 0.0
    var statusMessage: String = "Test task"
    var isCancellable: Bool = true
    var dependencies: [TaskIdentifier] = []
    
    func start() async throws {
        status = .running
        
        // Simulate some work
        for i in 1...5 {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            progress = Double(i) / 5.0
        }
        
        if shouldComplete {
            status = .completed
        }
    }
    
    func pause() async {
        status = .paused
    }
    
    func resume() async {
        status = .running
    }
    
    func cancel() async {
        status = .cancelled
    }
} 