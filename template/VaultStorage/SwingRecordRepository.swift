import Foundation
import SwiftData

@MainActor
final class SwingRecordRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchAll() throws -> [SwingRecord] {
        var descriptor = FetchDescriptor<SwingRecord>(sortBy: [SortDescriptor(\.swungAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func fetchToday() throws -> [SwingRecord] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        let all = try fetchAll()
        return all.filter { $0.swungAt >= start && $0.swungAt < end }
    }

    func insert(_ record: SwingRecord) throws {
        context.insert(record)
        try context.save()
    }

    func update(_ record: SwingRecord) throws {
        try context.save()
    }

    func delete(_ record: SwingRecord) throws {
        context.delete(record)
        try context.save()
    }
}
