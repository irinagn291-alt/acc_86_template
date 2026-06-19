import SwiftUI

struct LuxSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: PenduloraServices

    var body: some View {
        NavigationStack {
            Form {
                Section("Experience") {
                    Toggle("Sound", isOn: prefBinding(\.soundEnabled))
                    Toggle("Haptics", isOn: prefBinding(\.hapticsEnabled))
                    Toggle("Reduce Motion", isOn: prefBinding(\.reduceAnimations))
                    Toggle("Allow Re-swing", isOn: prefBinding(\.allowReswing))
                }
                Section("About") {
                    HStack {
                        Text("App")
                        Spacer()
                        Text(AppConstants.appName).foregroundStyle(LuxPalette.textMuted)
                    }
                    NavigationLink { PortalContactView() } label: { Text("Contact Us") }
                    NavigationLink { PortalPrivacyView() } label: { Text("Privacy Policy") }
                }
                Section {
                    Button("Reset Onboarding") {
                        services.preferences.hasCompletedOnboarding = false
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func prefBinding(_ keyPath: ReferenceWritableKeyPath<LuxPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { services.preferences[keyPath: keyPath] },
            set: { services.preferences[keyPath: keyPath] = $0 }
        )
    }
}

struct LuxContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "envelope.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(LuxPalette.primary)
                Button("Open in Safari") {
                    if let url = URL(string: AppConstants.contactURL) { openURL(url) }
                }
                .buttonStyle(.borderedProminent)
                .tint(LuxPalette.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(LuxPalette.background.ignoresSafeArea())
            .navigationTitle("Contact Us")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
