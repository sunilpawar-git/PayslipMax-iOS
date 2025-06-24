import Foundation

/// Protocol for secure storage operations
protocol SecureStorageProtocol {
    /// Save raw data for a given key
    func saveData(key: String, data: Data) throws
    
    /// Retrieve raw data for a given key
    func getData(key: String) throws -> Data?
    
    /// Save a string value for a given key
    func saveString(key: String, value: String) throws
    
    /// Retrieve a string value for a given key
    func getString(key: String) throws -> String?
    
    /// Delete an item for a given key
    func deleteItem(key: String) throws
} 