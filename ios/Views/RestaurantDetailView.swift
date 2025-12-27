import Kingfisher
import SwiftUI
import CoreData

struct RestaurantDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var restaurant: Restaurant

    @FetchRequest private var dishNotes: FetchedResults<DishNote>

    @State private var searchText = ""
    @State private var sortOption: SortOption = .nameAsc
    @State private var showingAddNote = false
    @State private var showingRestaurantForm = false
    @State private var noteSelection: NSManagedObjectID?
    @State private var noteToDelete: DishNote?
    @State private var showDeleteRestaurantConfirm = false
    @State private var selectedImages: [String] = []
    @State private var selectedImageIndex = 0
    @State private var showImageViewer = false

    private var repository: DishDiaryRepository {
        DishDiaryRepository(context: context)
    }

    private enum SortOption: String, CaseIterable {
        case nameAsc = "Name A–Z"
        case nameDesc = "Name Z–A"
        case recent = "Newest"
        case oldest = "Oldest"
        case ratingHigh = "Rating High–Low"
        case ratingLow = "Rating Low–High"
    }

    private var filteredNotes: [DishNote] {
        dishNotes
            .filter { note in
                guard !searchText.isEmpty else { return true }
                let query = searchText.lowercased()
                return note.wrappedName.lowercased().contains(query) || note.wrappedNote.lowercased().contains(query)
            }
            .sorted { lhs, rhs in
                switch sortOption {
                case .nameAsc:
                    return lhs.wrappedName.localizedCaseInsensitiveCompare(rhs.wrappedName) == .orderedAscending
                case .nameDesc:
                    return lhs.wrappedName.localizedCaseInsensitiveCompare(rhs.wrappedName) == .orderedDescending
                case .recent:
                    return lhs.createdDate > rhs.createdDate
                case .oldest:
                    return lhs.createdDate < rhs.createdDate
                case .ratingHigh:
                    let leftRating = lhs.ratingValue ?? -Double.greatestFiniteMagnitude
                    let rightRating = rhs.ratingValue ?? -Double.greatestFiniteMagnitude
                    if leftRating == rightRating {
                        return lhs.createdDate > rhs.createdDate
                    }
                    return leftRating > rightRating
                case .ratingLow:
                    let leftRating = lhs.ratingValue ?? Double.greatestFiniteMagnitude
                    let rightRating = rhs.ratingValue ?? Double.greatestFiniteMagnitude
                    if leftRating == rightRating {
                        return lhs.createdDate > rhs.createdDate
                    }
                    return leftRating < rightRating
                }
            }
    }

    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        _dishNotes = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \DishNote.name, ascending: true)],
            predicate: NSPredicate(format: "restaurant == %@", restaurant),
            animation: .default
        )
    }

    var body: some View {
        List {
            if !restaurant.wrappedAddress.isEmpty {
                Section("Address") {
                    Text(restaurant.wrappedAddress)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                ForEach(filteredNotes, id: \.objectID) { note in
                    DishNoteRowView(
                        note: note,
                        onImageTap: { index in
                            selectedImages = note.imagePathList
                            selectedImageIndex = index
                            showImageViewer = true
                        },
                        onShowMore: {
                            noteSelection = note.objectID
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        noteSelection = note.objectID
                    }
                    .background(
                        NavigationLink(
                            destination: DishNoteFormView(restaurant: restaurant, dishNote: note),
                            tag: note.objectID,
                            selection: $noteSelection
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    )
                        .swipeActions {
                            Button(role: .destructive) {
                                noteToDelete = note
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            } header: {
                HStack {
                    Text("Dish Notes")
                    Spacer()
                    Menu {
                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(restaurant.wrappedName)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingAddNote = true }) {
                    Label("Add Dish Note", systemImage: "plus")
                }
                Menu {
                    Button("Edit Restaurant") {
                        showingRestaurantForm = true
                    }
                    Button(role: .destructive) {
                        showDeleteRestaurantConfirm = true
                    } label: {
                        Label("Delete Restaurant", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search dishes")
        .sheet(isPresented: $showingAddNote) {
            DishNoteFormView(restaurant: restaurant, dishNote: nil)
        }
        .sheet(isPresented: $showingRestaurantForm) {
            RestaurantFormView(restaurant: restaurant) { name, address in
                repository.updateRestaurant(restaurant, name: name, address: address.isEmpty ? nil : address)
            }
        }
        .alert("Delete restaurant?", isPresented: $showDeleteRestaurantConfirm) {
            Button("Delete", role: .destructive) {
                repository.deleteRestaurant(restaurant)
                dismiss()
            }
            Button("Cancel", role: .cancel, action: {})
        } message: {
            Text("This will remove the restaurant and all of its dish notes.")
        }
        .alert("Delete this note?", isPresented: Binding(get: { noteToDelete != nil }, set: { value in
            if !value { noteToDelete = nil }
        })) {
            Button("Delete", role: .destructive) {
                if let note = noteToDelete {
                    repository.deleteDishNote(note)
                }
                noteToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                noteToDelete = nil
            }
        } message: {
            Text("Images will be removed from storage too.")
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            ImageViewer(
                imagePaths: selectedImages,
                startIndex: selectedImageIndex,
                isPresented: $showImageViewer
            )
        }
    }
}
