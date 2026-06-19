import SwiftUI

enum LuxPalette {
    static let primary = Color(hex: 0x722F37)
    static let secondary = Color(hex: 0xC9A961)
    static let accent = Color(hex: 0xE8D5B7)
    static let background = Color(hex: 0xFAF7F2)
    static let surface = Color(hex: 0xFFFFFF)
    static let text = Color(hex: 0x2C1810)
    static let textMuted = Color(hex: 0x2C1810).opacity(0.58)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.92), secondary.opacity(0.75), accent.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var goldShimmer: LinearGradient {
        LinearGradient(
            colors: [secondary.opacity(0.3), secondary, secondary.opacity(0.4)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var cardShadow: Color { primary.opacity(0.08) }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
