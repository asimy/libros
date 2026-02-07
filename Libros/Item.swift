//
//  Item.swift
//  Libros
//
//  Created by Glen Aultman-Bettridge on 2/7/26.
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
