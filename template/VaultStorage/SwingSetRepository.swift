import Foundation
import SwiftData

@MainActor
final class SwingSetRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchAll() throws -> [SwingSet] {
        var descriptor = FetchDescriptor<SwingSet>(sortBy: [SortDescriptor(\.sortOrder)])
        return try context.fetch(descriptor)
    }

    func fetch(id: UUID) throws -> SwingSet? {
        try fetchAll().first { $0.id == id }
    }

    func insert(_ set: SwingSet) throws {
        context.insert(set)
        try context.save()
    }

    func update(_ set: SwingSet) throws {
        try context.save()
    }

    func delete(_ set: SwingSet) throws {
        context.delete(set)
        try context.save()
    }
}
