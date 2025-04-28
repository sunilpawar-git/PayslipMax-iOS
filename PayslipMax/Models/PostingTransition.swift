import Foundation
import SwiftData

/// Represents a transition or change in military posting location.
///
/// This model stores details about a specific posting transition event,
/// such as the new location, the date of the transition, and any remarks.
/// It is designed to be persisted using SwiftData.
@Model
final class PostingTransition: Identifiable {
    /// The unique identifier for the posting transition record.
    @Attribute(.unique) var id: UUID
    /// The new location associated with the posting transition.
    var location: String
    /// The date when the posting transition occurred.
    var date: Date
    /// Optional remarks or notes related to the transition.
    var remarks: String?
    
    /// Initializes a new posting transition record.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - location: The new posting location.
    ///   - date: The date of the transition.
    ///   - remarks: Optional remarks about the transition. Defaults to nil.
    init(id: UUID = UUID(), location: String, date: Date, remarks: String? = nil) {
        self.id = id
        self.location = location
        self.date = date
        self.remarks = remarks
    }
} 