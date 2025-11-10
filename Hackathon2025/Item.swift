//
//  Item.swift
//  Hackathon2025
//
//  Created by Daniel Garcia Abril on 10/11/25.
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
