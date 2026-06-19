import SwiftUI

struct SwingResultSheet: View {
    let setName: String
    let segment: ArcSegment
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(LuxPalette.secondary.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            Text("The pendulum has chosen")
                .font(.subheadline)
                .foregroundStyle(LuxPalette.textMuted)

            Text(segment.title)
                .luxCormorant(32)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            if !segment.details.isEmpty {
                Text(segment.details)
                    .font(.body)
                    .foregroundStyle(LuxPalette.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Text(setName)
                .font(.caption)
                .foregroundStyle(LuxPalette.secondary)

            LuxPrimaryButton("Embrace This Choice", icon: "checkmark") {
                onDismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .luxScreen()
    }
}
