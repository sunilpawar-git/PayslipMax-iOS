import Foundation
import SwiftData

@Model
final class PostingTransition: Identifiable {
    @Attribute(.unique) var id: UUID
    var fromLocation: String
    var toLocation: String
    var transitionDate: Date
    var allowances: [Allowance]
    var remarks: String?
    
    init(id: UUID = UUID(),
         fromLocation: String,
         toLocation: String,
         transitionDate: Date,
         allowances: [Allowance] = [],
         remarks: String? = nil) {
        self.id = id
        self.fromLocation = fromLocation
        self.toLocation = toLocation
        self.transitionDate = transitionDate
        self.allowances = allowances
        self.remarks = remarks
    }
} 