import Foundation
import SwiftData

@Model
final class PostingTransition: Identifiable {
    @Attribute(.unique) var id: UUID
    var location: String
    var date: Date
    var remarks: String?
    
    init(id: UUID = UUID(), location: String, date: Date, remarks: String? = nil) {
        self.id = id
        self.location = location
        self.date = date
        self.remarks = remarks
    }
} 