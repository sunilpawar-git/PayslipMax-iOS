import Foundation

// MARK: - Protocol

/// Protocol for caching payslip comparison results
protocol PayslipComparisonCacheManagerProtocol {
    /// Retrieves a cached comparison for the given payslip ID
    /// - Parameter id: The UUID of the payslip
    /// - Returns: The cached comparison, or nil if not found
    func getComparison(for id: UUID) -> PayslipComparison?

    /// Stores a comparison in the cache
    /// - Parameters:
    ///   - comparison: The comparison to cache
    ///   - id: The UUID of the payslip
    func setComparison(_ comparison: PayslipComparison, for id: UUID)

    /// Clears all cached comparisons
    func clearCache()

    /// Invalidates (removes) a specific comparison from the cache
    /// - Parameter id: The UUID of the payslip to invalidate
    func invalidateComparison(for id: UUID)

    /// Waits for all pending async operations to complete (testing support)
    func waitForPendingOperations()
}

// MARK: - Implementation

/// Thread-safe cache manager for payslip comparisons using O(1) LRU eviction
final class PayslipComparisonCacheManager: PayslipComparisonCacheManagerProtocol {

    // MARK: - Configuration

    struct CacheConfiguration {
        let maxEntries: Int
        let ttl: TimeInterval?

        static let `default` = CacheConfiguration(maxEntries: 50, ttl: nil)
    }

    private struct CacheValue {
        let comparison: PayslipComparison
        let timestamp: Date
    }

    private final class Node {
        let key: UUID
        var value: CacheValue
        var previous: Node?
        var next: Node?

        init(key: UUID, value: CacheValue) {
            self.key = key
            self.value = value
        }
    }

    // MARK: - Properties

    private let configuration: CacheConfiguration
    private let queue: DispatchQueue
    private let dateProvider: () -> Date

    /// Node lookup for O(1) access and updates
    private var storage: [UUID: Node] = [:]
    private var head: Node?
    private var tail: Node?

    // MARK: - Initialization

    init(
        configuration: CacheConfiguration = .default,
        dateProvider: @escaping () -> Date = Date.init,
        queue: DispatchQueue = DispatchQueue(label: "com.payslipmax.xray.cache", attributes: .concurrent)
    ) {
        self.configuration = configuration
        self.dateProvider = dateProvider
        self.queue = queue
    }

    // MARK: - Public Methods

    func getComparison(for id: UUID) -> PayslipComparison? {
        queue.sync(flags: .barrier) {
            guard let node = storage[id] else {
                return nil
            }

            if isExpired(node.value) {
                remove(node)
                return nil
            }

            moveToTail(node)
            return node.value.comparison
        }
    }

    func setComparison(_ comparison: PayslipComparison, for id: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            let value = CacheValue(comparison: comparison, timestamp: self.dateProvider())

            if let existingNode = self.storage[id] {
                existingNode.value = value
                self.moveToTail(existingNode)
            } else {
                let newNode = Node(key: id, value: value)
                self.insertAtTail(newNode)
            }

            self.enforceCapacity()
        }
    }

    func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.storage.removeAll()
            self?.head = nil
            self?.tail = nil
        }
    }

    func invalidateComparison(for id: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self, let node = self.storage[id] else { return }
            self.remove(node)
        }
    }

    // MARK: - Internal (for testing)

    /// Returns the current cache size (for testing purposes)
    var cacheSize: Int {
        queue.sync {
            storage.count
        }
    }

    /// Waits for all pending async operations to complete (for testing purposes)
    func waitForPendingOperations() {
        queue.sync(flags: .barrier) { }
    }

    // MARK: - Private Helpers

    private func isExpired(_ value: CacheValue) -> Bool {
        guard let ttl = configuration.ttl else { return false }
        return dateProvider().timeIntervalSince(value.timestamp) > ttl
    }

    private func insertAtTail(_ node: Node) {
        storage[node.key] = node

        if let tail {
            tail.next = node
            node.previous = tail
        } else {
            head = node
        }

        tail = node
    }

    private func moveToTail(_ node: Node) {
        guard tail !== node else { return }

        let previous = node.previous
        let next = node.next

        if node === head {
            head = next
        }

        previous?.next = next
        next?.previous = previous

        node.previous = tail
        node.next = nil

        tail?.next = node
        tail = node

        if head == nil {
            head = node
        }
    }

    private func remove(_ node: Node) {
        let previous = node.previous
        let next = node.next

        if node === head {
            head = next
        }

        if node === tail {
            tail = previous
        }

        previous?.next = next
        next?.previous = previous

        node.previous = nil
        node.next = nil

        storage.removeValue(forKey: node.key)
    }

    private func enforceCapacity() {
        guard configuration.maxEntries > 0 else {
            storage.removeAll()
            head = nil
            tail = nil
            return
        }

        while storage.count > configuration.maxEntries, let head {
            remove(head)
        }
    }
}
