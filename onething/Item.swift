//
//  Item.swift
//  onething
//
//  Created by Tanmoy Khanra on 25/12/25.
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
