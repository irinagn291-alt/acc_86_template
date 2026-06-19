import SwiftUI

enum LuxTab: Int, CaseIterable, Identifiable {
    case today, library

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .library: "Library"
        }
    }

    var icon: String {
        switch self {
        case .today: "clock.badge.checkmark"
        case .library: "books.vertical.fill"
        }
    }
}

struct DualTabShell: View {
    @State private var tab: LuxTab = .today
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { showSettings = true } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(LuxPalette.primary)
                }
                .padding(.trailing, 18)
                .padding(.top, 8)
            }

            Group {
                switch tab {
                case .today: ArcDashboard()
                case .library: SwingLibraryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            luxTabBar
        }
        .luxScreen()
        .sheet(isPresented: $showSettings) {
            LuxSettingsView()
        }
    }

    private var luxTabBar: some View {
        HStack(spacing: 0) {
            ForEach(LuxTab.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { tab = item }
                    LuxHaptics.shared.selection()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: tab == item ? .semibold : .regular))
                        Text(item.title)
                            .font(.system(size: 13, weight: .medium, design: .serif))
                    }
                    .foregroundStyle(tab == item ? LuxPalette.primary : LuxPalette.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        tab == item
                            ? LuxPalette.accent.opacity(0.35)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            LuxPalette.surface.opacity(0.95),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(LuxPalette.secondary.opacity(0.2), lineWidth: 1)
        )
        .luxCardShadow()
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}
