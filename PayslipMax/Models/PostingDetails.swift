import Foundation
import SwiftData

/// Represents the details of a military posting.
///
/// This model stores information about a specific posting, including location, dates, and unit.
/// It is designed to be persisted using SwiftData.
@Model
final class PostingDetails {
    /// The unique identifier for the posting details record.
    @Attribute(.unique) var id: UUID
    /// The geographical location of the posting.
    var location: String
    /// The date when the posting started.
    var startDate: Date
    /// The date when the posting ended (optional, nil if current posting).
    var endDate: Date?
    /// The military unit associated with the posting.
    var unit: String
    
    /// Initializes new posting details.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - location: The location of the posting.
    ///   - startDate: The start date of the posting.
    ///   - endDate: The end date of the posting (optional).
    ///   - unit: The unit associated with the posting.
    init(id: UUID = UUID(), 
         location: String, 
         startDate: Date, 
         endDate: Date? = nil, 
         unit: String) {
        self.id = id
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.unit = unit
    }
} 