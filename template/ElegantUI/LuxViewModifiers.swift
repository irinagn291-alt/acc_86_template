import SwiftUI

struct LuxScreenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    LuxPalette.background.ignoresSafeArea()
                    RadialGradient(
                        colors: [LuxPalette.accent.opacity(0.22), .clear],
                        center: .top,
                        startRadius: 20,
                        endRadius: 480
                    )
                    .ignoresSafeArea()
                }
            )
            .foregroundStyle(LuxPalette.text)
    }
}

struct LuxCormorantTitle: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .semibold, design: .serif))
            .foregroundStyle(LuxPalette.text)
    }
}

extension View {
    func luxScreen() -> some View { modifier(LuxScreenModifier()) }

    func luxCormorant(_ size: CGFloat = 28) -> some View {
        modifier(LuxCormorantTitle(size: size))
    }

    func luxCardShadow() -> some View {
        shadow(color: LuxPalette.cardShadow, radius: 12, x: 0, y: 6)
    }
}
