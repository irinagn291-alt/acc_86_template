import Foundation
import SwiftData

enum BuiltInSwingSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let key = AppConstants.hasSeededBuiltInSetsKey
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let packs: [(String, String, SwingCategory, [String])] = [
            ("Evening Elegance", "Refined choices for twilight hours", .evening, [
                "Sip a vintage tea blend",
                "Read poetry by candlelight",
                "Take a slow evening stroll",
                "Journal three graceful moments",
                "Listen to a classical nocturne"
            ]),
            ("Wellness Arc", "Gentle rituals for body and mind", .wellness, [
                "Five minutes of mindful breathing",
                "Stretch with soft ambient music",
                "Hydrate with infused water",
                "Practice gratitude silently",
                "Rest eyes from screens"
            ]),
            ("Dining Decree", "Curated culinary decisions", .dining, [
                "Prepare a simple artisan plate",
                "Try a new herb in tonight's dish",
                "Dine without digital distraction",
                "Share a meal with someone dear",
                "Savor dessert unhurriedly"
            ]),
            ("Leisure Swing", "Sophisticated pastimes", .leisure, [
                "Visit a gallery or museum",
                "Watch a classic film",
                "Sketch or write freely",
                "Explore a new neighborhood",
                "Attend a live performance"
            ]),
            ("Focus Pendulum", "Decisive productivity prompts", .focus, [
                "Tackle your most important task",
                "Clear your workspace mindfully",
                "Review weekly priorities",
                "Complete one lingering errand",
                "Plan tomorrow with intention"
            ]),
            ("Ritual Chamber", "Ceremonial daily practices", .ritual, [
                "Light a candle and set intention",
                "Arrange flowers on your desk",
                "Speak affirmations aloud",
                "Organize one cherished space",
                "Write a letter of appreciation"
            ])
        ]

        for (index, pack) in packs.enumerated() {
            let set = SwingSet(
                name: pack.0,
                setDescription: pack.1,
                category: pack.2,
                isBuiltIn: true,
                sortOrder: index
            )
            set.segments = pack.3.enumerated().map { offset, title in
                ArcSegment(title: title, details: "An elegant choice awaits.", sortOrder: offset)
            }
            context.insert(set)
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: key)
    }
}
