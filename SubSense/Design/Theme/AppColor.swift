import SwiftUI
import UIKit

extension Color {
    // MARK: - Brand
    static let brand      = Color(hex: "#6366F1")
    static let brandDeep  = Color(hex: "#4338CA")
    static let accent     = Color(hex: "#F59E0B")

    // MARK: - Semantic adaptive
    static let appBackground = Color(
        light: UIColor(hex: "#FAFAF9"),
        dark:  UIColor(hex: "#09090B")
    )
    static let appSurface = Color(
        light: UIColor(hex: "#FFFFFF"),
        dark:  UIColor(hex: "#18181B")
    )
    static let appSurfaceAlt = Color(
        light: UIColor(hex: "#F4F4F5"),
        dark:  UIColor(hex: "#27272A")
    )
    static let appBorder = Color(
        light: UIColor(red: 0, green: 0, blue: 0, alpha: 0.06),
        dark:  UIColor(red: 1, green: 1, blue: 1, alpha: 0.08)
    )
    static let appTextPrimary = Color(
        light: UIColor(hex: "#09090B"),
        dark:  UIColor(hex: "#FAFAFA")
    )
    static let appTextMuted = Color(
        light: UIColor(hex: "#71717A"),
        dark:  UIColor(hex: "#A1A1AA")
    )

    // MARK: - Semantic fixed
    static let appSuccess = Color(hex: "#10B981")
    static let appWarning = Color(hex: "#F59E0B")
    static let appDanger  = Color(hex: "#EF4444")
    static let appInfo    = Color(hex: "#3B82F6")

    // MARK: - Init from UIColor (adaptive)
    init(light: UIColor, dark: UIColor) {
        self.init(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    // MARK: - Init from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
