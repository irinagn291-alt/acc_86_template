import Foundation

enum SwingCategory: String, Codable, CaseIterable, Identifiable {
    case evening = "Evening"
    case wellness = "Wellness"
    case dining = "Dining"
    case leisure = "Leisure"
    case focus = "Focus"
    case ritual = "Ritual"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .evening: "moon.stars.fill"
        case .wellness: "leaf.fill"
        case .dining: "fork.knife"
        case .leisure: "theatermasks.fill"
        case .focus: "scope"
        case .ritual: "sparkles"
        }
    }
}
