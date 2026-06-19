import SwiftUI

struct ChainLinkStreak: View {
    let streak: Int
    let weekActivity: [Bool]

    var body: some View {
        LuxGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    LuxSectionHeader(title: "Golden Chain", subtitle: "Consecutive elegant swings")
                    Spacer()
                    Text("\(streak)")
                        .luxCormorant(32)
                        .foregroundStyle(LuxPalette.secondary)
                }

                HStack(spacing: 6) {
                    ForEach(weekActivity.indices, id: \.self) { idx in
                        chainLink(active: weekActivity[idx])
                    }
                }
            }
        }
    }

    private func chainLink(active: Bool) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(active ? LuxPalette.goldShimmer : LinearGradient(colors: [LuxPalette.accent.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
            .frame(height: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(LuxPalette.secondary.opacity(active ? 0.8 : 0.2), lineWidth: 1)
            )
    }
}
