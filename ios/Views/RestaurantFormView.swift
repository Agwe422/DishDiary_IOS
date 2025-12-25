import SwiftUI

struct RestaurantFormView: View {
    @Environment(\.dismiss) private var dismiss

    var restaurant: Restaurant?
    var onSave: ((String, String) -> Void)?

    @State private var name: String
    @State private var address: String
    @State private var showValidation = false

    init(restaurant: Restaurant?, onSave: ((String, String) -> Void)? = nil) {
        self.restaurant = restaurant
        self.onSave = onSave
        _name = State(initialValue: restaurant?.wrappedName ?? "")
        _address = State(initialValue: restaurant?.wrappedAddress ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                        .onChange(of: name) { _ in showValidation = true }
                    TextField("Address (optional)", text: $address)

                    if showValidation && !isValid {
                        Text("Name is required")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(restaurant == nil ? "Add Restaurant" : "Edit Restaurant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard isValid else {
                            showValidation = true
                            return
                        }
                        onSave?(name, address)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
