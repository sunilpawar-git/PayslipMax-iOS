import Foundation

class MockDataService: DataServiceProtocol {
    var fetchCallCount = 0
    var shouldFail = false
    var items: [String: Any] = [:]

    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        fetchCallCount += 1
        if shouldFail {
            throw MockError.fetchFailed
        }
        if let items = items[String(describing: T.self)] as? [T] {
            return items
        }
        return []
    }
    
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        fetchCallCount += 1
        if shouldFail {
            throw MockError.fetchFailed
        }
        if let items = items[String(describing: T.self)] as? [T] {
            return items
        }
        return []
    }
    
    func save<T>(_ item: T) async throws where T: Identifiable {
        // Implementation needed
    }
} 