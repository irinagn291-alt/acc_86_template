import SwiftUI

struct PendulumHeroDecoration: View {
    let segmentCount: Int
    let reduceMotion: Bool

    @State private var angle: Double = -18

    private let arcSpan: Double = 150

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let pivotY: CGFloat = 20
            let radius = min(width * 0.4, 150)

            ZStack {
                ArcShape(spanDegrees: arcSpan)
                    .stroke(LuxPalette.secondary.opacity(0.4), lineWidth: 2.5)
                    .frame(width: radius * 2.1, height: radius * 1.0)
                    .position(x: width / 2, y: pivotY + radius * 0.5)

                ForEach(0..<max(segmentCount, 3), id: \.self) { idx in
                    let segAngle = PendulumEngine.arcAngle(for: idx, count: max(segmentCount, 3), span: arcSpan)
                    let rad = (segAngle - 90) * .pi / 180
                    Circle()
                        .fill(LuxPalette.secondary.opacity(0.45))
                        .frame(width: 8, height: 8)
                        .position(
                            x: width / 2 + CGFloat(cos(rad)) * radius * 0.88,
                            y: pivotY + radius * 0.5 + CGFloat(sin(rad)) * radius * 0.5
                        )
                }

                pendulum(width: width, radius: radius, pivotY: pivotY)
            }
        }
        .frame(height: 200)
        .onAppear { startGentleSway() }
    }

    private func pendulum(width: CGFloat, radius: CGFloat, pivotY: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(LuxPalette.goldShimmer)
                .frame(width: 2, height: radius)
                .offset(y: radius / 2)
            Circle()
                .fill(RadialGradient(colors: [LuxPalette.secondary, LuxPalette.primary], center: .topLeading, startRadius: 2, endRadius: 16))
                .frame(width: 24, height: 24)
                .overlay(Circle().stroke(LuxPalette.accent, lineWidth: 1))
                .offset(y: radius)
                .shadow(color: LuxPalette.primary.opacity(0.2), radius: 6, y: 3)
        }
        .rotationEffect(.degrees(angle), anchor: .top)
        .position(x: width / 2, y: pivotY)
    }

    private func startGentleSway() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
            angle = 18
        }
    }
}

private struct ArcShape: Shape {
    let spanDegrees: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2) / 2
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90 - spanDegrees / 2),
            endAngle: .degrees(-90 + spanDegrees / 2),
            clockwise: false
        )
        return path
    }
}
