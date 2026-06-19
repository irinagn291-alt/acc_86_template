import Foundation

enum AppConstants {
    static let appName = "Pendulora"
    static let contactURL = PortalConfig.contactURL
    static let privacyURL = PortalConfig.privacyURL
    static let maxSetNameLength = 60
    static let maxSegmentTitleLength = 100
    static let maxSegmentDetailsLength = 240
    static let minSegments = 3
    static let maxSegments = 10
    static let swingAnimationDuration: TimeInterval = 2.4
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let hasSeededBuiltInSetsKey = "hasSeededBuiltInSets"
    static let defaultDailySetIdKey = "defaultDailySetId"
    static let soundEnabledKey = "soundEnabled"
    static let hapticsEnabledKey = "hapticsEnabled"
    static let reduceAnimationsKey = "reduceAnimations"
    static let allowReswingKey = "allowReswing"
}
