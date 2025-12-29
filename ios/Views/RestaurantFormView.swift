import SwiftData
import SwiftUI

struct RestaurantEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant?

    @State private var name: String
    @State private var address: String
    @State private var showValidation = false

    private var repository: DishDiaryRepository {
        DishDiaryRepository(context: context)
    }

    init(restaurant: Restaurant?) {
        self.restaurant = restaurant
        _name = State(initialValue: restaurant?.name ?? "")
        _address = State(initialValue: restaurant?.address ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Restaurant") {
                    TextField("Name", text: $name)
                        .onChange(of: name) { _ in showValidation = true }
                    TextField("Street address", text: $address)
                        .onChange(of: address) { _ in showValidation = true }

                    if showValidation && !isValid {
                        Text("Name and address are required")
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

        if let restaurant {
            repository.updateRestaurant(restaurant, name: name, address: address)
        } else {
            _ = repository.addRestaurant(name: name, address: address)
        }

        dismiss()
    }
}
