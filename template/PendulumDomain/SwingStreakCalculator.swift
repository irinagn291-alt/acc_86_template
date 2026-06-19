import Foundation

enum SwingStreakCalculator {
    static func currentStreak(from records: [SwingRecord]) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var day = calendar.startOfDay(for: .now)
        let daysWithSwing = Set(records.map { calendar.startOfDay(for: $0.swungAt) })
        while daysWithSwing.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    static func weekActivity(from records: [SwingRecord]) -> [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        let swungDays = Set(records.map { calendar.startOfDay(for: $0.swungAt) })
        return days.reversed().map { swungDays.contains($0) }
    }
}
