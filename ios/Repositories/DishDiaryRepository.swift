import CoreSpotlight
import SwiftData
import UIKit
import UniformTypeIdentifiers

@MainActor
struct DishDiaryRepository {
    let context: ModelContext
    let imageStore: ImageStore
    let spotlight: SpotlightIndexer

    init(
        context: ModelContext,
        imageStore: ImageStore = .shared,
        spotlight: SpotlightIndexer = .shared
    ) {
        self.context = context
        self.imageStore = imageStore
        self.spotlight = spotlight
    }

    @discardableResult
    func addRestaurant(name: String, latitude: Double? = nil, longitude: Double? = nil) -> Restaurant {
        let restaurant = Restaurant(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude,
            longitude: longitude,
            dateAdded: Date()
        )
        context.insert(restaurant)
        saveContext()
        return restaurant
    }

    func updateRestaurant(_ restaurant: Restaurant, name: String, latitude: Double? = nil, longitude: Double? = nil) {
        restaurant.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        restaurant.latitude = latitude
        restaurant.longitude = longitude
        saveContext()
    }

    func deleteRestaurant(_ restaurant: Restaurant) {
        restaurant.dishes.forEach { dish in
            imageStore.deleteImages(dish.imageRefs)
            spotlight.remove(dish: dish)
        }
        context.delete(restaurant)
        saveContext()
    }

    func addDish(
        name: String,
        rating: Double,
        notes: String,
        tags: [String],
        dateEaten: Date,
        imageRefs: [String],
        restaurant: Restaurant?
    ) -> Dish {
        let dish = Dish(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            rating: rating,
            notes: notes,
            tags: tags,
            dateEaten: dateEaten,
            createdAt: Date(),
            updatedAt: Date(),
            imageRefs: imageRefs,
            restaurant: restaurant
        )
        context.insert(dish)
        saveContext()
        spotlight.index(dish: dish)
        return dish
    }

    func updateDish(
        _ dish: Dish,
        name: String,
        rating: Double,
        notes: String,
        tags: [String],
        dateEaten: Date,
        imageRefs: [String],
        restaurant: Restaurant?
    ) {
        dish.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        dish.rating = Dish.clampRating(rating)
        dish.notes = notes
        dish.tags = tags
        dish.dateEaten = dateEaten
        dish.imageRefs = imageRefs
        dish.restaurant = restaurant
        dish.updatedAt = Date()
        saveContext()
        spotlight.index(dish: dish)
    }

    func deleteDish(_ dish: Dish) {
        imageStore.deleteImages(dish.imageRefs)
        spotlight.remove(dish: dish)
        context.delete(dish)
        saveContext()
    }

    func reindexAllDishes(_ dishes: [Dish]) {
        spotlight.reindex(dishes: dishes)
    }

    func saveContext() {
        do {
            try context.save()
        } catch {
            NSLog("SwiftData save failed: \(error.localizedDescription)")
        }
    }
}

final class SpotlightIndexer {
    static let shared = SpotlightIndexer()
    private let index = CSSearchableIndex.default()

    func index(dish: Dish) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.item)
        attributeSet.title = dish.name
        attributeSet.contentDescription = dish.notes.isEmpty ? nil : String(dish.notes.prefix(500))

        var keywords = dish.tags
        if let restaurantName = dish.restaurant?.name {
            keywords.append(restaurantName)
        }
        attributeSet.keywords = keywords.isEmpty ? nil : keywords

        let item = CSSearchableItem(
            uniqueIdentifier: dish.id.uuidString,
            domainIdentifier: "dish",
            attributeSet: attributeSet
        )
        index.indexSearchableItems([item]) { error in
            if let error {
                NSLog("Spotlight index failed: \(error.localizedDescription)")
            }
        }
    }

    func remove(dish: Dish) {
        index.deleteSearchableItems(withIdentifiers: [dish.id.uuidString]) { error in
            if let error {
                NSLog("Spotlight delete failed: \(error.localizedDescription)")
            }
        }
    }

    func reindex(dishes: [Dish]) {
        let items = dishes.map { dish -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: UTType.item)
            attributeSet.title = dish.name
            attributeSet.contentDescription = dish.notes.isEmpty ? nil : String(dish.notes.prefix(500))
            var keywords = dish.tags
            if let restaurantName = dish.restaurant?.name {
                keywords.append(restaurantName)
            }
            attributeSet.keywords = keywords.isEmpty ? nil : keywords
            return CSSearchableItem(
                uniqueIdentifier: dish.id.uuidString,
                domainIdentifier: "dish",
                attributeSet: attributeSet
            )
        }

        index.indexSearchableItems(items) { error in
            if let error {
                NSLog("Spotlight reindex failed: \(error.localizedDescription)")
            }
        }
    }
}
