import PhotosUI
import SwiftData
import SwiftUI

struct DishEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let dish: Dish?
    let presetRestaurant: Restaurant?

    @State private var name: String
    @State private var rating: Double
    @State private var notes: String
    @State private var tagsText: String
    @State private var dateEaten: Date
    @State private var imageRefs: [String]
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showValidation = false

    private let maxImages = 5

    private var repository: DishDiaryRepository {
        DishDiaryRepository(context: context)
    }

    init(dish: Dish?, presetRestaurant: Restaurant? = nil) {
        self.dish = dish
        self.presetRestaurant = presetRestaurant
        _name = State(initialValue: dish?.name ?? "")
        _rating = State(initialValue: dish?.rating ?? 0.0)
        _notes = State(initialValue: dish?.notes ?? "")
        _tagsText = State(initialValue: dish?.tagDisplay ?? "")
        _dateEaten = State(initialValue: dish?.dateEaten ?? Date())
        _imageRefs = State(initialValue: dish?.imageRefs ?? [])
    }

    private var remainingSlots: Int {
        max(0, maxImages - imageRefs.count)
    }

    private var resolvedRestaurant: Restaurant? {
        dish?.restaurant ?? presetRestaurant
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && resolvedRestaurant != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dish") {
                    TextField("Name", text: $name)
                        .onChange(of: name) { _ in showValidation = true }
                    StarRatingControl(rating: $rating)
                    DatePicker("Date eaten", selection: $dateEaten, displayedComponents: .date)
                }

                Section("Restaurant") {
                    if let restaurant = resolvedRestaurant {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(restaurant.name)
                                .font(.headline)
                                .foregroundColor(BistroTheme.textPrimary)
                            Text(restaurant.address)
                                .font(.subheadline)
                                .foregroundColor(BistroTheme.secondary)
                        }
                    } else {
                        Text("Select a restaurant first")
                            .foregroundColor(BistroTheme.bad)
                    }
                }

                Section("Tags") {
                    TextField("Comma-separated tags", text: $tagsText)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }

                Section(header: HStack {
                    Text("Photos")
                    Spacer()
                    Text("\(imageRefs.count)/5")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(imageRefs, id: \.self) { ref in
                                ZStack(alignment: .topTrailing) {
                                    DiskImageView(
                                        ref: ref,
                                        targetSize: CGSize(width: 200, height: 200),
                                        contentMode: .fill,
                                        cornerRadius: 12
                                    )
                                    .frame(width: 96, height: 96)

                                    Button {
                                        imageRefs.removeAll { $0 == ref }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }

                            if remainingSlots > 0 {
                                PhotosPicker(
                                    selection: $pickerItems,
                                    maxSelectionCount: remainingSlots,
                                    matching: .images
                                ) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.largeTitle)
                                        Text("Add")
                                            .font(.footnote)
                                    }
                                    .frame(width: 96, height: 96)
                                    .foregroundColor(BistroTheme.primary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                            .foregroundColor(BistroTheme.primary)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if showValidation && !isValid {
                    Text("Dish name and restaurant are required")
                        .font(.footnote)
                        .foregroundColor(BistroTheme.bad)
                }
            }
            .scrollContentBackground(.hidden)
            .background(BistroTheme.canvas)
            .navigationTitle(dish == nil ? "Add Dish" : "Edit Dish")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onChange(of: pickerItems) { newItems in
                Task {
                    let newRefs = await PhotoPickerLoader.loadImageRefs(from: newItems)
                    await MainActor.run {
                        imageRefs.append(contentsOf: newRefs.prefix(remainingSlots))
                        pickerItems = []
                    }
                }
            }
        }
    }

    private func save() {
        guard isValid else {
            showValidation = true
            return
        }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let dish {
            let removed = dish.imageRefs.filter { !imageRefs.contains($0) }
            if !removed.isEmpty {
                ImageStore.shared.deleteImages(removed)
            }
            repository.updateDish(
                dish,
                name: name,
                rating: rating,
                notes: notes,
                tags: tags,
                dateEaten: dateEaten,
                imageRefs: imageRefs,
                restaurant: resolvedRestaurant
            )
        } else {
            _ = repository.addDish(
                name: name,
                rating: rating,
                notes: notes,
                tags: tags,
                dateEaten: dateEaten,
                imageRefs: imageRefs,
                restaurant: resolvedRestaurant
            )
        }

        dismiss()
    }
}

struct DishDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let dish: Dish

    @State private var showingGallery = false
    @State private var selectedImageIndex = 0
    @State private var showingEditor = false
    @State private var showDeleteConfirm = false

    private var repository: DishDiaryRepository {
        DishDiaryRepository(context: context)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !dish.imageRefs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(dish.imageRefs.enumerated()), id: \.offset) { index, ref in
                                Button {
                                    selectedImageIndex = index
                                    showingGallery = true
                                } label: {
                                    DiskImageView(
                                        ref: ref,
                                        targetSize: CGSize(width: 320, height: 240),
                                        contentMode: .fill,
                                        cornerRadius: 16
                                    )
                                    .frame(width: 200, height: 140)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(dish.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(BistroTheme.textPrimary)
                    if let restaurant = dish.restaurant {
                        Text(restaurant.name)
                            .font(.headline)
                            .foregroundColor(BistroTheme.secondary)
                        Text(restaurant.address)
                            .font(.subheadline)
                            .foregroundColor(BistroTheme.secondary)
                    }
                    StarRatingDisplay(rating: dish.rating, size: 18)
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Eaten: \(dish.dateEaten, formatter: DateFormatter.shortDate)")
                    Text("Created: \(dish.createdAt, formatter: DateFormatter.shortDate)")
                    Text("Updated: \(dish.updatedAt, formatter: DateFormatter.shortDate)")
                }
                .font(.caption)
                .foregroundColor(BistroTheme.secondary)
                .padding(.horizontal, 16)

                if !dish.tags.isEmpty {
                    Text(dish.tagDisplay)
                        .font(.caption)
                        .foregroundColor(BistroTheme.secondary)
                        .padding(.horizontal, 16)
                }

                if !dish.notes.isEmpty {
                    Text(dish.notes)
                        .font(.body)
                        .foregroundColor(BistroTheme.textPrimary)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .background(BistroTheme.canvas.ignoresSafeArea())
        .navigationTitle("Dish Detail")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditor = true
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            DishEditorView(dish: dish)
        }
        .fullScreenCover(isPresented: $showingGallery) {
            GalleryView(
                imageRefs: dish.imageRefs,
                startIndex: selectedImageIndex,
                isPresented: $showingGallery
            )
        }
        .alert("Delete dish?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                repository.deleteDish(dish)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the dish and its photos.")
        }
    }
}
