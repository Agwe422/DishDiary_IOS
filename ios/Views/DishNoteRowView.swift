import SwiftUI
import UIKit

struct DishCardView: View {
    let dish: Dish

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            DiskImageView(
                ref: dish.imageRefs.first,
                targetSize: CGSize(width: 320, height: 320),
                contentMode: .fill,
                cornerRadius: BistroTheme.cornerRadius,
                placeholder: AnyView(
                    ZStack {
                        BistroTheme.surface
                        Image(systemName: "fork.knife")
                            .font(.system(size: 32))
                            .foregroundColor(BistroTheme.secondary.opacity(0.6))
                    }
                )
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(dish.name)
                    .font(.headline.weight(.bold))
                    .foregroundColor(BistroTheme.textPrimary)
                    .lineLimit(1)
                if let restaurant = dish.restaurant?.name {
                    Text(restaurant)
                        .font(.subheadline)
                        .foregroundColor(BistroTheme.textPrimary.opacity(0.8))
                        .lineLimit(1)
                }
                StarRatingDisplay(rating: dish.rating, size: 14)
            }
            .padding(12)
            .background(
                LinearGradient(
                    colors: [BistroTheme.surface.opacity(0.95), BistroTheme.surface.opacity(0.7)],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(RoundedRectangle(cornerRadius: BistroTheme.cornerRadius, style: .continuous))
            )
            .padding(10)
        }
        .aspectRatio(1, contentMode: .fit)
        .background(BistroTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: BistroTheme.cornerRadius, style: .continuous)
                .stroke(BistroTheme.secondary.opacity(0.5), lineWidth: BistroTheme.borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: BistroTheme.cornerRadius, style: .continuous))
    }
}

struct StarRatingDisplay: View {
    let rating: Double
    var size: CGFloat = 16

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .font(.system(size: size))
                    .foregroundColor(BistroTheme.rating)
            }
        }
        .accessibilityLabel("Rating \(rating, specifier: "%.1f") out of 5")
    }

    private func symbol(for index: Int) -> String {
        let threshold = Double(index)
        if rating >= threshold {
            return "star.fill"
        }
        if rating >= threshold - 0.5 {
            return "star.leadinghalf.filled"
        }
        return "star"
    }
}

struct StarRatingControl: View {
    @Binding var rating: Double
    var maxRating: Int = 5
    var size: CGFloat = 28

    @State private var lastStep: Double = -1
    private let feedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 8) {
                ForEach(1...maxRating, id: \.self) { index in
                    Image(systemName: symbol(for: index))
                        .font(.system(size: size))
                        .foregroundColor(BistroTheme.rating)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newRating = ratingFrom(locationX: value.location.x, width: proxy.size.width)
                        if newRating != rating {
                            rating = newRating
                            triggerHapticIfNeeded(newRating)
                        }
                    }
            )
        }
        .frame(height: size + 6)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(rating, specifier: "%.1f") out of 5")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                setRating(rating + 0.5)
            case .decrement:
                setRating(rating - 0.5)
            @unknown default:
                break
            }
        }
    }

    private func symbol(for index: Int) -> String {
        let threshold = Double(index)
        if rating >= threshold {
            return "star.fill"
        }
        if rating >= threshold - 0.5 {
            return "star.leadinghalf.filled"
        }
        return "star"
    }

    private func ratingFrom(locationX: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return rating }
        let percent = max(0, min(1, locationX / width))
        let raw = percent * Double(maxRating)
        return Dish.clampRating(raw)
    }

    private func setRating(_ value: Double) {
        let newRating = Dish.clampRating(value)
        rating = newRating
        triggerHapticIfNeeded(newRating)
    }

    private func triggerHapticIfNeeded(_ newRating: Double) {
        let step = (newRating * 2).rounded() / 2
        if step != lastStep {
            feedback.impactOccurred()
            lastStep = step
        }
    }
}
