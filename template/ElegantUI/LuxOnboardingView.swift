import SwiftUI

struct LuxOnboardingView: View {
    @EnvironmentObject private var services: PenduloraServices
    @State private var page = 0

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("clock.badge.checkmark", "Welcome to Pendulora",
         "An elegant instrument for life's finer decisions."),
        ("arrow.triangle.2.circlepath", "Swing the golden pendulum",
         "Watch it arc across curated sectors until fate selects your path."),
        ("link", "Build your golden chain",
         "Each daily swing forges links in a streak of refined consistency."),
        ("books.vertical.fill", "Curate your library",
         "Browse swing packs, craft custom arcs, and revisit past choices.")
    ]

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Skip") { finish() }
                    .foregroundStyle(LuxPalette.textMuted)
            }
            .padding(.horizontal, 20)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { idx in
                    onboardingPage(pages[idx]).tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            LuxPrimaryButton(page == pages.count - 1 ? "Enter Pendulora" : "Continue", icon: "arrow.right") {
                if page == pages.count - 1 { finish() }
                else { withAnimation { page += 1 } }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .luxScreen()
    }

    private func onboardingPage(_ item: (icon: String, title: String, subtitle: String)) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LuxPalette.heroGradient)
                    .frame(width: 170, height: 170)
                    .luxCardShadow()
                Image(systemName: item.icon)
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(LuxPalette.surface)
            }
            VStack(spacing: 12) {
                Text(item.title).luxCormorant(28).multilineTextAlignment(.center)
                Text(item.subtitle)
                    .font(.body)
                    .foregroundStyle(LuxPalette.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            Spacer()
        }
    }

    private func finish() {
        Task { @MainActor in
            services.preferences.hasCompletedOnboarding = true
        }
    }
}
