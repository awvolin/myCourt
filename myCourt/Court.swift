//
//  Court.swift
//  myCourt
//
//  Created by Alex Volin on 8/5/23.
//

import Foundation
struct Court: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var description: String
    var numGames: Int64
    // You can add more properties as needed, like location, capacity, etc.
}
    
