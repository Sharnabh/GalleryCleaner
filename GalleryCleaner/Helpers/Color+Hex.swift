//
//  Color+Hex.swift
//  GalleryCleaner
//
//  Created by Sharnabh on 07/10/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Initializes a SwiftUI `Color` from a hexadecimal string.
    /// Supports 3, 4, 6, or 8 character hex strings (with or without a leading '#').
    ///
    /// Examples:
    /// - `Color(hex: "#FF5733")`
    /// - `Color(hex: "3498DB")`
    /// - `Color(hex: "#80FF5733")` (with alpha)
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }

    /// Initializes a SwiftUI `Color` using an RGB integer hex code.
    /// Example: `Color(hex: 0x1E293B, alpha: 1.0)`
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Converts the current `Color` to a hexadecimal string representation (#RRGGBB).
    func toHex() -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        return String(format: "#%06x", rgb)
        #else
        return nil
        #endif
    }
}

#if canImport(UIKit)
extension UIColor {
    /// Initializes a `UIColor` from a hexadecimal string.
    convenience init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}
#endif

// MARK: - App Theme Colors
extension Color {
    enum Theme {
        // Category Card Accent Colors
        static let screenshots     = Color(hex: "#4F46E5") // Indigo
        static let videos          = Color(hex: "#06B6D4") // Cyan
        static let duplicatePhotos = Color(hex: "#EF4444") // Coral Red
        static let similarPhotos   = Color(hex: "#F59E0B") // Amber
        static let duplicateVideos = Color(hex: "#EC4899") // Pink
        static let largeVideos     = Color(hex: "#8B5CF6") // Purple

        // Surface & Background Colors
        static let cardBackground  = Color(hex: "#1E293B") // Dark Slate
        static let appBackground   = Color(hex: "#0F172A") // Deep Midnight
        static let secondaryText   = Color(hex: "#94A3B8") // Slate Gray
        static let accentGreen     = Color(hex: "#10B981") // Emerald Green
    }
}
