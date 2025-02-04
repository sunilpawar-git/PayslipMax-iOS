import Foundation
import SwiftData

@Model
final class Allowance {
    @Attribute(.unique) var id: UUID
    var name: String
    var amount: Double
    var category: String
    
    init(id: UUID = UUID(), name: String, amount: Double, category: String) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
    }
} 