import SwiftUI
import UIKit

struct GalleryView: View {
    let imageRefs: [String]
    let startIndex: Int
    @Binding var isPresented: Bool

    @State private var currentIndex: Int

    init(imageRefs: [String], startIndex: Int, isPresented: Binding<Bool>) {
        self.imageRefs = imageRefs
        if imageRefs.isEmpty {
            self.startIndex = 0
        } else {
            self.startIndex = min(max(startIndex, 0), imageRefs.count - 1)
        }
        _isPresented = isPresented
        _currentIndex = State(initialValue: self.startIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if !imageRefs.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(imageRefs.enumerated()), id: \.offset) { index, ref in
                        ZoomableImageView(ref: ref)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }

            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

struct ZoomableImageView: View {
    let ref: String
    @State private var image: UIImage?

    var body: some View {
        ZoomableScrollView(image: image)
            .task {
                image = await ImageStore.shared.loadImage(ref: ref, targetSize: nil)
            }
    }
}

struct ZoomableScrollView: UIViewRepresentable {
    let image: UIImage?

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = context.coordinator
        scrollView.backgroundColor = .black

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        context.coordinator.imageView = imageView
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }
    }
}
