//
//  Item.swift
//  PayslipMax
//
//  Created by Sunil on 21/01/25.
//

import Foundation
import SwiftData

/// A basic timestamped item model.
///
/// This class serves as a placeholder or a base for items that primarily need a timestamp.
/// It is designed to be persisted using SwiftData.
@Model
final class Item {
    /// The date and time when the item was created or recorded.
    var timestamp: Date
    
    /// Initializes a new item with a specific timestamp.
    ///
    /// - Parameter timestamp: The timestamp for the item.
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
