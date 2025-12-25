import Kingfisher
import SwiftUI

struct DishNoteFormView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let restaurant: Restaurant
    let dishNote: DishNote?

    @State private var name: String
    @State private var ratingText: String
    @State private var noteText: String
    @State private var existingImagePaths: [String]
    @State private var newImages: [UIImage] = []
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var ratingError: String?
    @State private var showValidation = false

    private var initialPaths: [String]

    private var repository: DishDiaryRepository {
        DishDiaryRepository(context: context)
    }

    private var remainingImageSlots: Int {
        max(0, 5 - existingImagePaths.count - newImages.count)
    }

    private var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && ratingError == nil
    }

    init(restaurant: Restaurant, dishNote: DishNote?) {
        self.restaurant = restaurant
        self.dishNote = dishNote
        let initialName = dishNote?.wrappedName ?? ""
        let initialNote = dishNote?.wrappedNote ?? ""
        let initialRating = dishNote?.ratingValue
        let paths = dishNote?.imagePathList ?? []

        _name = State(initialValue: initialName)
        _noteText = State(initialValue: initialNote)
        _ratingText = State(initialValue: initialRating != nil ? String(format: "%.1f", initialRating ?? 0) : "")
        _existingImagePaths = State(initialValue: paths)
        initialPaths = paths
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dish")) {
                    TextField("Name", text: $name)
                        .onChange(of: name) { _ in showValidation = true }
                    TextField("Rating (1.0 - 10.0)", text: $ratingText)
                        .keyboardType(.decimalPad)
                        .onChange(of: ratingText, perform: validateRating)
                    if let ratingError {
                        Text(ratingError)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    if showValidation && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Name is required")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 120)
                }

                Section(header: HStack {
                    Text("Photos")
                    Spacer()
                    Text("\(existingImagePaths.count + newImages.count)/5")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(existingImagePaths.enumerated()), id: \.offset) { index, path in
                                imageThumbnail(forPath: path) {
                                    existingImagePaths.remove(at: index)
                                }
                            }
                            ForEach(Array(newImages.enumerated()), id: \.offset) { index, image in
                                imageThumbnail(forImage: image) {
                                    newImages.remove(at: index)
                                }
                            }
                            if remainingImageSlots > 0 {
                                Menu {
                                    Button {
                                        showPhotoPicker = true
                                    } label: {
                                        Label("Photo Library", systemImage: "photo.on.rectangle")
                                    }
                                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        Button {
                                            showCamera = true
                                        } label: {
                                            Label("Camera", systemImage: "camera")
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.largeTitle)
                                        Text("Add")
                                            .font(.footnote)
                                    }
                                    .frame(width: 96, height: 96)
                                    .foregroundColor(.accentColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                            .foregroundColor(.accentColor)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(dishNote == nil ? "Add Dish Note" : "Edit Dish Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
                if dishNote != nil {
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            if let dishNote {
                                repository.deleteDishNote(dishNote)
                            }
                            dismiss()
                        } label: {
                            Label("Delete Note", systemImage: "trash")
                        }
                    }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(selectionLimit: remainingImageSlots) { images in
                    let toAdd = images.prefix(remainingImageSlots)
                    newImages.append(contentsOf: toAdd)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    if let image, remainingImageSlots > 0 {
                        newImages.append(image)
                    }
                }
            }
        }
    }

    private func imageThumbnail(forPath path: String, removeAction: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            KFImage(URL(fileURLWithPath: path))
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                .cacheOriginalImage(false)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipped()
                .cornerRadius(12)

            Button(action: removeAction) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 6, y: -6)
        }
    }

    private func imageThumbnail(forImage image: UIImage, removeAction: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipped()
                .cornerRadius(12)

            Button(action: removeAction) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 6, y: -6)
        }
    }

    private func validateRating(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            ratingError = nil
            return
        }
        if let value = Double(trimmed), value >= 1.0, value <= 10.0 {
            ratingError = nil
        } else {
            ratingError = "Rating must be between 1.0 and 10.0"
        }
    }

    private func save() {
        showValidation = true
        guard isValid else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = noteText
        let ratingValue = Double(ratingText.trimmingCharacters(in: .whitespacesAndNewlines))

        let store = ImageStore()
        let newPaths = store.saveImages(newImages)

        let removedPaths = initialPaths.filter { !existingImagePaths.contains($0) }
        store.deleteImages(at: removedPaths)

        let allPaths = existingImagePaths + newPaths

        if let dishNote {
            repository.updateDishNote(dishNote, name: trimmedName, rating: ratingValue, note: trimmedNote, imagePaths: allPaths)
        } else {
            repository.addDishNote(to: restaurant, name: trimmedName, rating: ratingValue, note: trimmedNote, imagePaths: allPaths)
        }

        dismiss()
    }
}
