import PhotosUI
import SwiftUI

enum PhotoPickerLoader {
    static func loadImageRefs(from items: [PhotosPickerItem]) async -> [String] {
        await ImageStore.shared.savePickerItems(items)
    }
}
