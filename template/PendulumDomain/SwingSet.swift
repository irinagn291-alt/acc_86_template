import Foundation
import SwiftData

@Model
final class SwingSet {
    var id: UUID
    var name: String
    var setDescription: String
    var categoryRaw: String
    var isBuiltIn: Bool
    var createdAt: Date
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \ArcSegment.swingSet)
    var segments: [ArcSegment]

    var category: SwingCategory {
        get { SwingCategory(rawValue: categoryRaw) ?? .ritual }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        setDescription: String = "",
        category: SwingCategory,
        isBuiltIn: Bool = false,
        createdAt: Date = .now,
        sortOrder: Int = 0,
        segments: [ArcSegment] = []
    ) {
        self.id = id
        self.name = name
        self.setDescription = setDescription
        self.categoryRaw = category.rawValue
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.segments = segments
    }

    var sortedSegments: [ArcSegment] {
        segments.sorted { $0.sortOrder < $1.sortOrder }
    }
}
