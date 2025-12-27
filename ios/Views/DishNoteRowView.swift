import Kingfisher
import SwiftUI

struct DishNoteRowView: View {
    let note: DishNote
    var onImageTap: (Int) -> Void
    var onShowMore: () -> Void

    private var images: [String] { note.imagePathList }

    private var isLongNote: Bool {
        note.wrappedNote.count > 160
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.wrappedName)
                    .font(.headline)
                Spacer()
                if let rating = note.ratingValue {
                    Text(String(format: "%.1f", rating))
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            Text(note.wrappedNote)
                .lineLimit(5)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if isLongNote {
                Button(action: onShowMore) {
                    Text("Show more")
                        .font(.footnote)
                }
                .buttonStyle(.borderless)
            }

            HStack(spacing: 12) {
                Label(note.createdDate, formatter: DateFormatter.shortDate) {
                    Text("Created")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Label(note.updatedDate, formatter: DateFormatter.shortDate) {
                    Text("Updated")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            if !images.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(images.prefix(3).enumerated()), id: \.offset) { index, path in
                        Button(action: { onImageTap(index) }) {
                            ZStack {
                                KFImage(URL(fileURLWithPath: path))
                                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                                    .cacheOriginalImage(false)
                                    .fade(duration: 0.15)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)

                                if index == 2 && images.count > 3 {
                                    Color.black.opacity(0.45)
                                        .cornerRadius(8)
                                    Text("+\(images.count - 3) more")
                                        .foregroundColor(.white)
                                        .font(.footnote.weight(.semibold))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
    }
}
