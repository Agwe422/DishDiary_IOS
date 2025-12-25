import CoreData
import UIKit

struct DishDiaryRepository {
    let context: NSManagedObjectContext
    let imageStore: ImageStore

    init(context: NSManagedObjectContext, imageStore: ImageStore = ImageStore()) {
        self.context = context
        self.imageStore = imageStore
    }

    @discardableResult
    func addRestaurant(name: String, address: String?) -> Restaurant? {
        let restaurant = Restaurant(context: context)
        restaurant.id = restaurant.id ?? UUID()
        restaurant.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        restaurant.address = address?.trimmingCharacters(in: .whitespacesAndNewlines)
        saveContext()
        return restaurant
    }

    func updateRestaurant(_ restaurant: Restaurant, name: String, address: String?) {
        restaurant.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        restaurant.address = address?.trimmingCharacters(in: .whitespacesAndNewlines)
        saveContext()
    }

    func deleteRestaurant(_ restaurant: Restaurant) {
        let notes = (restaurant.dishNotes as? Set<DishNote>) ?? []
        let paths = notes.flatMap { ($0.imagePaths as? [String]) ?? [] }
        imageStore.deleteImages(at: paths)
        context.delete(restaurant)
        saveContext()
    }

    func addDishNote(to restaurant: Restaurant, name: String, rating: Double?, note: String, imagePaths: [String]) {
        let dishNote = DishNote(context: context)
        dishNote.id = UUID()
        dishNote.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let rating {
            dishNote.rating = NSNumber(value: rating)
        } else {
            dishNote.rating = nil
        }
        dishNote.note = note
        dishNote.imagePaths = imagePaths
        dishNote.restaurant = restaurant
        saveContext()
    }

    func updateDishNote(_ dishNote: DishNote, name: String, rating: Double?, note: String, imagePaths: [String]) {
        dishNote.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let rating {
            dishNote.rating = NSNumber(value: rating)
        } else {
            dishNote.rating = nil
        }
        dishNote.note = note
        dishNote.imagePaths = imagePaths
        saveContext()
    }

    func deleteDishNote(_ dishNote: DishNote) {
        let paths = (dishNote.imagePaths as? [String]) ?? []
        imageStore.deleteImages(at: paths)
        context.delete(dishNote)
        saveContext()
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                NSLog("Failed to save context: \(error.localizedDescription)")
            }
        }
    }
}
