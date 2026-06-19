import Foundation
import SwiftData

enum SwingStatus: String, Codable {
    case pending, completed, skipped
}

@Model
final class SwingRecord {
    var id: UUID
    var swingSetId: UUID
    var swingSetName: String
    var landedTitle: String
    var landedDetails: String
    var statusRaw: String
    var swungAt: Date

    var status: SwingStatus {
        get { SwingStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        swingSetId: UUID,
        swingSetName: String,
        landedTitle: String,
        landedDetails: String = "",
        status: SwingStatus = .pending,
        swungAt: Date = .now
    ) {
        self.id = id
        self.swingSetId = swingSetId
        self.swingSetName = swingSetName
        self.landedTitle = landedTitle
        self.landedDetails = landedDetails
        self.statusRaw = status.rawValue
        self.swungAt = swungAt
    }
}
