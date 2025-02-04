import Foundation
import SwiftData

@Model
final class PostingDetails {
    @Attribute(.unique) var id: UUID
    var location: String
    var startDate: Date
    var endDate: Date?
    var unit: String
    
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