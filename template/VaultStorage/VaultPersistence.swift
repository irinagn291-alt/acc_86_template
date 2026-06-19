import SwiftData

enum VaultPersistence {
    static let schema = Schema([SwingSet.self, ArcSegment.self, SwingRecord.self])

    static func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
