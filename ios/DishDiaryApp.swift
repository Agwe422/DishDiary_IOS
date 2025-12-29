import CoreSpotlight
import SwiftData
import SwiftUI

@main
struct DishDiaryApp: App {
    private let modelContainer: ModelContainer
    @State private var path = NavigationPath()

    init() {
        let schema = Schema([Restaurant.self, Dish.self])
        let configuration = ModelConfiguration("DishDiary", schema: schema)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }

        BistroTheme.applyNavigationAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView(path: $path)
                .modelContainer(modelContainer)
                .task {
                    await LegacyCoreDataImporter.importIfNeeded(into: modelContainer.mainContext)
                }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    guard let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                          let uuid = UUID(uuidString: id) else { return }
                    path = NavigationPath()
                    path.append(uuid)
                }
        }
    }
}

struct RootView: View {
    @Binding var path: NavigationPath

    var body: some View {
        NavigationStack(path: $path) {
            RestaurantListView()
                .navigationDestination(for: UUID.self) { id in
                    DishDetailRouteView(dishID: id)
                }
        }
        .tint(BistroTheme.primary)
        .background(BistroTheme.canvas.ignoresSafeArea())
    }
}
