import SwiftUI

@main
struct DishDiaryApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RestaurantListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
