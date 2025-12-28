import SwiftData
import SwiftUI

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query private var dishes: [Dish]

    @State private var searchText = ""
    @State private var sortOption: DishSortOption = .dateEatenDesc
    @State private var showingEditor = false

    private var repository: DishDiaryRepository {
        DishDiaryRepository(context: context)
    }

    private var filteredDishes: [Dish] {
        let filtered = dishes.filter { dish in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            let matchName = dish.name.lowercased().contains(query)
            let matchRestaurant = dish.restaurant?.name.lowercased().contains(query) ?? false
            let matchTags = dish.tags.contains { $0.lowercased().contains(query) }
            let matchNotes = dish.notes.lowercased().contains(query)
            return matchName || matchRestaurant || matchTags || matchNotes
        }

        return filtered.sorted(by: sortOption.sorter)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filteredDishes) { dish in
                    NavigationLink(value: dish.id) {
                        DishCardView(dish: dish)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(BistroTheme.canvas.ignoresSafeArea())
        .navigationTitle("Journal")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(DishSortOption.allCases, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditor = true }) {
                    Label("Add Dish", systemImage: "plus")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search dishes, notes, tags")
        .sheet(isPresented: $showingEditor) {
            DishEditorView(dish: nil)
        }
        .onAppear {
            repository.reindexAllDishes(dishes)
        }
    }
}

struct RestaurantListView: View {
    @Environment(\.modelContext) private var context
    @Query private var restaurants: [Restaurant]

    @State private var searchText = ""
    @State private var sortOption: RestaurantSortOption = .nameAsc
    @State private var showingAddRestaurant = false

    private var filteredRestaurants: [Restaurant] {
        let filtered = restaurants.filter { restaurant in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            let matchName = restaurant.name.lowercased().contains(query)
            let matchDish = restaurant.dishes.contains { dish in
                dish.name.lowercased().contains(query)
                    || dish.notes.lowercased().contains(query)
                    || dish.tags.contains { $0.lowercased().contains(query) }
            }
            return matchName || matchDish
        }

        return filtered.sorted(by: sortOption.sorter)
    }

    var body: some View {
        List {
            ForEach(filteredRestaurants) { restaurant in
                NavigationLink {
                    RestaurantDetailView(restaurant: restaurant)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(restaurant.name)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(BistroTheme.textPrimary)
                        HStack(spacing: 12) {
                            Text("\(restaurant.dishCount) dishes")
                                .font(.caption)
                                .foregroundColor(BistroTheme.secondary)
                            if let last = restaurant.lastEatenDate {
                                Text("Last: \(last, formatter: DateFormatter.shortDate)")
                                    .font(.caption)
                                    .foregroundColor(BistroTheme.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(BistroTheme.canvas)
        .navigationTitle("Restaurants")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        ForEach(RestaurantSortOption.allCases, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddRestaurant = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search restaurants, dishes, notes")
        .sheet(isPresented: $showingAddRestaurant) {
            RestaurantEditorView(restaurant: nil)
        }
    }
}

enum DishSortOption: String, CaseIterable {
    case dateEatenDesc
    case dateEatenAsc
    case ratingDesc
    case ratingAsc
    case nameAsc
    case nameDesc

    var title: String {
        switch self {
        case .dateEatenDesc: return "Most Recent"
        case .dateEatenAsc: return "Oldest First"
        case .ratingDesc: return "Rating High–Low"
        case .ratingAsc: return "Rating Low–High"
        case .nameAsc: return "Name A–Z"
        case .nameDesc: return "Name Z–A"
        }
    }

    var sorter: (Dish, Dish) -> Bool {
        switch self {
        case .dateEatenDesc:
            return { lhs, rhs in
                if lhs.dateEaten == rhs.dateEaten {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.dateEaten > rhs.dateEaten
            }
        case .dateEatenAsc:
            return { lhs, rhs in
                if lhs.dateEaten == rhs.dateEaten {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.dateEaten < rhs.dateEaten
            }
        case .ratingDesc:
            return { lhs, rhs in
                if lhs.rating == rhs.rating {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.rating > rhs.rating
            }
        case .ratingAsc:
            return { lhs, rhs in
                if lhs.rating == rhs.rating {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.rating < rhs.rating
            }
        case .nameAsc:
            return { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            return { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }
    }
}

enum RestaurantSortOption: String, CaseIterable {
    case nameAsc
    case nameDesc
    case recentDesc
    case recentAsc

    var title: String {
        switch self {
        case .nameAsc: return "Name A–Z"
        case .nameDesc: return "Name Z–A"
        case .recentDesc: return "Most Recent"
        case .recentAsc: return "Oldest First"
        }
    }

    var sorter: (Restaurant, Restaurant) -> Bool {
        switch self {
        case .nameAsc:
            return { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            return { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .recentDesc:
            return { lhs, rhs in
                let lhsDate = lhs.lastEatenDate ?? lhs.dateAdded
                let rhsDate = rhs.lastEatenDate ?? rhs.dateAdded
                if lhsDate == rhsDate {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhsDate > rhsDate
            }
        case .recentAsc:
            return { lhs, rhs in
                let lhsDate = lhs.lastEatenDate ?? lhs.dateAdded
                let rhsDate = rhs.lastEatenDate ?? rhs.dateAdded
                if lhsDate == rhsDate {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhsDate < rhsDate
            }
        }
    }
}
