import CoreSpotlight
import SwiftData
import SwiftUI

final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .journal
    @Published var path = NavigationPath()
}

enum AppTab: Hashable {
    case journal
    case restaurants
}

@main
struct DishDiaryApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var router = AppRouter()

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
            RootView()
                .modelContainer(modelContainer)
                .environmentObject(router)
                .task {
                    await LegacyCoreDataImporter.importIfNeeded(into: modelContainer.mainContext)
                }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    guard let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                          let uuid = UUID(uuidString: id) else { return }
                    router.selectedTab = .journal
                    router.path = NavigationPath()
                    router.path.append(uuid)
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.path) {
                JournalView()
                    .navigationDestination(for: UUID.self) { id in
                        DishDetailRouteView(dishID: id)
                    }
            }
            .tabItem {
                Label("Journal", systemImage: "square.grid.2x2")
            }
            .tag(AppTab.journal)

            NavigationStack {
                RestaurantListView()
                    .navigationDestination(for: UUID.self) { id in
                        DishDetailRouteView(dishID: id)
                    }
            }
            .tabItem {
                Label("Restaurants", systemImage: "building.2")
            }
            .tag(AppTab.restaurants)
        }
        .tint(BistroTheme.primary)
        .background(BistroTheme.canvas.ignoresSafeArea())
    }
}
