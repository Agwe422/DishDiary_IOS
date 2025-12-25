import UIKit

struct ImageStore {
    private let maxDimension: CGFloat = 1280
    private let jpegQuality: CGFloat = 0.8

    private var imagesDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("Images", isDirectory: true)
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
                return url.path
            } catch {
                NSLog("Failed to save image: \(error.localizedDescription)")
                return nil
            }
        }
    }

    func deleteImages(at paths: [String]) {
        for path in paths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    NSLog("Failed to delete image at \(path): \(error.localizedDescription)")
                }
            }
        }
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
}
