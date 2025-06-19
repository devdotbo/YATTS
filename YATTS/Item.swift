//
//  Item.swift
//  YATTS
//
//  Created by Reza Shokri on 19.06.25.
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
