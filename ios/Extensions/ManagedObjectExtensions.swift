import Foundation
import SwiftData

@Model
final class Restaurant {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double?
    var longitude: Double?
    var dateAdded: Date
    @Relationship(deleteRule: .cascade, inverse: \Dish.restaurant) var dishes: [Dish]

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        dateAdded: Date = Date(),
        dishes: [Dish] = []
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.dateAdded = dateAdded
        self.dishes = dishes
    }

    var dishCount: Int { dishes.count }
    var lastEatenDate: Date? { dishes.map(\.dateEaten).max() }
}

@Model
final class Dish {
    @Attribute(.unique) var id: UUID
    var name: String
    var rating: Double
    var notes: String
    @Attribute(.transformable) var tags: [String]
    var dateEaten: Date
    var createdAt: Date
    var updatedAt: Date
    @Attribute(.transformable) var imageRefs: [String]
    @Relationship(inverse: \Restaurant.dishes) var restaurant: Restaurant?

    init(
        id: UUID = UUID(),
        name: String,
        rating: Double = 0.0,
        notes: String = "",
        tags: [String] = [],
        dateEaten: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        imageRefs: [String] = [],
        restaurant: Restaurant? = nil
    ) {
        self.id = id
        self.name = name
        self.rating = Dish.clampRating(rating)
        self.notes = notes
        self.tags = tags
        self.dateEaten = dateEaten
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageRefs = imageRefs
        self.restaurant = restaurant
    }

    var tagDisplay: String {
        tags.joined(separator: ", ")
    }

    static func clampRating(_ value: Double) -> Double {
        min(max(round(value * 2) / 2.0, 0.0), 5.0)
    }
}
