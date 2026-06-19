import SwiftUI

struct PendulumSwingView: View {
    let segments: [ArcSegment]
    let reduceMotion: Bool
    var onComplete: (ArcSegment) -> Void

    @State private var angle: Double = 0
    @State private var isSwinging = false
    @State private var highlightIndex: Int?
    @State private var landedSegment: ArcSegment?

    private let arcSpan: Double = 150

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let pivotY: CGFloat = 24
            let radius = min(width * 0.42, 160)

            ZStack(alignment: .top) {
                arcPath(width: width, radius: radius, pivotY: pivotY)
                ZStack {
                    pendulumRod(radius: radius, pivotY: pivotY)
                    bob(radius: radius, pivotY: pivotY)
                }
                .position(x: width / 2, y: pivotY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: 220)
        .onAppear { if !isSwinging { startSwing() } }
    }

    private func arcPath(width: CGFloat, radius: CGFloat, pivotY: CGFloat) -> some View {
        let count = max(segments.count, 1)
        return ZStack {
            ArcShape(spanDegrees: arcSpan)
                .stroke(LuxPalette.secondary.opacity(0.35), lineWidth: 3)
                .frame(width: radius * 2.1, height: radius * 1.05)
                .position(x: width / 2, y: pivotY + radius * 0.55)

            ForEach(segments.indices, id: \.self) { idx in
                let segAngle = PendulumEngine.arcAngle(for: idx, count: count, span: arcSpan)
                let isLit = highlightIndex == idx || landedSegment?.id == segments[idx].id
                segmentLabel(
                    segments[idx],
                    angle: segAngle,
                    radius: radius,
                    width: width,
                    pivotY: pivotY,
                    highlighted: isLit
                )
            }
        }
    }

    private func segmentLabel(
        _ segment: ArcSegment,
        angle: Double,
        radius: CGFloat,
        width: CGFloat,
        pivotY: CGFloat,
        highlighted: Bool
    ) -> some View {
        let rad = (angle - 90) * .pi / 180
        let cx = width / 2 + CGFloat(cos(rad)) * radius * 0.92
        let cy = pivotY + radius * 0.55 + CGFloat(sin(rad)) * radius * 0.55
        return Text(segment.title)
            .font(.system(size: highlighted ? 13 : 11, weight: highlighted ? .semibold : .regular, design: .serif))
            .foregroundStyle(highlighted ? LuxPalette.primary : LuxPalette.textMuted)
            .lineLimit(1)
            .frame(maxWidth: 72)
            .position(x: cx, y: cy)
    }

    private func pendulumRod(radius: CGFloat, pivotY: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [LuxPalette.secondary, LuxPalette.secondary.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 2.5, height: radius)
            .offset(y: radius / 2)
            .rotationEffect(.degrees(angle), anchor: .top)
    }

    private func bob(radius: CGFloat, pivotY: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [LuxPalette.secondary, LuxPalette.primary],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: 18
                )
            )
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(LuxPalette.accent, lineWidth: 1.5))
            .offset(y: radius)
            .rotationEffect(.degrees(angle), anchor: .top)
            .shadow(color: LuxPalette.primary.opacity(0.25), radius: 8, y: 4)
    }

    private func startSwing() {
        guard !segments.isEmpty, !isSwinging else { return }
        isSwinging = true
        let targetIdx = PendulumEngine.landingIndex(segmentCount: segments.count)
        let targetAngle = PendulumEngine.arcAngle(for: targetIdx, count: segments.count, span: arcSpan)
        let frames = PendulumEngine.swingKeyframes(targetAngle: targetAngle, reduceMotion: reduceMotion)

        if reduceMotion {
            angle = targetAngle
            highlightIndex = targetIdx
            finishSwing(segment: segments[targetIdx])
            return
        }

        var delay: Double = 0
        let stepDuration = AppConstants.swingAnimationDuration / Double(max(frames.count, 1))
        for (i, frame) in frames.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: stepDuration)) {
                    angle = frame
                }
                if i == frames.count - 1 {
                    highlightIndex = targetIdx
                    LuxHaptics.shared.impact(.heavy)
                    finishSwing(segment: segments[targetIdx])
                }
            }
            delay += stepDuration
        }
    }

    private func finishSwing(segment: ArcSegment) {
        landedSegment = segment
        isSwinging = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onComplete(segment)
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
