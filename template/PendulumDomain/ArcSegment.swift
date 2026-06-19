import Foundation
import SwiftData

@Model
final class ArcSegment {
    var id: UUID
    var title: String
    var details: String
    var sortOrder: Int
    var swingSet: SwingSet?

    init(id: UUID = UUID(), title: String, details: String = "", sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.details = details
        self.sortOrder = sortOrder
    }
}
