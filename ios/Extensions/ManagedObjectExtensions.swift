import CoreData
import Foundation

extension Restaurant {
    var wrappedName: String { name ?? "" }
    var wrappedAddress: String { address ?? "" }
    var dishNoteArray: [DishNote] {
        let set = dishNotes as? Set<DishNote> ?? []
        return set.sorted { ($0.wrappedName.localizedCaseInsensitiveCompare($1.wrappedName) == .orderedAscending) }
    }
    var createdDate: Date { createdAt ?? Date.distantPast }
}

extension DishNote {
    var wrappedName: String { name ?? "" }
    var wrappedNote: String { note ?? "" }
    var imagePathList: [String] { (imagePaths as? [String]) ?? [] }
    var ratingValue: Double? { rating?.doubleValue }
    var createdDate: Date { createdAt ?? Date.distantPast }
    var updatedDate: Date { updatedAt ?? createdDate }
}
