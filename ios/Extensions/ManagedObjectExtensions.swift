import Foundation
import SwiftData

@Model
final class Restaurant {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var dateAdded: Date
    @Relationship(deleteRule: .cascade) var dishes: [Dish]

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        dateAdded: Date = Date(),
        dishes: [Dish] = []
    ) {
        self.id = id
        self.name = name
        self.address = address
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
    var tagsData: Data
    var dateEaten: Date
    var createdAt: Date
    var updatedAt: Date
    var imageRefsData: Data
    var restaurant: Restaurant?

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
        self.tagsData = Dish.encodeStringArray(tags)
        self.dateEaten = dateEaten
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageRefsData = Dish.encodeStringArray(imageRefs)
        self.restaurant = restaurant
    }

    var tags: [String] {
        get { Dish.decodeStringArray(from: tagsData) }
        set { tagsData = Dish.encodeStringArray(newValue) }
    }

    var imageRefs: [String] {
        get { Dish.decodeStringArray(from: imageRefsData) }
        set { imageRefsData = Dish.encodeStringArray(newValue) }
    }

    var tagDisplay: String {
        tags.joined(separator: ", ")
    }

    static func clampRating(_ value: Double) -> Double {
        min(max(round(value * 2) / 2.0, 0.0), 5.0)
    }

    private static func encodeStringArray(_ values: [String]) -> Data {
        (try? JSONEncoder().encode(values)) ?? Data()
    }

    private static func decodeStringArray(from data: Data) -> [String] {
        (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }
}
