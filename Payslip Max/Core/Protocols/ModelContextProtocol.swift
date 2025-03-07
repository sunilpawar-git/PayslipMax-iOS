import SwiftData
import Foundation

// MARK: - Model Context Protocol
protocol ModelContextProtocol {
    func insert<T: PersistentModel>(_ model: T)
    func delete<T: PersistentModel>(_ model: T)
    func save() throws
}

extension ModelContext: ModelContextProtocol {
    // ModelContext already implements these methods with the correct signatures
    // No need to add additional implementations
} 