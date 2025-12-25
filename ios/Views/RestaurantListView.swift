import SwiftUI

struct RestaurantListView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Restaurant.name, ascending: true)],
        animation: .default
    )
    private var restaurants: FetchedResults<Restaurant>

    @State private var searchText = ""
    @State private var sortAscending = true
    @State private var showingAddRestaurant = false

    private var repository: DishDiaryRepository {
        DishDiaryRepository(context: context)
    }

    private var filteredRestaurants: [Restaurant] {
        restaurants
            .filter { restaurant in
                guard !searchText.isEmpty else { return true }
                let query = searchText.lowercased()
                let matchesName = restaurant.wrappedName.lowercased().contains(query)
                let matchesAddress = restaurant.wrappedAddress.lowercased().contains(query)
                return matchesName || matchesAddress
            }
            .sorted { lhs, rhs in
                let lhsName = lhs.wrappedName.lowercased()
                let rhsName = rhs.wrappedName.lowercased()
                return sortAscending ? lhsName < rhsName : lhsName > rhsName
            }
    }

    var body: some View {
        NavigationView {
            Group {
                if filteredRestaurants.isEmpty {
                    VStack(spacing: 12) {
                        Text("No restaurants yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button(action: { showingAddRestaurant = true }) {
                            Label("Add Restaurant", systemImage: "plus")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredRestaurants, id: \.objectID) { restaurant in
                            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(restaurant.wrappedName)
                                        .font(.headline)
                                    if !restaurant.wrappedAddress.isEmpty {
                                        Text(restaurant.wrappedAddress)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Dish Diary")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { sortAscending.toggle() }) {
                        Label(sortAscending ? "A–Z" : "Z–A", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRestaurant = true }) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search name or address")
            .sheet(isPresented: $showingAddRestaurant) {
                RestaurantFormView(
                    restaurant: nil,
                    onSave: { name, address in
                        _ = repository.addRestaurant(name: name, address: address.isEmpty ? nil : address)
                    }
                )
            }
        }
    }
}
