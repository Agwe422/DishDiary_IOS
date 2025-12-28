import PhotosUI
import SwiftUI
import UIKit

final class ImageStore {
    static let shared = ImageStore()

    private let maxDimension: CGFloat = 1600
    private let jpegQuality: CGFloat = 0.82
    private let cache = NSCache<NSString, UIImage>()

    private var imagesDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("Images", isDirectory: true)
    }

    func url(for ref: String) -> URL {
        imagesDirectory.appendingPathComponent(ref)
    }

    func saveImages(_ images: [UIImage]) -> [String] {
        guard !images.isEmpty else { return [] }
        ensureDirectory()

        return images.compactMap { image in
            let resized = downscale(image: image)
            guard let data = resized.jpegData(compressionQuality: jpegQuality) else { return nil }
            let filename = UUID().uuidString + ".jpg"
            let url = imagesDirectory.appendingPathComponent(filename)

            do {
                try data.write(to: url, options: .atomic)
                return filename
            } catch {
                NSLog("Failed to save image: \(error.localizedDescription)")
                return nil
            }
        }
    }

    func savePickerItems(_ items: [PhotosPickerItem]) async -> [String] {
        guard !items.isEmpty else { return [] }
        var saved: [String] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                saved.append(contentsOf: saveImages([image]))
            }
        }
        return saved
    }

    func deleteImages(_ refs: [String]) {
        for ref in refs {
            let url = imagesDirectory.appendingPathComponent(ref)
            cache.removeObject(forKey: ref as NSString)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    NSLog("Failed to delete image at \(url.path): \(error.localizedDescription)")
                }
            }
        }
    }

    func loadImage(ref: String, targetSize: CGSize? = nil) async -> UIImage? {
        if let cached = cache.object(forKey: cacheKey(ref: ref, targetSize: targetSize)) {
            return cached
        }

        let url = imagesDirectory.appendingPathComponent(ref)
        guard let image = downsampleImage(at: url, targetSize: targetSize) else { return nil }
        cache.setObject(image, forKey: cacheKey(ref: ref, targetSize: targetSize))
        return image
    }

    private func ensureDirectory() {
        let directory = imagesDirectory
        if !FileManager.default.fileExists(atPath: directory.path) {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                NSLog("Failed to create images directory: \(error.localizedDescription)")
            }
        }
    }

    private func downscale(image: UIImage) -> UIImage {
        let maxSide = max(image.size.width, image.size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func downsampleImage(at url: URL, targetSize: CGSize?) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else { return nil }

        let maxPixel: CGFloat
        if let targetSize {
            maxPixel = max(targetSize.width, targetSize.height) * UIScreen.main.scale
        } else {
            maxPixel = maxDimension
        }

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func cacheKey(ref: String, targetSize: CGSize?) -> NSString {
        if let targetSize {
            return "\(ref)-\(Int(targetSize.width))x\(Int(targetSize.height))" as NSString
        }
        return ref as NSString
    }
}

struct DiskImageView: View {
    let ref: String?
    var targetSize: CGSize?
    var contentMode: ContentMode = .fill
    var cornerRadius: CGFloat = 16
    var placeholder: AnyView = AnyView(Color.gray.opacity(0.2))

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: ref) {
            guard let ref else { return }
            image = await ImageStore.shared.loadImage(ref: ref, targetSize: targetSize)
        }
    }
}
