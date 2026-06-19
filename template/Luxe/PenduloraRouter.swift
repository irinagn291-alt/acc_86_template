import SwiftUI

struct PenduloraRouter: View {
    @EnvironmentObject private var services: PenduloraServices

    var body: some View {
        if services.preferences.hasCompletedOnboarding {
            DualTabShell()
        } else {
            LuxOnboardingView()
        }
    }
}
