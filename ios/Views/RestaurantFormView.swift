import SwiftData
import SwiftUI

struct RestaurantEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant?

    @State private var name: String
    @State private var latitude: String
    @State private var longitude: String
    @State private var showValidation = false

    private var repository: DishDiaryRepository {
        DishDiaryRepository(context: context)
    }

    init(restaurant: Restaurant?) {
        self.restaurant = restaurant
        _name = State(initialValue: restaurant?.name ?? "")
        _latitude = State(initialValue: restaurant?.latitude != nil ? String(restaurant?.latitude ?? 0) : "")
        _longitude = State(initialValue: restaurant?.longitude != nil ? String(restaurant?.longitude ?? 0) : "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Restaurant") {
                    TextField("Name", text: $name)
                        .onChange(of: name) { _ in showValidation = true }
                    TextField("Latitude (optional)", text: $latitude)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Longitude (optional)", text: $longitude)
                        .keyboardType(.numbersAndPunctuation)

                    if showValidation && !isValid {
                        Text("Name is required")
                            .foregroundColor(BistroTheme.bad)
                            .font(.footnote)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(BistroTheme.canvas)
            .navigationTitle(restaurant == nil ? "Add Restaurant" : "Edit Restaurant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        guard isValid else {
            showValidation = true
            return
        }

        let latValue = Double(latitude.trimmingCharacters(in: .whitespacesAndNewlines))
        let lonValue = Double(longitude.trimmingCharacters(in: .whitespacesAndNewlines))

        if let restaurant {
            repository.updateRestaurant(restaurant, name: name, latitude: latValue, longitude: lonValue)
        } else {
            _ = repository.addRestaurant(name: name, latitude: latValue, longitude: lonValue)
        }

        dismiss()
    }
}
