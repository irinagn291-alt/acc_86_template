import SwiftUI

struct SwingArenaView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: PenduloraServices
    let swingSet: SwingSet
    let onLand: (ArcSegment) -> Void

    @State private var swingKey = UUID()

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(LuxPalette.textMuted)
                }
                Spacer()
                Text(swingSet.name).luxCormorant(24)
                Spacer()
                Color.clear.frame(width: 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Text(swingSet.setDescription)
                .font(.subheadline)
                .foregroundStyle(LuxPalette.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            PendulumSwingView(
                segments: swingSet.sortedSegments,
                reduceMotion: services.preferences.reduceAnimations
            ) { segment in
                onLand(segment)
                dismiss()
            }
            .id(swingKey)
            .padding(.horizontal, 12)

            LuxPrimaryButton("Swing Again", icon: "arrow.clockwise") {
                swingKey = UUID()
                LuxHaptics.shared.impact()
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .luxScreen()
    }
}
