import SwiftData
import SwiftUI

struct RestaurantDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant

    @State private var searchText = ""
    @State private var sortOption: DishSortOption = .dateEatenDesc
    @State private var showingEditor = false
    @State private var showingRestaurantEditor = false
    @State private var showDeleteConfirm = false

    private var repository: DishDiaryRepository {
        DishDiaryRepository(context: context)
    }

    private var filteredDishes: [Dish] {
        let filtered = restaurant.dishes.filter { dish in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            let matchName = dish.name.lowercased().contains(query)
            let matchTags = dish.tags.contains { $0.lowercased().contains(query) }
            let matchNotes = dish.notes.lowercased().contains(query)
            return matchName || matchTags || matchNotes
        }
        return filtered.sorted(by: sortOption.sorter)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(restaurant.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(BistroTheme.textPrimary)
                    Spacer()
                    if let last = restaurant.lastEatenDate {
                        Text("Last: \(last, formatter: DateFormatter.shortDate)")
                            .font(.caption)
                            .foregroundColor(BistroTheme.secondary)
                    }
                }
                .padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(filteredDishes) { dish in
                        NavigationLink(value: dish.id) {
                            DishCardView(dish: dish)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 8)
        }
        .background(BistroTheme.canvas.ignoresSafeArea())
        .navigationTitle("Restaurant")
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
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingEditor = true }) {
                    Label("Add Dish", systemImage: "plus")
                }
                Menu {
                    Button("Edit Restaurant") {
                        showingRestaurantEditor = true
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Restaurant", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search dishes, notes, tags")
        .sheet(isPresented: $showingEditor) {
            DishEditorView(dish: nil, presetRestaurant: restaurant)
        }
        .sheet(isPresented: $showingRestaurantEditor) {
            RestaurantEditorView(restaurant: restaurant)
        }
        .alert("Delete restaurant?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                repository.deleteRestaurant(restaurant)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the restaurant and all dishes.")
        }
    }
}

struct DishDetailRouteView: View {
    @Query private var dishes: [Dish]

    init(dishID: UUID) {
        _dishes = Query(filter: #Predicate<Dish> { $0.id == dishID })
    }

    var body: some View {
        if let dish = dishes.first {
            DishDetailView(dish: dish)
        } else {
            ContentUnavailableView("Dish not found", systemImage: "exclamationmark.triangle")
                .background(BistroTheme.canvas)
        }
    }
}
