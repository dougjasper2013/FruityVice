//
//  Fruit.swift
//  FruityVice
//
//  Created by Douglas Jasper on 2025-10-06.
//

import Foundation

struct Fruit: Codable, Identifiable, Hashable {
    let id = UUID()           // Needed for List and Identifiable
    let name: String
    let genus: String
    let family: String
    let order: String
    let nutritions: Nutrition
}

struct Nutrition: Codable, Hashable {
    let carbohydrates: Double
    let protein: Double
    let fat: Double
    let calories: Double
    let sugar: Double
}
