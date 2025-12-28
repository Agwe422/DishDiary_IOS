import Foundation

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

import SwiftUI
import UIKit

enum BistroTheme {
    static let canvas = Color.dynamic(light: "#F2F2F7", dark: "#1C1C1E")
    static let surface = Color.dynamic(light: "#FFFFFF", dark: "#2C2C2E")
    static let primary = Color.dynamic(light: "#D95D39", dark: "#E3856B")
    static let secondary = Color.dynamic(light: "#8D6E63", dark: "#A47764")
    static let rating = Color.dynamic(light: "#FAAF00", dark: "#FFD700")
    static let good = Color.dynamic(light: "#4F7E17", dark: "#8BAE66")
    static let bad = Color.dynamic(light: "#B00020", dark: "#CF6679")
    static let textPrimary = Color.dynamic(light: "#1C1C1E", dark: "#E5E5E7")

    static let cornerRadius: CGFloat = 16
    static let borderWidth: CGFloat = 1.5

    static func applyNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(BistroTheme.canvas)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(BistroTheme.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(BistroTheme.textPrimary)]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

extension Color {
    static func dynamic(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hexString.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }

        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: 1.0
        )
    }
}
