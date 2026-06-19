import Foundation
import SwiftData
import Combine

@MainActor
final class LuxPreferences: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: AppConstants.hasCompletedOnboardingKey) }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: AppConstants.soundEnabledKey) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: AppConstants.hapticsEnabledKey) }
    }
    @Published var reduceAnimations: Bool {
        didSet { UserDefaults.standard.set(reduceAnimations, forKey: AppConstants.reduceAnimationsKey) }
    }
    @Published var allowReswing: Bool {
        didSet { UserDefaults.standard.set(allowReswing, forKey: AppConstants.allowReswingKey) }
    }
    @Published var defaultDailySetId: UUID? {
        didSet { UserDefaults.standard.set(defaultDailySetId?.uuidString, forKey: AppConstants.defaultDailySetIdKey) }
    }

    init() {
        let d = UserDefaults.standard
        hasCompletedOnboarding = d.bool(forKey: AppConstants.hasCompletedOnboardingKey)
        soundEnabled = d.object(forKey: AppConstants.soundEnabledKey) as? Bool ?? true
        hapticsEnabled = d.object(forKey: AppConstants.hapticsEnabledKey) as? Bool ?? true
        reduceAnimations = d.bool(forKey: AppConstants.reduceAnimationsKey)
        allowReswing = d.object(forKey: AppConstants.allowReswingKey) as? Bool ?? true
        if let raw = d.string(forKey: AppConstants.defaultDailySetIdKey) {
            defaultDailySetId = UUID(uuidString: raw)
        } else {
            defaultDailySetId = nil
        }
    }
}
