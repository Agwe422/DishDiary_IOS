import Kingfisher
import SwiftUI

struct ImageViewer: View {
    let imagePaths: [String]
    let startIndex: Int
    @Binding var isPresented: Bool

    @State private var currentIndex: Int

    init(imagePaths: [String], startIndex: Int, isPresented: Binding<Bool>) {
        self.imagePaths = imagePaths
        if imagePaths.isEmpty {
            self.startIndex = 0
        } else {
            self.startIndex = min(max(startIndex, 0), imagePaths.count - 1)
        }
        _isPresented = isPresented
        _currentIndex = State(initialValue: self.startIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if !imagePaths.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(imagePaths.enumerated()), id: \.offset) { index, path in
                        KFImage(URL(fileURLWithPath: path))
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
