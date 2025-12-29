import CoreData
import SwiftData

@MainActor
enum LegacyCoreDataImporter {
    private static let migrationKey = "didImportLegacyCoreData"

    static func importIfNeeded(into context: ModelContext) async {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        guard let legacyStore = LegacyCoreDataStore() else {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        do {
            let existing = try context.fetch(FetchDescriptor<Restaurant>())
            if !existing.isEmpty {
                UserDefaults.standard.set(true, forKey: migrationKey)
                return
            }
        } catch {
            NSLog("SwiftData preflight fetch failed: \(error.localizedDescription)")
        }

        let importedRestaurants = legacyStore.fetchRestaurants()
        guard !importedRestaurants.isEmpty else {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        for legacyRestaurant in importedRestaurants {
            let name = (legacyRestaurant.value(forKey: "name") as? String) ?? "Untitled"
            let dateAdded = (legacyRestaurant.value(forKey: "createdAt") as? Date) ?? Date()
            let restaurant = Restaurant(name: name, dateAdded: dateAdded)

            if let notes = legacyRestaurant.value(forKey: "dishNotes") as? Set<NSManagedObject> {
                for legacyDish in notes {
                    let dishName = (legacyDish.value(forKey: "name") as? String) ?? "Untitled Dish"
                    let rawRating = (legacyDish.value(forKey: "rating") as? NSNumber)?.doubleValue ?? 0
                    let normalizedRating = Dish.clampRating(rawRating / 2.0)
                    let notesText = (legacyDish.value(forKey: "note") as? String) ?? ""
                    let createdAt = (legacyDish.value(forKey: "createdAt") as? Date) ?? Date()
                    let updatedAt = (legacyDish.value(forKey: "updatedAt") as? Date) ?? createdAt
                    let imagePaths = (legacyDish.value(forKey: "imagePaths") as? [String]) ?? []
                    let imageRefs = imagePaths.map { URL(fileURLWithPath: $0).lastPathComponent }

                    let dish = Dish(
                        name: dishName,
                        rating: normalizedRating,
                        notes: notesText,
                        tags: [],
                        dateEaten: createdAt,
                        createdAt: createdAt,
                        updatedAt: updatedAt,
                        imageRefs: imageRefs,
                        restaurant: restaurant
                    )
                    restaurant.dishes.append(dish)
                }
            }

            context.insert(restaurant)
        }

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            NSLog("SwiftData migration save failed: \(error.localizedDescription)")
        }
    }
}

private final class LegacyCoreDataStore {
    private let container: NSPersistentContainer

    init?() {
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Restaurant.sqlite")
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return nil }

        container = NSPersistentContainer(name: "Restaurant")
        let description = NSPersistentStoreDescription(url: storeURL)
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if let error = loadError {
            NSLog("Legacy Core Data load failed: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchRestaurants() -> [NSManagedObject] {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Restaurant")
        do {
            return try context.fetch(request)
        } catch {
            NSLog("Legacy Core Data fetch failed: \(error.localizedDescription)")
            return []
        }
    }
}
