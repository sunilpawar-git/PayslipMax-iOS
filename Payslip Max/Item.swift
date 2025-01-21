//
//  Item.swift
//  Payslip Max
//
//  Created by Sunil on 21/01/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
