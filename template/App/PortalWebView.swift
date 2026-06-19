import SwiftUI
@preconcurrency import Alamofire

struct PortalWebView: View {
    let url: String
    let title: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            WebContentView(url: url)
        }
        .preferredColorScheme(.dark)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PortalContactView: View {
    var body: some View {
        PortalWebView(url: PortalConfig.contactURL, title: "Contact Us")
    }
}

struct PortalPrivacyView: View {
    var body: some View {
        PortalWebView(url: PortalConfig.privacyURL, title: "Privacy Policy")
    }
}
