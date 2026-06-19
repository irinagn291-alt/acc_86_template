import SwiftUI

struct LuxPrimaryButton: View {
    let title: String
    var icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
            }
            .foregroundStyle(LuxPalette.surface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(LuxPalette.heroGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .luxCardShadow()
        }
        .buttonStyle(.plain)
    }
}

struct LuxGlassCard<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LuxPalette.surface.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(LuxPalette.secondary.opacity(0.25), lineWidth: 1)
                    )
            )
            .luxCardShadow()
    }
}

struct LuxSectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).luxCormorant(22)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(LuxPalette.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LuxAccordionPack: View {
    let set: SwingSet
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSwing: () -> Void

    var body: some View {
        LuxGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Button(action: onToggle) {
                    HStack {
                        Image(systemName: set.category.icon)
                            .foregroundStyle(LuxPalette.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(set.name).luxCormorant(20)
                            Text(set.setDescription)
                                .font(.caption)
                                .foregroundStyle(LuxPalette.textMuted)
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(LuxPalette.secondary)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider().overlay(LuxPalette.accent)
                    ForEach(set.sortedSegments, id: \.id) { segment in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(LuxPalette.secondary.opacity(0.5))
                                .frame(width: 6, height: 6)
                            Text(segment.title)
                                .font(.subheadline)
                                .foregroundStyle(LuxPalette.text)
                        }
                    }
                    LuxPrimaryButton("Release Pendulum", icon: "arrow.triangle.2.circlepath") {
                        onSwing()
                    }
                }
            }
        }
    }
}
